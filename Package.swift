// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CakePond",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CakePond", targets: ["CakePond"])
    ],
    targets: [
        .executableTarget(name: "CakePond"),
        .testTarget(name: "CakePondTests", dependencies: ["CakePond"])
    ]
)
