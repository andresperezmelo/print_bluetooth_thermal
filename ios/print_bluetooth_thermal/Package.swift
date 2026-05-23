// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "print_bluetooth_thermal",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        // Flutter requiere que si el plugin contiene "_" en el nombre,
        // el nombre de la librería use guiones medios "-"
        .library(name: "print-bluetooth-thermal", targets: ["print_bluetooth_thermal"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "print_bluetooth_thermal",
            dependencies: [
                // Corrección: El nombre correcto del producto es "FlutterFramework"
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/print_bluetooth_thermal"
        )
    ]
)