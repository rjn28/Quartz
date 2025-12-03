#!/bin/bash

# --- CONFIGURATION ---
APP_NAME="Whiteboard"
# D'après ta capture d'écran, l'exécutable généré par Swift s'appelle "Whiteboard"
EXECUTABLE_NAME="WhiteboardApp"
DMG_NAME="Whiteboard_Installer.dmg"

# --- 1. NETTOYAGE & COMPILATION (MODE RELEASE) ---
echo "🧹 Nettoyage et compilation en mode RELEASE..."
rm -rf .build
rm -rf "$APP_NAME.app"
rm -f "$DMG_NAME"

# On compile en mode optimisé (Release)
swift build -c release -Xswiftc -O

# On définit le chemin vers le binaire compilé
BUILD_PATH=".build/release/$EXECUTABLE_NAME"

# Vérification que la compilation a réussi
if [ ! -f "$BUILD_PATH" ]; then
    echo "❌ Erreur : L'exécutable n'a pas été trouvé à $BUILD_PATH"
    exit 1
fi

# --- 2. CRÉATION DU PAQUET .APP ---
echo "📦 Création de $APP_NAME.app..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copie de l'exécutable
cp "$BUILD_PATH" "$APP_NAME.app/Contents/MacOS/$APP_NAME"

# Création du Info.plist (Indispensable pour macOS)
cat > "$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.rjn28.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
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

# --- 3. CRÉATION DU DMG (IMAGE DISQUE) ---
echo "💿 Création du fichier $DMG_NAME..."

# Création d'un dossier temporaire pour le DMG
mkdir -p dist
cp -r "$APP_NAME.app" dist/

# Création du lien symbolique vers le dossier Applications (pour le drag & drop)
ln -s /Applications dist/Applications

# Utilisation de l'outil natif d'Apple pour créer le DMG
hdiutil create -volname "$APP_NAME" -srcfolder dist -ov -format UDZO "$DMG_NAME"

# Nettoyage final
rm -rf dist
rm -rf "$APP_NAME.app"

echo "✅ SUCCÈS ! Le fichier $DMG_NAME est prêt à être uploadé sur GitHub."
ls -lh "$DMG_NAME"