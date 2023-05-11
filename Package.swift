// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "OTMonolith",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/andreas16700/MockShopifyClient", branch: "main"),
		.package(url: "https://github.com/andreas16700/MockPowersoftClient", branch: "main"),
		.package(url: "https://github.com/andreas16700/OTModelSyncer_pub", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
				"MockShopifyClient"
				,"MockPowersoftClient"
                ,.product(name: "Vapor", package: "vapor")
                ,.product(name: "OTModelSyncer", package: "OTModelSyncer_pub")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://www.swift.org/server/guides/building.html#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
