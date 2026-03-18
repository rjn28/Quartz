#!/bin/bash

# --- CONFIGURATION ---
APP_NAME="Quartz"
EXECUTABLE_NAME="QuartzApp"
OUTPUT_DIR="BuildArtifacts"
DMG_NAME="$OUTPUT_DIR/Quartz_Installer.dmg"

# --- 1. NETTOYAGE ---
echo "🧹 Nettoyage..."
rm -rf .build
rm -rf "$APP_NAME.app"
rm -rf "TempIcon.iconset"
rm -f "AppIcon.icns"
rm -f "$DMG_NAME"
rm -f "Quartz_Installer.dmg"
mkdir -p "$OUTPUT_DIR"

# --- 2. COMPILATION DU CODE ---
echo "🔨 Compilation du code..."
swift build -c release -Xswiftc -O

BUILD_PATH=".build/release/$EXECUTABLE_NAME"

if [ ! -f "$BUILD_PATH" ]; then
    echo "❌ Erreur : L'exécutable n'a pas été trouvé."
    exit 1
fi

# --- 3. ASSEMBLAGE ---
echo "📦 Assemblage de $APP_NAME.app..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# A. Copie du moteur
cp "$BUILD_PATH" "$APP_NAME.app/Contents/MacOS/$APP_NAME"

# B. FABRICATION MANUELLE DE L'ICÔNE (Le retour !)
echo "🎨 Création de l'icône via iconutil..."

# On crée le dossier temporaire
mkdir -p "TempIcon.iconset"

# IMPORTANT : On cherche ton image 1024.png. 
# Comme on a déplacé le dossier dans Sources, le chemin est maintenant ici :
SOURCE_ICON="Sources/QuartzTarget/Assets.xcassets/AppIcon.appiconset/1024.png"

# Si jamais tu as remis le dossier à la racine (Resources), on vérifie aussi là-bas :
if [ ! -f "$SOURCE_ICON" ]; then
    SOURCE_ICON="Resources/Assets.xcassets/AppIcon.appiconset/1024.png"
fi

if [ -f "$SOURCE_ICON" ]; then
    # On prépare l'image pour l'outil
    cp "$SOURCE_ICON" "TempIcon.iconset/icon_512x512@2x.png"
    
    # On convertit en .icns (Format Mac)
    iconutil -c icns "TempIcon.iconset" -o "AppIcon.icns"
    
    # On injecte dans l'app
    mv "AppIcon.icns" "$APP_NAME.app/Contents/Resources/"
    echo "   ✅ Icône .icns générée et injectée !"
else
    echo "❌ ERREUR : Impossible de trouver 1024.png (ni dans Sources ni dans Resources)"
fi

# Nettoyage
rm -rf "TempIcon.iconset"

# C. Création du Info.plist
cat > "$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.rjn28.Quartz</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# --- 4. SIGNATURE (Pour éviter "Endommagé") ---
echo "🔏 Signature Ad-Hoc..."
codesign --force --deep --sign - "$APP_NAME.app"

# --- 5. PACKAGING ---
echo "💿 Création du DMG..."
mkdir -p dist
cp -r "$APP_NAME.app" dist/
ln -s /Applications dist/Applications
hdiutil create -volname "$APP_NAME" -srcfolder dist -ov -format UDZO "$DMG_NAME" > /dev/null
rm -rf dist
rm -rf "$APP_NAME.app"

echo "✅ TERMINÉ ! Lance $DMG_NAME."
