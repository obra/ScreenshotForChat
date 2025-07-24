# Update

(Cunningham's Law)[https://meta.wikimedia.org/wiki/Cunningham%27s_Law] successfully applied! It turns out that on MacOS, Claude Code has a magic key binding on *`Control-V`* that raids the system copy-paste buffer and does the right thing. You probably don't need this tool, but it was a fun afternoon getting it together.

# Screenshot for Chat

A quick macOS screenshot tool designed for copying and pasting images into most apps and the path on disk to a temp file containing the image to tools like Claude Code.

Capture windows, full screen, or custom regions with global keyboard shortcuts. The smart clipboard automatically provides both image data and file paths, making it perfect for both visual sharing and AI assistant interactions.

Screenshot files are written into an ephemeral temporary directory. They won't be cluttering up your homedir next year. But you also shouldn't depend on them still existing in an hour unless you've pasted them somewhere.

## Features

- **Window Capture**: Click to select any window for precise screenshots
- **Full Screen Capture**: Capture entire screen or all displays
- **Region Capture**: Drag to select any area of the screen
- **Global Keyboard Shortcuts**: Work from any application (fully customizable)
- **Smart Clipboard**: Both image data and file path copied simultaneously

## Requirements

- macOS 14.0 or later
- Apple Silicon Mac (ARM64)
- Screen Recording permission (granted automatically on first use)

## Installation

1. Download the latest release
3. Launch and grant Screen Recording permission when prompted
4. Configure keyboard shortcuts in Settings if you want. 

## Usage

### Keyboard Shortcuts (Default)

- **Window Capture**: `Cmd+Shift+0` - Select and capture a specific window
- **Full Screen Capture**: `Cmd+Shift+9` - Capture the entire screen
- **Region Capture**: `Cmd+Shift+8` - Drag to select any area of the screen

All shortcuts are fully customizable in Settings.

### Settings

- Configure global keyboard shortcuts
- Toggle launch at login
- Adjust HiDPI scaling behavior

## Smart Clipboard Integration

Screenshots are automatically saved to your temporary directory with intelligent clipboard handling:

### Dual Clipboard Content
- **Image Data**: Direct image for apps like Photoshop, Slack, Discord, Messages
- **File Path**: Text path perfect for sharing with your AI coding buddy that expected you to drag and drop a screenshot into your terminal

### How It Works
When you paste after taking a screenshot:
- **Image-capable apps** automatically receive the screenshot image
- **Text-based apps** automatically receive the file path string
- No manual copy paste needed - apps choose the format they prefer

Perfect for both visual sharing and AI assistant interactions!

## Building from Source

```bash
git clone https://github.com/obra/screenshotForChat.git
cd screenshotForChat
swift build
```

### Creating App Bundle

```bash
swift build --configuration release --arch arm64
mkdir -p ScreenshotForChat.app/Contents/MacOS
cp .build/arm64-apple-macosx/release/ScreenshotForChat ScreenshotForChat.app/Contents/MacOS/
cp -r .build/arm64-apple-macosx/release/KeyboardShortcuts_KeyboardShortcuts.bundle ScreenshotForChat.app/Contents/
# Add Info.plist to Contents/
```

## Privacy

This app requires Screen Recording permission to capture screenshots. No data is transmitted or stored remotely - all screenshots remain local to your machine.

## License

MIT License - see LICENSE file for details

## Copyright

Copyright 2025 Jesse Vincent <jesse@fsck.com>

Made with love and robots in Berkeley, California
