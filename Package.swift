// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeCodeUsage",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClaudeCodeUsage", targets: ["ClaudeCodeUsage"])
    ],
    targets: [
        .executableTarget(
            name: "ClaudeCodeUsage",
            path: "ClaudeCodeUsage/Sources",
            exclude: ["App/Info.plist"]
        ),
        .testTarget(
            name: "ClaudeCodeUsageTests",
            dependencies: ["ClaudeCodeUsage"],
            path: "Tests"
        )
    ]
)
