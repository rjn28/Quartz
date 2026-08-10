// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Quartz",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "QuartzApp",
            targets: ["Quartz"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Quartz",
            path: "Sources/Quartz",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "QuartzTests",
            dependencies: ["Quartz"],
            path: "Tests/QuartzTests"
        )
    ]
)
