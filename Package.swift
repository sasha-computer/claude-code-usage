// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CCUsage",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CCUsage", targets: ["CCUsage"])
    ],
    targets: [
        .executableTarget(
            name: "CCUsage",
            path: "CCUsage/Sources",
            exclude: ["App/Info.plist"]
        )
    ]
)
