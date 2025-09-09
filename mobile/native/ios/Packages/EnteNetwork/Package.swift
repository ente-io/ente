// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnteNetwork",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "EnteNetwork",
            targets: ["EnteNetwork"]
        ),
    ],
    dependencies: [
        .package(path: "../EnteCore"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "EnteNetwork",
            dependencies: [
                "EnteCore",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "EnteNetworkTests",
            dependencies: ["EnteNetwork"]
        ),
    ]
)
