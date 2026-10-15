// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "AwesomeWindows",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AwesomeWindows",
            dependencies: ["Yams"],
            path: "Sources",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "AwesomeWindowsTests",
            dependencies: ["AwesomeWindows", "Yams"],
            path: "Tests"
        )
    ]
)
