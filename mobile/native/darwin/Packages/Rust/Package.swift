// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InferenceRS",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "InferenceRS", targets: ["InferenceRS"]),
    ],
    targets: [
        .binaryTarget(
            name: "InferenceRSFFI",
            path: "InferenceRSFFI.xcframework"
        ),
        .target(
            name: "InferenceRS",
            dependencies: ["InferenceRSFFI"],
            path: "Sources/InferenceRS",
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit")
            ]
        ),
        .testTarget(
            name: "InferenceRSTests",
            dependencies: ["InferenceRS"],
            path: "Tests/InferenceRSTests"
        ),
    ]
)
