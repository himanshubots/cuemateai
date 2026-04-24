// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "cuemate",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "cuemate",
            targets: ["CuemateApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CuemateApp"
        )
    ]
)
