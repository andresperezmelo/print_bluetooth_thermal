// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "print_bluetooth_thermal",
    platforms: [
        .macOS("10.15") // Versión mínima de macOS
    ],
    products: [
        // El nombre de la librería debe llevar un guion medio en lugar de guion bajo
        .library(name: "print-bluetooth-thermal", targets: ["print_bluetooth_thermal"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "print_bluetooth_thermal",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/print_bluetooth_thermal"
        )
    ]
)