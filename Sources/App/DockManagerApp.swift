import SwiftUI

@main
struct DockManagerApp: App {
  var body: some Scene {
    MenuBarExtra(content: {
      Button("Reveal", action: {
        NSWorkspace.shared.selectFile(Bundle.main.bundlePath,
                                      inFileViewerRootedAtPath: "")
      })
      Divider()
      Button("Quit", action: { NSApplication.shared.terminate(nil) })
    }, label: {
      Image(systemName: "dock.rectangle")
        .onAppear {
          Engine.shared.start()
        }
    })
  }
}
