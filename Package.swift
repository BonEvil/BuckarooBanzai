// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BuckarooBanzai",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "BuckarooBanzai",
            targets: ["BuckarooBanzai"]
        )
    ],
    targets: [
        .target(
            name: "BuckarooBanzai",
            path: "BuckarooBanzai"
        ),
        .testTarget(
            name: "BuckarooBanzaiTests",
            dependencies: ["BuckarooBanzai"],
            path: "BuckarooBanzaiTests"
        )
    ]
)
