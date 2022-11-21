import Combine
import Cocoa
import Windows

final class Engine {
  var subscription: AnyCancellable?
  var dockState: Dock = .unknown
  var dockPosition: Dock.Position = .bottom

  static private(set) var shared: Engine = .init()

  private init() { }

  func start() {
    let mask: NSEvent.EventTypeMask = [.leftMouseDragged, .mouseMoved, .flagsChanged]
    NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] in
      self?.handle($0)
    }
    subscription = NSWorkspace.shared.publisher(for: \.frontmostApplication)
      .dropFirst()
      .sink { [weak self] _ in
      self?.run()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.375) {
        self?.run()
      }
    }
    _ = Dock.hasPrivileges()
    dockState = Dock.get()
  }

  private func handle(_ event: NSEvent) {
    guard (!event.modifierFlags.isEmpty && event.type == .mouseMoved) || event.type == .leftMouseDragged else {
      return
    }
    run()
  }

  private func run() {
    guard let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) else {
      return
    }
    let windows = (try? WindowsInfo
      .getWindows([.excludeDesktopElements, .optionOnScreenOnly])
      .filter {
        $0.ownerName != "WindowManager" &&
        $0.rect.size.width > 160 &&
        $0.rect.size.height > 160
      }) ?? []

    let predicate: (WindowModel) -> Bool
    let dockPosition: Dock.Position

    if dockState == .hidden {
      dockPosition = self.dockPosition
    } else {
      dockPosition = Dock.position(activeScreen)
    }

    switch dockPosition {
    case .bottom:
      predicate = {
        $0.rect.maxY <= activeScreen.visibleFrame.maxY

      }
    case .left:
      predicate = { $0.rect.origin.x > activeScreen.visibleFrame.origin.x }
    case .right:
      predicate = { $0.rect.maxX < activeScreen.visibleFrame.width }
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
