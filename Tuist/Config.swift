import ProjectDescription

let config = Config(
  swiftVersion: "5.7.1",
  plugins: [
    .local(path: .relativeToManifest("../../Plugins/Tuist")),
  ]
)
