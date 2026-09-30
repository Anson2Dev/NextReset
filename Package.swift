// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "TokenPark",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TokenPark", targets: ["TokenPark"])],
    targets: [
        .target(name: "TokenParkCore"),
        .executableTarget(name: "TokenPark", dependencies: ["TokenParkCore"]),
        .testTarget(name: "TokenParkCoreTests", dependencies: ["TokenParkCore"])
    ]
)
