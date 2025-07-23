#!/bin/bash
set -e

APP_NAME="ScreenshotForChat"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"

echo "📀 Creating DMG for ${APP_NAME}..."

# Check if app exists
if [ ! -d "dist/${APP_NAME}.app" ]; then
    echo "❌ App bundle not found. Run ./Scripts/build.sh first"
    exit 1
fi

# Create temporary DMG directory
TEMP_DMG_DIR="temp_dmg"
rm -rf "${TEMP_DMG_DIR}"
mkdir -p "${TEMP_DMG_DIR}"

# Copy app to temp directory
cp -r "dist/${APP_NAME}.app" "${TEMP_DMG_DIR}/"

# Create Applications shortcut
ln -s "/Applications" "${TEMP_DMG_DIR}/Applications"

# Create DMG
echo "🔧 Creating DMG file..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${TEMP_DMG_DIR}" \
    -ov -format UDZO \
    "dist/${DMG_NAME}.dmg"

# Clean up
rm -rf "${TEMP_DMG_DIR}"

echo "✅ DMG created: $(pwd)/dist/${DMG_NAME}.dmg"
echo "📋 Size: $(du -h "dist/${DMG_NAME}.dmg" | cut -f1)"