// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Gigavore",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "Gigavore",
            path: "Sources/Gigavore"
        )
    ]
)
