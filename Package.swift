// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "monkey-swift",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "monkey-swift",
            dependencies: ["Token", "Lexer"]),
        .target(
            name: "Token",
            dependencies: []),
        .target(
            name: "Lexer",
            dependencies: ["Token"]),
        .testTarget(
            name: "monkey-swiftTests",
            dependencies: ["monkey-swift"]),
        .testTarget(
            name: "LexerTests",
            dependencies: ["Token", "Lexer"]),
    ]
)
