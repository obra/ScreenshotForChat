#!/bin/bash
set -e

APP_NAME="ScreenshotForChat"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🎨 Setting up icons for $APP_NAME..."

# Check if source images exist in Resources (canonical location)
APP_ICON_SOURCE="$PROJECT_DIR/Resources/app-icon-source.png"
MENUBAR_ICON_SOURCE="$PROJECT_DIR/Resources/menubar-source.png"

if [ ! -f "$APP_ICON_SOURCE" ]; then
    echo "❌ App icon not found at $APP_ICON_SOURCE"
    exit 1
fi

if [ ! -f "$MENUBAR_ICON_SOURCE" ]; then
    echo "❌ Menu bar icon not found at $MENUBAR_ICON_SOURCE"
    exit 1
fi

# Create Resources directory if it doesn't exist
mkdir -p "$PROJECT_DIR/Resources"

# Clean up any existing icon files
rm -rf "$PROJECT_DIR/Resources/$APP_NAME.iconset"
rm -rf "$PROJECT_DIR/Resources/MenuBar.iconset"
rm -f "$PROJECT_DIR/Resources/$APP_NAME.icns"

echo "📱 Generating app icon sizes..."

# Prepare .iconset folder for app icon
mkdir "$PROJECT_DIR/Resources/$APP_NAME.iconset"

# Generate all required app icon sizes with transparency preserved
sips -z 16 16 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_16x16.png"
sips -z 32 32 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_16x16@2x.png"
sips -z 32 32 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_32x32.png"
sips -z 64 64 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_32x32@2x.png"
sips -z 128 128 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_128x128.png"
sips -z 256 256 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_128x128@2x.png"
sips -z 256 256 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_256x256.png"
sips -z 512 512 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_256x256@2x.png"
sips -z 512 512 -s format png -s formatOptions 100 "$APP_ICON_SOURCE" --out "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_512x512.png"
cp "$APP_ICON_SOURCE" "$PROJECT_DIR/Resources/$APP_NAME.iconset/icon_512x512@2x.png"

# Generate the .icns file
echo "🔨 Creating .icns file..."
iconutil -c icns "$PROJECT_DIR/Resources/$APP_NAME.iconset"

echo "🔍 Generating menu bar icon sizes..."

# Prepare folder for menu bar icons
mkdir "$PROJECT_DIR/Resources/MenuBar.iconset"

# Generate menu bar icon sizes (template glyphs)
for size in 16 32 44; do
  sips -z $size $size "$MENUBAR_ICON_SOURCE" \
    --out "$PROJECT_DIR/Resources/MenuBar.iconset/menubar_${size}x${size}.png"
done

# Generate @2x variants for menu bar
for size in 16 32; do
  sips -z $((size*2)) $((size*2)) "$MENUBAR_ICON_SOURCE" \
    --out "$PROJECT_DIR/Resources/MenuBar.iconset/menubar_${size}x${size}@2x.png"
done

# Copy the menu bar icons to main Resources folder
cp "$PROJECT_DIR/Resources/MenuBar.iconset/menubar_16x16.png" "$PROJECT_DIR/Resources/"
cp "$PROJECT_DIR/Resources/MenuBar.iconset/menubar_16x16@2x.png" "$PROJECT_DIR/Resources/"
cp "$PROJECT_DIR/Resources/MenuBar.iconset/menubar_32x32.png" "$PROJECT_DIR/Resources/"
cp "$PROJECT_DIR/Resources/MenuBar.iconset/menubar_32x32@2x.png" "$PROJECT_DIR/Resources/"

echo "📋 Using source images from Resources..."
echo "   App icon: $APP_ICON_SOURCE"
echo "   Menubar icon: $MENUBAR_ICON_SOURCE"

echo "✅ Icon setup complete!"
echo "📱 App icon: $PROJECT_DIR/Resources/$APP_NAME.icns"
echo "🔍 Menu bar icons: $PROJECT_DIR/Resources/menubar_*.png"
echo ""
echo "📋 Generated files:"
ls -la "$PROJECT_DIR/Resources/"*.png "$PROJECT_DIR/Resources/"*.icns 2>/dev/null || true