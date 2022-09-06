// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(macOS)
let excludeFiles = [
    "./Browser/BrowserViewController.swift" // Because of inheriting iOS only class failed to build on macOS.
]
#elseif os(iOS)
let excludeFiles: String = []
#endif

let package = Package(
    name: "web3swift",
    platforms: [
        .macOS(.v10_12), .iOS(.v11)
    ],
    products: [
        .library(name: "web3swift", targets: ["web3swift"]),
    ],

    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", .upToNextMinor(from: "5.3.0")),
        .package(url: "https://github.com/Boilertalk/secp256k1.swift.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/mxcl/PromiseKit.git", .upToNextMinor(from: "6.16.2")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMinor(from: "4.0.4")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.5.1"))
    ],
    targets: [
        .target(
            name: "web3swift",
            dependencies: [
                "BigInt",
                .product(name: "secp256k1", package: "secp256k1.swift"),
                "PromiseKit",
                "Starscream",
                "CryptoSwift"],
            exclude: excludeFiles,
            resources: [
                .copy("./Browser/browser.js"),
                .copy("./Browser/browser.min.js"),
                .copy("./Browser/wk.bridge.min.js")
            ]
        ),
        .testTarget(
            name: "localTests",
            dependencies: ["web3swift"],
            path: "Tests/web3swiftTests/localTests",
            resources: [
                .copy("../../../TestToken/Helpers/SafeMath/SafeMath.sol"),
                .copy("../../../TestToken/Helpers/TokenBasics/ERC20.sol"),
                .copy("../../../TestToken/Helpers/TokenBasics/IERC20.sol"),
                .copy("../../../TestToken/Token/Web3SwiftToken.sol")
            ]
        ),
        .testTarget(
            name: "remoteTests",
            dependencies: ["web3swift"],
            path: "Tests/web3swiftTests/remoteTests",
            resources: [
                .copy("../../../TestToken/Helpers/SafeMath/SafeMath.sol"),
                .copy("../../../TestToken/Helpers/TokenBasics/ERC20.sol"),
                .copy("../../../TestToken/Helpers/TokenBasics/IERC20.sol"),
                .copy("../../../TestToken/Token/Web3SwiftToken.sol")
            ]
        )
    ]
)
