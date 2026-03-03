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
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
    ],
    targets: [
        .binaryTarget(
            name: "EnteRustCryptoFFI",
            path: "Binaries/EnteRustCryptoFFI.xcframework"
        ),
        .target(
            name: "EnteCrypto",
            dependencies: [
                "EnteCore",
                "EnteRustCryptoFFI",
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "BigInt", package: "BigInt"),
            ],
            linkerSettings: [
                .linkedFramework("SystemConfiguration", .when(platforms: [.macOS])),
            ]
        ),
        .testTarget(
            name: "EnteCryptoTests",
            dependencies: [
                "EnteCrypto",
                "EnteCore"
            ]
        ),
    ]
)
