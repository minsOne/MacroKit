// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "MacroKit",
    platforms: [.macOS(.v11), .iOS(.v15), .tvOS(.v15), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MacroKit",
            targets: ["MacroKit"]
        ),
        .executable(
            name: "MacroPlayground",
            targets: ["MacroPlayground"]
        ),
    ],
    dependencies: [
        // Depend on the Swift 5.9 release of SwiftSyntax
 //       .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(name: "Macros",
               dependencies: [.target(name: "SwiftSyntaxWrapper")],
               path: "Sources/Implementation"),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "MacroKit", dependencies: ["Macros"], path: "Sources/Interface"),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "MacroPlayground", dependencies: ["MacroKit"], path: "Sources/Playground"),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "MacroKitTests",
            dependencies: [
                "Macros",
                .target(name: "SwiftSyntaxWrapper"),
            ]
        ),
        .binaryTarget(name: "SwiftSyntaxWrapper", path: "XCFramework/SwiftSyntaxWrapper.xcframework"),
    ]
)
