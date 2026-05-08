// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "print_bluetooth_thermal",
    platforms: [
        .iOS("13.0") // Versión mínima recomendada para Bluetooth
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