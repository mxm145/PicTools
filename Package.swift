// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PicTools",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PicTools", targets: ["PicTools"])
    ],
    targets: [
        .executableTarget(name: "PicTools"),
        .testTarget(name: "PicToolsTests", dependencies: ["PicTools"])
    ]
)
