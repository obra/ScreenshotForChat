// swift-tools-version: 5.11
import PackageDescription

let package = Package(
    name: "ScreenshotForChat",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "2.3.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", exact: "1.1.0")
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotForChat",
            dependencies: [
                "KeyboardShortcuts",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern")
            ],
            path: "Sources/ScreenshotForChat"
        )
    ]
)