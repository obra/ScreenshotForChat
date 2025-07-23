#!/bin/bash
# ABOUTME: Build script for screenshotForChat menubar app
# ABOUTME: Compiles Swift source and creates executable

set -e

echo "Building screenshotForChat..."
swiftc -o screenshotForChat screenshotForChat.swift \
    -framework AppKit \
    -framework ScreenCaptureKit \
    -framework Carbon

echo "Build complete! Run with: ./screenshotForChat"
echo "Use Cmd+Shift+0 to trigger screenshot anywhere"