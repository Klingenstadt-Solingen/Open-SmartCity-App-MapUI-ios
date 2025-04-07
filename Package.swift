// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

/// use local package path
let packageLocal: Bool = false

let oscaEssentialsVersion = Version("1.1.0")
let oscaTestCaseExtensionVersion = Version("1.1.0")
let oscaMapVersion = Version("1.1.0")
let atomicsVersion = Version("1.1.0")
let deviceKitVersion = Version("5.0.0")

let package = Package(
  name: "OSCAMapUI",
  defaultLocalization: "de",
  platforms: [.iOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "OSCAMapUI",
      targets: ["OSCAMapUI"]
    )
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),

   // OSCAEssentials
    packageLocal ? .package(path: "../OSCAEssentials") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscaessentials-ios.git",
             .upToNextMinor(from: oscaEssentialsVersion)),
    /* OSCAMap */
    packageLocal ? .package(path: "../OSCAMap") :
    .package(
      url: "https://git-dev.solingen.de/smartcityapp/modules/oscamap-ios.git",
      .upToNextMinor(from: oscaMapVersion)),
    /* Atomics */
    .package(
      url: "https://github.com/apple/swift-atomics.git",
      .upToNextMinor(from: atomicsVersion)),
    /* DeviceKit */
    .package(
      url: "https://github.com/devicekit/DeviceKit.git",
      .upToNextMinor(from: deviceKitVersion)),
    // OSCATestCaseExtension
    packageLocal ? .package(path: "../OSCATestCaseExtension") :
    .package(
      url: "https://git-dev.solingen.de/smartcityapp/modules/oscatestcaseextension-ios.git",
      .upToNextMinor(from: oscaTestCaseExtensionVersion))
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "OSCAMapUI",
      dependencies: [
        .product(
          name: "OSCAMap",
          package: packageLocal ? "OSCAMap" : "oscamap-ios"
        ),
        /* OSCAEssentials */
        .product(name: "OSCAEssentials",
                 package: packageLocal ? "OSCAEssentials" : "oscaessentials-ios"),
        .product(
          name: "Atomics",
          package: "swift-atomics"
        ),
        .product(
          name: "DeviceKit",
          package: "DeviceKit"
        )
      ],
      path: "OSCAMapUI/OSCAMapUI",
      exclude: [
        "Info.plist",
        "SupportingFiles"
      ],
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "OSCAMapUITests",
      dependencies: [
        "OSCAMapUI",
        .product(
          name: "OSCATestCaseExtension",
          package: packageLocal ? "OSCATestCaseExtension" : "oscatestcaseextension-ios"
        )
      ],
      path: "OSCAMapUI/OSCAMapUITests",
      exclude: ["Info.plist"],
      resources: [.process("Resources")] /* ,
       swiftSettings: [
       .define("ENABLE_SOMETHING",
       .when(configuration: .debug))
       ] */
    )
  ],
  swiftLanguageVersions: [.v5]
)
