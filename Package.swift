// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VimeoMetadata",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "VimeoMetadata",
            targets: ["VimeoMetadata"]
        ),
    ],
    targets: [
        .target(
            name: "VimeoMetadata",
            dependencies: []
        ),
        .testTarget(
            name: "VimeoMetadataTests",
            dependencies: ["VimeoMetadata"]
        ),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
