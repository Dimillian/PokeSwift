import ProjectDescription

let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "MACOSX_DEPLOYMENT_TARGET": "26.0",
    "DEVELOPMENT_TEAM": "",
]

let project = Project(
    name: "PokeSwift",
    organizationName: "dimillian",
    settings: .settings(base: baseSettings),
    targets: [
        .target(
            name: "PokeDataModel",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.dimillian.PokeSwift.PokeDataModel",
            deploymentTargets: .macOS("26.0"),
            sources: ["Sources/PokeDataModel/**"]
        ),
        .target(
            name: "PokeContent",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.dimillian.PokeSwift.PokeContent",
            deploymentTargets: .macOS("26.0"),
            sources: ["Sources/PokeContent/**"],
            dependencies: [
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeTelemetry",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.dimillian.PokeSwift.PokeTelemetry",
            deploymentTargets: .macOS("26.0"),
            sources: ["Sources/PokeTelemetry/**"],
            dependencies: [
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeCore",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.dimillian.PokeSwift.PokeCore",
            deploymentTargets: .macOS("26.0"),
            sources: ["Sources/PokeCore/**"],
            dependencies: [
                .target(name: "PokeContent"),
                .target(name: "PokeDataModel"),
                .target(name: "PokeTelemetry"),
            ]
        ),
        .target(
            name: "PokeUI",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.dimillian.PokeSwift.PokeUI",
            deploymentTargets: .macOS("26.0"),
            sources: ["Sources/PokeUI/**"],
            dependencies: [
                .target(name: "PokeCore"),
                .target(name: "PokeContent"),
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeExtractCLI",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "com.dimillian.PokeSwift.PokeExtractCLI",
            deploymentTargets: .macOS("26.0"),
            sources: ["Sources/PokeExtractCLI/**"],
            dependencies: [
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeHarness",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "com.dimillian.PokeSwift.PokeHarness",
            deploymentTargets: .macOS("26.0"),
            sources: ["Sources/PokeHarness/**"],
            dependencies: [
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeMac",
            destinations: .macOS,
            product: .app,
            bundleId: "com.dimillian.PokeSwift.PokeMac",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "PokeMac",
                "NSPrincipalClass": "NSApplication",
                "LSMinimumSystemVersion": "26.0",
            ]),
            sources: ["App/PokeMac/Sources/**"],
            resources: ["Content/**"],
            dependencies: [
                .target(name: "PokeCore"),
                .target(name: "PokeUI"),
                .target(name: "PokeContent"),
                .target(name: "PokeDataModel"),
                .target(name: "PokeTelemetry"),
            ]
        ),
        .target(
            name: "PokeExtractCLITests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.dimillian.PokeSwift.PokeExtractCLITests",
            deploymentTargets: .macOS("26.0"),
            sources: [
                "Tests/PokeExtractCLITests/**",
                "Sources/PokeExtractCLI/RedContentExtractor.swift",
            ],
            dependencies: [
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeCoreTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.dimillian.PokeSwift.PokeCoreTests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Tests/PokeCoreTests/**"],
            dependencies: [
                .target(name: "PokeCore"),
                .target(name: "PokeContent"),
                .target(name: "PokeDataModel"),
                .target(name: "PokeTelemetry"),
            ]
        ),
        .target(
            name: "PokeContentTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.dimillian.PokeSwift.PokeContentTests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Tests/PokeContentTests/**"],
            dependencies: [
                .target(name: "PokeContent"),
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeDataModelTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.dimillian.PokeSwift.PokeDataModelTests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Tests/PokeDataModelTests/**"],
            dependencies: [
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeTelemetryTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.dimillian.PokeSwift.PokeTelemetryTests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Tests/PokeTelemetryTests/**"],
            dependencies: [
                .target(name: "PokeTelemetry"),
                .target(name: "PokeDataModel"),
            ]
        ),
        .target(
            name: "PokeUITests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.dimillian.PokeSwift.PokeUITests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Tests/PokeUITests/**"],
            dependencies: [
                .target(name: "PokeUI"),
                .target(name: "PokeDataModel"),
            ]
        ),
    ]
)
