// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ManhwaReader",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ManhwaReader", targets: ["ManhwaReader"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "ManhwaReader",
            dependencies: ["SwiftSoup"],
            path: "ManhwaReader"
        )
    ]
)
