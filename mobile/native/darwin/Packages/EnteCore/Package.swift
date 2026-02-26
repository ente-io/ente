// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnteCore",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "EnteCore",
            targets: ["EnteCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged.git", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "EnteCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .testTarget(
            name: "EnteCoreTests",
            dependencies: ["EnteCore"]
        ),
    ]
)
