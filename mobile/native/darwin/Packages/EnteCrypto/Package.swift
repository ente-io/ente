// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnteCrypto",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "EnteCrypto",
            targets: ["EnteCrypto"]
        ),
    ],
    dependencies: [
        .package(path: "../EnteCore"),
        .package(path: "../EnteNetwork"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/jedisct1/swift-sodium.git", from: "0.9.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
    ],
    targets: [
        .target(
            name: "EnteCrypto",
            dependencies: [
                "EnteCore",
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Sodium", package: "swift-sodium"),
                .product(name: "BigInt", package: "BigInt"),
            ]
        ),
        .testTarget(
            name: "EnteCryptoTests",
            dependencies: [
                "EnteCrypto",
                "EnteCore",
                "EnteNetwork"
            ]
        ),
    ]
)
