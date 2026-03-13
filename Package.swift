// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZaiSubscriptionWidget",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ZaiSubscriptionWidget", targets: ["ZaiSubscriptionWidget"])
    ],
    targets: [
        .executableTarget(
            name: "ZaiSubscriptionWidget",
            path: "ZaiSubscriptionWidget"
        )
    ]
)
