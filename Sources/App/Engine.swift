import Combine
import Cocoa
import Windows

final class Engine {
  var subscriptions: [AnyCancellable] = .init()
  var dockState: Dock = .unknown
  var dockPosition: Dock.Position = .bottom

  var leftThreshold: Double = 0
  var rightThreshold: Double = 0

  static private(set) var shared: Engine = .init()

  private init() { }

  func start() {
    let mask: NSEvent.EventTypeMask = [.leftMouseDragged, .mouseMoved, .flagsChanged, .keyDown]
    NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] in
      self?.handle($0)
    }

    NotificationCenter.default
      .publisher(for: NSApplication.didChangeScreenParametersNotification, object: nil)
      .sink { [weak self] _ in
        self?.run()
      }.store(in: &subscriptions)

    NSWorkspace.shared.publisher(for: \.frontmostApplication)
      .dropFirst()
      .sink { [weak self] _ in
        self?.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.375) {
          self?.run()
        }
      }.store(in: &subscriptions)

    _ = Dock.hasPrivileges()
    dockState = Dock.get()
  }

  private func handle(_ event: NSEvent) {
    let keyDownWithModifier = (event.type == .keyDown && !event.modifierFlags.isEmpty)
    guard
      keyDownWithModifier ||
      (!event.modifierFlags.isEmpty && event.type == .mouseMoved) ||
        event.type == .leftMouseDragged else {
      return
    }

    run()

    if keyDownWithModifier {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.375) {
        self.run()
      }
    }
  }

  private func run() {
    guard let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
    else { return }

    let windows = (try? WindowsInfo
      .getWindows([.optionOnScreenOnly, .excludeDesktopElements])
      .filter {
        $0.ownerName != "WindowManager" &&
        $0.rect.size.width > 160 &&
        $0.rect.size.height > 160
      }
    )
    ?? []

    // Check if mission control is active
    guard windows.allSatisfy({ $0.ownerName != "Dock" }) else {
      return
    }

    let predicate: (WindowModel) -> Bool
    let margin: CGFloat = 16

    switch Dock.Position.get() {
    case .bottom:
      predicate = { $0.rect.maxY <= activeScreen.visibleFrame.maxY - margin }
    case .left:
      predicate = { value in
        if activeScreen.visibleFrame.origin.x > 0 {
          self.leftThreshold = activeScreen.visibleFrame.origin.x * 1.1
        }
        return value.rect.origin.x > self.leftThreshold
      }
    case .right:
      predicate = { value in
        let offset = activeScreen.frame.width - activeScreen.visibleFrame.width
        if offset > 0 {
          self.rightThreshold = activeScreen.visibleFrame.width * 0.99
        }
        return value.rect.maxX < self.rightThreshold
      }
    }

    let shouldShowDock = windows.allSatisfy(predicate)

    switch dockState {
    case .shown:
      guard !shouldShowDock else { return }
      Dock.hide()
      dockState = .hidden
    case .hidden:
      guard shouldShowDock else { return }
      Dock.show()
      dockState = .shown
    case .unknown:
      break
    }
  }
}
