import Cocoa

enum Dock {
  enum Position: String {
    case left
    case right
    case bottom

    static func get() -> Position {
      guard let dockDefaults = UserDefaults(suiteName: "com.apple.dock") else {
        return .bottom
      }
      return Dock.Position(rawValue: dockDefaults.string(forKey: "orientation") ?? "bottom") ?? .bottom
    }
  }

  case unknown, shown, hidden

  func toggle() {
    switch self {
    case .shown, .unknown:
      Dock.hide()
    case .hidden:
      Dock.show()
    }
  }

  static func position(_ screen: NSScreen) -> Position {
    if screen.visibleFrame.width == screen.frame.width {
      return .bottom
    } else if screen.visibleFrame.origin == .zero {
      return .right
    } else {
      return .left
    }
  }

  static func get() -> Dock {
    let result = try? TerminalCommand.run("defaults read com.apple.Dock autohide")
    if result == "0" {
      return .shown
    } else if result == "1" {
      return .hidden
    } else {
      return .unknown
    }
  }

  static func show() {
    Task {
      var errorInfo: NSDictionary?
      let source = source("tell dock preferences to set autohide to not autohide")
      let appleScript = NSAppleScript(source: source)
      appleScript?.executeAndReturnError(&errorInfo)
    }
  }

  static func hide() {
    Task {
      var errorInfo: NSDictionary?
      let source = source("tell dock preferences to set autohide to true")
      let appleScript = NSAppleScript(source: source)
      appleScript?.executeAndReturnError(&errorInfo)
    }
  }

  static private func source(_ contents: String) -> String {
    return """
    tell application "System Events"
        \(contents)
    end tell
    """
  }

  static func hasPrivileges() -> Bool {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let privOptions = [trusted: true] as CFDictionary
    let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)

    return accessEnabled
  }
}
