// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Default",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "Default",
            targets: ["Default"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMajor(from: "602.0.0")),
    ],
    targets: [
        .macro(
            name: "DefaultMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Default",
            dependencies: ["DefaultMacros"]
        ),
        .testTarget(
            name: "DefaultTests",
            dependencies: ["Default"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
