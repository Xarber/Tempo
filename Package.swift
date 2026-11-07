// swift-tools-version: 6.0
// SPDX-License-Identifier: AGPL-3.0-only
import PackageDescription
let package = Package(name: "Tempo", platforms: [.macOS(.v14), .iOS(.v17)], products: [.library(name: "TempoCore", targets: ["TempoCore"]), .executable(name: "Tempo", targets: ["Tempo"])], targets: [.systemLibrary(name: "CSQLite", pkgConfig: "sqlite3"), .target(name: "TempoCore", dependencies: ["CSQLite"]), .executableTarget(name: "Tempo", dependencies: ["TempoCore"]), .testTarget(name: "TempoCoreTests", dependencies: ["TempoCore"])])
