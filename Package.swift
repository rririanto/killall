// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KillAll",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "KillAll",
            targets: ["KillAll"]
        )
    ],
    targets: [
        .executableTarget(
            name: "KillAll",
            path: "Sources/KillAll"
        ),
        .testTarget(
            name: "KillAllTests",
            dependencies: ["KillAll"],
            path: "Tests/KillAllTests"
        )
    ]
)
