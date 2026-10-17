// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MenuBarNotes",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "MenuBarNotes", targets: ["MenuBarNotes"]),
    ],
    targets: [
        .executableTarget(
            name: "MenuBarNotes",
            swiftLanguageMode: .v5
        ),
        .testTarget(
            name: "MenuBarNotesTests",
            dependencies: ["MenuBarNotes"],
            swiftLanguageMode: .v5
        ),
    ]
)
