#!/bin/bash
set -e

APP_NAME="ScreenshotForChat"
VERSION="1.0.0"

echo "🔧 Building ${APP_NAME} with Swift Package Manager..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build/release
rm -rf dist/

# Resolve dependencies and build with SPM
echo "📦 Resolving dependencies..."
swift package resolve

echo "🔨 Building release binary..."
swift build -c release

# Verify binary exists
BINARY_PATH=".build/release/${APP_NAME}"
if [ ! -f "${BINARY_PATH}" ]; then
    echo "❌ Build failed - binary not found at ${BINARY_PATH}"
    exit 1
fi

# Create .app bundle structure
echo "📱 Creating .app bundle..."
APP_BUNDLE="dist/${APP_NAME}.app"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BINARY_PATH}" "${APP_BUNDLE}/Contents/MacOS/"

# Copy Info.plist
if [ -f "Resources/Info.plist" ]; then
    cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/"
else
    echo "❌ Info.plist not found in Resources/"
    exit 1
fi

# Make binary executable
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "✅ Build complete!"
echo "📱 App bundle: $(pwd)/${APP_BUNDLE}"
echo "📋 Binary size: $(du -h "${BINARY_PATH}" | cut -f1)"
echo ""
echo "🚀 To run: open ${APP_BUNDLE}"
echo "📋 To install: cp -r ${APP_BUNDLE} /Applications/"