// swift-tools-version: 5.9
//
// Municipal Companion — SwiftUI iOS app for the Municipal Elections REST API.
//
// xtool packages a SwiftPM app from exactly ONE library product representing
// the main app (see the `xtool new` template), so this must be a plain
// `.target` + `.library`, NOT an executableTarget. `xtool.yml` (next to this
// file) supplies the bundle identifier and points at Info.plist.
//
// Tools-version 5.9 keeps every target in the Swift 5 language mode (iOS 16+,
// no third-party dependencies).
import PackageDescription

let package = Package(
    name: "MunicipalCompanion",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // The single library product xtool packages as the main app.
        .library(
            name: "MunicipalCompanion",
            targets: ["MunicipalCompanion"]
        )
    ],
    targets: [
        .target(
            name: "MunicipalCompanion",
            path: "Sources/MunicipalCompanion"
        )
    ]
)
