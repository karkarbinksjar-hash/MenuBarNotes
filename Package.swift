// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MenuBarNotes",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "MenuBarNotes", targets: ["MenuBarNotes"]),
    ],
    targets: [
        .executableTarget(name: "MenuBarNotes"),
        .testTarget(name: "MenuBarNotesTests", dependencies: ["MenuBarNotes"]),
    ],
    swiftLanguageModes: [.v5]
)
