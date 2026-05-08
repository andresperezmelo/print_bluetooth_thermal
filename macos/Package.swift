// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "print_bluetooth_thermal",
    platforms: [
        .macOS("10.15") // Versión mínima recomendada para macOS
    ],
    products: [
        .library(name: "print-bluetooth-thermal", targets: ["print_bluetooth_thermal"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "print_bluetooth_thermal",
            dependencies: [],
            path: "Classes",
            resources: []
        )
    ]
)