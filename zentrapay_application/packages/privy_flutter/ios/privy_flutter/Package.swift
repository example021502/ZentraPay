// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "privy_flutter",
    platforms: [
        .iOS("17.0"),
        .macOS("11.0")
    ],
    products: [
        .library(name: "privy-flutter", targets: ["privy_flutter"])
    ],
    dependencies: [
        .package(url: "https://github.com/privy-io/privy-ios", from: "2.12.0"),
    ],
    targets: [
        .target(
            name: "privy_flutter",
            dependencies: [
                .product(name: "Privy", package: "privy-ios")
            ],
            path: "Sources/privy_flutter"  // Points to the combined directory for both Swift and ObjC source files
        )
    ]
)
