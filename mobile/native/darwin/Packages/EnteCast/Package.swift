// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnteCast",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "EnteCast",
            targets: ["EnteCast"]
        ),
    ],
    dependencies: [
        // TODO: Uncomment when these packages are available:
        // .package(path: "../EnteCore"),
        // .package(path: "../EnteNetwork"),
        // .package(path: "../EnteCrypto"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "EnteCast",
            dependencies: [
                // TODO: Uncomment when these packages are available:
                // "EnteCore",
                // "EnteNetwork", 
                // "EnteCrypto",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "EnteCastTests",
            dependencies: ["EnteCast"]
        ),
    ]
)