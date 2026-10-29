// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuiteAll",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "QuiteAll",
            targets: ["QuiteAll"]
        )
    ],
    targets: [
        .executableTarget(
            name: "QuiteAll",
            path: "Sources/QuiteAll"
        ),
        .testTarget(
            name: "QuiteAllTests",
            dependencies: ["QuiteAll"],
            path: "Tests/QuiteAllTests"
        )
    ]
)
