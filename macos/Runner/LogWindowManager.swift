import Cocoa
import FlutterMacOS

class LogWindowManager: NSObject {
  static let shared = LogWindowManager()

  private var window: NSWindow?
  private var textView: NSTextView?

  func setup(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "com.pr_list/log_window",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "openLogWindow":
        let buffer = call.arguments as? [String] ?? []
        self?.openWindow(initialBuffer: buffer)
      case "onLog":
        if let entry = call.arguments as? String {
          self?.appendLog(entry)
        }
      default:
        result(FlutterMethodNotImplemented)
        return
      }
      result(nil)
    }
  }

  private func openWindow(initialBuffer: [String]) {
    if let win = window {
      if win.isVisible {
        win.makeKeyAndOrderFront(nil)
        return
      }
      win.makeKeyAndOrderFront(nil)
      return
    }

    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 800, height: 500))
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = false
    scrollView.borderType = .noBorder

    let tv = NSTextView()
    tv.isEditable = false
    tv.isSelectable = true
    tv.font = NSFont(name: "Menlo", size: 11)
    tv.autoresizingMask = [.width, .height]
    scrollView.documentView = tv
    textView = tv

    let win = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    win.isReleasedWhenClosed = false
    win.title = "Logs"
    win.center()
    win.contentView = scrollView
    window = win

    let full = initialBuffer.joined(separator: "\n")
    if !full.isEmpty {
      tv.string = full + "\n"
      tv.scrollToEndOfDocument(nil)
    }

    win.makeKeyAndOrderFront(nil)
  }

  private func appendLog(_ entry: String) {
    guard let tv = textView, let win = window, win.isVisible else { return }
    DispatchQueue.main.async {
      let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: "Menlo", size: 11) ?? NSFont.systemFont(ofSize: 11),
      ]
      tv.textStorage?.append(NSAttributedString(string: entry + "\n", attributes: attrs))
      tv.scrollToEndOfDocument(nil)
    }
  }
}
