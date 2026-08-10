#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly APP_NAME="Quartz"
readonly EXECUTABLE_NAME="QuartzApp"
readonly DEFAULT_OUTPUT_DIR="$PROJECT_ROOT/BuildArtifacts"
readonly DEFAULT_ARCHITECTURES="arm64 x86_64"

version="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"
build_number=""
identity="${CODE_SIGN_IDENTITY:--}"
output_dir="${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"
architectures="${ARCHITECTURES:-$DEFAULT_ARCHITECTURES}"

usage() {
    echo "Usage: $0 [--version X.Y.Z] [--build-number N] [--identity NAME] [--output-dir PATH]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            version="${2:?Missing value for --version}"
            shift 2
            ;;
        --build-number)
            build_number="${2:?Missing value for --build-number}"
            shift 2
            ;;
        --identity)
            identity="${2:?Missing value for --identity}"
            shift 2
            ;;
        --output-dir)
            output_dir="${2:?Missing value for --output-dir}"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "$build_number" ]]; then
    if command -v git >/dev/null 2>&1 && git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        build_number="$(git -C "$PROJECT_ROOT" rev-list --count HEAD)"
    else
        build_number="1"
    fi
fi

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version must use X.Y.Z format: $version" >&2
    exit 2
fi

if [[ ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
    echo "Build number must be a positive integer: $build_number" >&2
    exit 2
fi

read -r -a architecture_list <<< "$architectures"
if [[ ${#architecture_list[@]} -eq 0 ]]; then
    echo "At least one architecture is required" >&2
    exit 2
fi

swift_architecture_args=()
for architecture in "${architecture_list[@]}"; do
    case "$architecture" in
        arm64|x86_64)
            swift_architecture_args+=(--arch "$architecture")
            ;;
        *)
            echo "Unsupported architecture: $architecture" >&2
            exit 2
            ;;
    esac
done

mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

readonly temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/quartz-package.XXXXXX")"
trap 'rm -rf "$temporary_root"' EXIT

readonly app_bundle="$temporary_root/$APP_NAME.app"
readonly app_contents="$app_bundle/Contents"
readonly app_binary="$app_contents/MacOS/$APP_NAME"
readonly staging_directory="$temporary_root/dmg"
readonly output_dmg="$output_dir/$APP_NAME-$version.dmg"

echo "Building $APP_NAME $version ($build_number) for ${architecture_list[*]}..."
swift build \
    --package-path "$PROJECT_ROOT" \
    --configuration release \
    "${swift_architecture_args[@]}"

binary_directory="$(
    swift build \
        --package-path "$PROJECT_ROOT" \
        --configuration release \
        "${swift_architecture_args[@]}" \
        --show-bin-path
)"
readonly binary_directory
readonly source_binary="$binary_directory/$EXECUTABLE_NAME"

if [[ ! -x "$source_binary" ]]; then
    echo "Built executable not found: $source_binary" >&2
    exit 1
fi

mkdir -p "$app_contents/MacOS" "$app_contents/Resources"
install -m 755 "$source_binary" "$app_binary"

while IFS= read -r -d '' resource_bundle; do
    cp -R "$resource_bundle" "$app_contents/Resources/"
done < <(find "$binary_directory" -maxdepth 1 -type d -name '*.bundle' -print0)

cp "$PROJECT_ROOT/Packaging/Info.plist" "$app_contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$app_contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$app_contents/Info.plist"
plutil -lint "$app_contents/Info.plist"

iconset="$temporary_root/AppIcon.iconset"
mkdir -p "$iconset"
readonly icon_source="$PROJECT_ROOT/Sources/Quartz/Resources/Assets.xcassets/AppIcon.appiconset"
cp "$icon_source/16.png" "$iconset/icon_16x16.png"
cp "$icon_source/32.png" "$iconset/icon_16x16@2x.png"
cp "$icon_source/32.png" "$iconset/icon_32x32.png"
cp "$icon_source/64.png" "$iconset/icon_32x32@2x.png"
cp "$icon_source/128.png" "$iconset/icon_128x128.png"
cp "$icon_source/256.png" "$iconset/icon_128x128@2x.png"
cp "$icon_source/256.png" "$iconset/icon_256x256.png"
cp "$icon_source/512.png" "$iconset/icon_256x256@2x.png"
cp "$icon_source/512.png" "$iconset/icon_512x512.png"
cp "$icon_source/1024.png" "$iconset/icon_512x512@2x.png"
iconutil --convert icns "$iconset" --output "$app_contents/Resources/AppIcon.icns"

if [[ "$identity" == "-" ]]; then
    echo "Applying an ad hoc signature for local testing..."
    codesign --force --sign - "$app_bundle"
else
    echo "Signing with Developer ID identity: $identity"
    codesign --force --options runtime --timestamp --sign "$identity" "$app_bundle"
fi

codesign --verify --deep --strict --verbose=2 "$app_bundle"

built_architectures="$(lipo -archs "$app_binary")"
for architecture in "${architecture_list[@]}"; do
    if [[ " $built_architectures " != *" $architecture "* ]]; then
        echo "Missing architecture $architecture in $app_binary" >&2
        exit 1
    fi
done

mkdir -p "$staging_directory"
cp -R "$app_bundle" "$staging_directory/"
ln -s /Applications "$staging_directory/Applications"
rm -f "$output_dmg"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$staging_directory" \
    -format UDZO \
    -ov \
    "$output_dmg" \
    >/dev/null

if [[ "$identity" != "-" ]]; then
    codesign --force --timestamp --sign "$identity" "$output_dmg"
    codesign --verify --verbose=2 "$output_dmg"
fi

hdiutil verify "$output_dmg" >/dev/null
shasum -a 256 "$output_dmg"
echo "Created $output_dmg"
