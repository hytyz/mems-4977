// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MunicipalCompanion",
    platforms: [
        .iOS(.v16)
    ],
    products: [
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
