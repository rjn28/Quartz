// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Quartz",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "QuartzApp",
            targets: ["QuartzTarget"]),
    ],
    targets: [
        .executableTarget(
            name: "QuartzTarget",
            dependencies: [],
            path: ".",
            exclude: [
                "bundle_app.sh",
                "BuildArtifacts",
                "docs",
                "Resources",
                ".gitignore",
                "README.md",
                "LICENSE",
                "logoquartz.png"
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
