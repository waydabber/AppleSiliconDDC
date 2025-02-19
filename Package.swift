// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "AppleSiliconDDC",
    products: [
        .library(
            name: "AppleSiliconDDC",
            targets: ["AppleSiliconDDC"]
        ),
        .executable(
            name: "ASDDC",
            targets: ["ASDDC"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AppleSiliconDDCObjC",
            path: "Sources/AppleSiliconDDCObjC",
            publicHeadersPath: "."
        ),
        .target(
            name: "AppleSiliconDDC",
            dependencies: ["AppleSiliconDDCObjC"],
            path: "Sources/AppleSiliconDDC",
            linkerSettings: [
                .linkedFramework("CoreDisplay", .when(platforms: [.macOS]))
            ]
        ),
        .executableTarget(
            name: "ASDDC",
            dependencies: [
                "AppleSiliconDDC",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/ASDDC"
        )
    ]
)