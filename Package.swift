// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "fireterm",
    targets: [
        .target(name: "FiretermLib"),
        .executableTarget(name: "fireterm", dependencies: ["FiretermLib"]),
        .testTarget(name: "FiretermTests", dependencies: ["FiretermLib"]),
    ]
)
