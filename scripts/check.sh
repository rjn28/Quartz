#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

bash -n scripts/build_and_run.sh scripts/package_app.sh scripts/check.sh
swift package describe >/dev/null
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
swift test
swift build --configuration release
git diff --check
git diff --cached --check
