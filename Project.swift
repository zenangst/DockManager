import ProjectDescription
import ProjectDescriptionHelpers
import Foundation
import Env

// MARK: - Project

let bundleId = "com.zenangst.DockManager"

func xcconfig(_ targetName: String) -> String { "Configurations/\(targetName).xcconfig" }
func sources(_ folder: String) -> SourceFilesList { "Sources/**" }
func resources(_ folder: String) -> ResourceFileElements { "\(folder)/Resources/**" }

let envPath = URL(fileURLWithPath: String(#filePath))
    .deletingLastPathComponent()
    .absoluteString
    .replacingOccurrences(of: "file://", with: "")
    .appending(".env")

let env = EnvHelper(envPath)

let project = Project(
    name: "DockManager",
    options: Project.Options.options(
        textSettings: .textSettings(indentWidth: 2,
                                    tabWidth: 2)),
    targets: [
        Target(
            name: "DockManager",
            platform: .macOS,
            product: .app,
            bundleId: bundleId,
            deploymentTarget: DeploymentTarget.macOS(targetVersion: "13.0"),
            infoPlist: .file(path: .relativeToRoot("App/Info.plist")),
            sources: "Sources/**",
            resources: "Resources/**",
            entitlements: "App/Entitlements/com.zenangst.DockManager.entitlements",
            dependencies: [
                .external(name: "Windows"),
                .external(name: "Inject"),
            ],
            settings:
                Settings.settings(
                    base: [
                        "CODE_SIGN_IDENTITY": "Apple Development",
                        "CODE_SIGN_STYLE": "Automatic",
                        "CURRENT_PROJECT_VERSION": "1",
                        "DEVELOPMENT_TEAM": env["TEAM_ID"],
                        "ENABLE_HARDENED_RUNTIME": true,
                        "MARKETING_VERSION": "0.0.1",
                        "PRODUCT_NAME": "DockManager"
                    ],
                    configurations: [
                        .debug(name: "Debug", xcconfig: "\(xcconfig("Debug"))"),
                        .release(name: "Release", xcconfig: "\(xcconfig("Release"))")
                    ],
                    defaultSettings: .recommended)
        )
    ],
    schemes: [
        Scheme(
            name: "DockManager",
            shared: true,
            hidden: false,
            buildAction: .buildAction(targets: ["DockManager"]),
            runAction: .runAction(
                executable: "DockManager",
                arguments: Arguments.init(environment: [
                    "SOURCE_ROOT": "$(SRCROOT)"
                ]))
        )
    ],
    additionalFiles: [
        FileElement(stringLiteral: ".gitignore"),
        FileElement(stringLiteral: ".env"),
        FileElement(stringLiteral: "Project.swift"),
        FileElement(stringLiteral: "Tuist/Dependencies.swift"),
    ]
)
