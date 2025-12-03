// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhiteboardApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WhiteboardApp", targets: ["WhiteboardApp"])
    ],
    targets: [
        .executableTarget(
            name: "WhiteboardApp",
            path: ".",
            exclude: [
                "Whiteboard.app",
                "bundle_app.sh"
            ],
            sources: [
                "WhiteboardApp.swift",
                "ContentView.swift",
                "WhiteboardViewModel.swift"
            ]
        )
    ]
)
