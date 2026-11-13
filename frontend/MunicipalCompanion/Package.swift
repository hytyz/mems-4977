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
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "MunicipalCompanion",
            dependencies: [
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "Sources/MunicipalCompanion"
        )
    ]
)
