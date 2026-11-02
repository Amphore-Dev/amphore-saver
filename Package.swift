// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "amphore-saver",
    platforms: [.macOS("11.5")],
    products: [
        .library(name: "ScreensaverCore", targets: ["ScreensaverCore"]),
        .library(name: "KinogridaKit", targets: ["KinogridaKit"]),
        .library(name: "ShadesKit", targets: ["ShadesKit"]),
        .library(name: "PsykalaKit", targets: ["PsykalaKit"]),
    ],
    targets: [
        .target(name: "ScreensaverCore"),
        .target(name: "KinogridaKit", dependencies: ["ScreensaverCore"]),
        .target(name: "ShadesKit", dependencies: ["ScreensaverCore"], resources: [.copy("Resources/Remained.ttf")]),
        .target(name: "PsykalaKit", dependencies: ["ScreensaverCore"], resources: [.copy("Resources/Artworks")]),
    ]
)
