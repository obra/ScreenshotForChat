# Screenshot for Chat

A modern macOS screenshot tool with intelligent clipboard integration. Capture windows, full screen, or custom regions with global keyboard shortcuts. The smart clipboard automatically provides both image data and file paths, making it perfect for both visual sharing and AI assistant interactions.

## Features

- **Window Capture**: Click to select any window for precise screenshots
- **Full Screen Capture**: Capture entire screen or all displays
- **Region Capture**: Drag to select any area of the screen
- **Global Keyboard Shortcuts**: Work from any application (fully customizable)
- **Visual Feedback**: Flash effects confirm successful captures
- **Smart Clipboard**: Both image data and file path copied simultaneously
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

### Keyboard Shortcuts (Default)

- **Window Capture**: `Cmd+Shift+0` - Select and capture a specific window
- **Full Screen Capture**: `Cmd+Shift+9` - Capture the entire screen
- **Region Capture**: `Cmd+Shift+8` - Drag to select any area of the screen

All shortcuts are fully customizable in Settings.

### Menu Bar

Click the camera icon in the menu bar to access:
- Capture Window
- Capture Full Screen
- Capture Region
- Settings
- Quit

### Settings

- Configure global keyboard shortcuts
- Toggle launch at login
- Adjust HiDPI scaling behavior

## Smart Clipboard Integration

Screenshots are automatically saved to your temporary directory with intelligent clipboard handling:

### Dual Clipboard Content
- **Image Data**: Direct image for apps like Photoshop, Slack, Discord, Messages
- **File Path**: Text path for terminals, code editors, AI chats, file managers

### How It Works
When you paste after taking a screenshot:
- **Image-capable apps** automatically receive the screenshot image
- **Text-based apps** automatically receive the file path string
- No manual switching needed - apps choose the format they prefer

Perfect for both visual sharing and AI assistant interactions!

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