// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineAsync",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "CombineAsync",
            targets: ["CombineAsync"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/hainayanda/Retain.git", from: "1.0.2"),
        // uncomment code below to test
//        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
//        .package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "CombineAsync",
            dependencies: ["Retain"],
            path: "CombineAsync/Classes"
        ),
        // uncomment code below to test
//        .testTarget(
//            name: "CombineAsyncTests",
//            dependencies: [
//                "CombineAsync", "Quick", "Nimble"
//            ],
//            path: "Example/Tests",
//            exclude: ["Info.plist"]
//        )
    ]
)
