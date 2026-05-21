// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "RSBeforeAfterImageView",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "RSBeforeAfterImageView", targets: ["RSBeforeAfterImageView"]),
    ],
    targets: [
        .target(
            name: "RSBeforeAfterImageView",
            path: "Pod/Classes"
        ),
    ]
)
