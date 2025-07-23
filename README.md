# Screenshot for Chat

A modern macOS screenshot tool designed for AI chat interactions. Capture windows or full screen with global keyboard shortcuts and get file paths automatically copied to your clipboard for easy sharing with AI assistants.

## Features

- **Window Capture**: Click to select any window for precise screenshots
- **Full Screen Capture**: Capture entire screen or all displays
- **Global Keyboard Shortcuts**: Work from any application
- **Visual Feedback**: Flash effects confirm successful captures
- **AI-Optimized**: File paths copied to clipboard for easy AI chat sharing
- **Modern macOS Integration**: Built with ScreenCaptureKit for hardware acceleration
- **Launch at Login**: Optional automatic startup
- **HiDPI Support**: Configurable retina display handling

## Requirements

- macOS 14.0 or later
- Screen Recording permission (granted automatically on first use)

## Installation

1. Download the latest release
2. Move to `/Applications/` folder
3. Launch and grant Screen Recording permission when prompted
4. Configure keyboard shortcuts in Settings

## Usage

### Keyboard Shortcuts

- **Window Capture**: Select and capture a specific window (customizable)
- **Full Screen Capture**: Capture the entire screen (customizable)

### Menu Bar

Click the camera icon in the menu bar to access:
- Capture Window
- Capture Full Screen  
- Settings
- Quit

### Settings

- Configure global keyboard shortcuts
- Toggle launch at login
- Adjust HiDPI scaling behavior

## Screenshots

Screenshots are automatically saved to your temporary directory and the file path is copied to your clipboard. Perfect for sharing with AI assistants by simply pasting the path.

## Building from Source

```bash
git clone https://github.com/obra/screenshotForChat.git
cd screenshotForChat
swift build
```

### Creating App Bundle

```bash
swift build
mkdir -p ScreenshotForChat.app/Contents/MacOS
cp .build/debug/ScreenshotForChat ScreenshotForChat.app/Contents/MacOS/
cp -r .build/debug/KeyboardShortcuts_KeyboardShortcuts.bundle ScreenshotForChat.app/Contents/
# Add Info.plist to Contents/
```

## Privacy

This app requires Screen Recording permission to capture screenshots. No data is transmitted or stored remotely - all screenshots remain local to your machine.

## License

MIT License - see LICENSE file for details

## Copyright

Copyright 2025 Jesse Vincent <jesse@fsck.com>