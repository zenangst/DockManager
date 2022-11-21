import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
      .remote(url: "https://github.com/zenangst/Windows.git", requirement: .exact("1.0.0")),
      .remote(url: "https://github.com/krzysztofzablocki/Inject.git", requirement: .exact("1.2.2"))
    ],
    platforms: [.macOS]
)
