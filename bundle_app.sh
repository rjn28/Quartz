#!/bin/bash

# --- CONFIGURATION ---
APP_NAME="Quartz"
EXECUTABLE_NAME="QuartzApp"
DMG_NAME="Quartz_Installer.dmg"

# --- 1. NETTOYAGE ---
echo "🧹 Nettoyage..."
rm -rf .build
rm -rf "$APP_NAME.app"
rm -rf "TempIcon.iconset"
rm -f "AppIcon.icns"
rm -f "$DMG_NAME"

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

# B. FABRICATION MANUELLE DE L'ICÔNE (Sans Xcode)
echo "🎨 Création de l'icône via iconutil..."

# 1. On crée un dossier temporaire au format que macOS aime
mkdir -p "TempIcon.iconset"

# 2. On copie ta grande image 1024.png et on la renomme comme macOS le veut
# (On utilise l'image HD pour l'affichage Retina)
SOURCE_ICON="Resources/Assets.xcassets/AppIcon.appiconset/1024.png"

if [ -f "$SOURCE_ICON" ]; then
    cp "$SOURCE_ICON" "TempIcon.iconset/icon_512x512@2x.png"
    
    # 3. On utilise l'outil natif 'iconutil' pour créer le fichier .icns
    iconutil -c icns "TempIcon.iconset" -o "AppIcon.icns"
    
    # 4. On déplace le fichier final dans l'application
    mv "AppIcon.icns" "$APP_NAME.app/Contents/Resources/"
    echo "   ✅ Icône .icns générée et injectée !"
else
    echo "❌ ERREUR : L'image 1024.png est introuvable à $SOURCE_ICON"
fi

# Nettoyage du dossier temporaire
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

# --- 4. PACKAGING ---
echo "💿 Création du DMG..."
mkdir -p dist
cp -r "$APP_NAME.app" dist/
ln -s /Applications dist/Applications
hdiutil create -volname "$APP_NAME" -srcfolder dist -ov -format UDZO "$DMG_NAME" > /dev/null
rm -rf dist
rm -rf "$APP_NAME.app"

echo "✅ TERMINÉ ! Lance $DMG_NAME."