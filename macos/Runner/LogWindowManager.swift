import Cocoa
import FlutterMacOS

class LogWindowManager: NSObject {
  static let shared = LogWindowManager()

  private var channel: FlutterMethodChannel?
  private var window: NSWindow?
  private var textView: NSTextView?

  func setup(controller: FlutterViewController) {
    let methodChannel = FlutterMethodChannel(
      name: "com.pr_list/log_window",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel = methodChannel

    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "openLogWindow":
        let buffer = call.arguments as? [String] ?? []
        self.openWindow(initialBuffer: buffer)
      case "onLog":
        if let entry = call.arguments as? String {
          self.appendLog(entry)
        }
      default:
        result(FlutterMethodNotImplemented)
        return
      }

      result(nil)
    }
  }

  private func openWindow(initialBuffer: [String]) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      if let win = self.window {
        self.applyBuffer(initialBuffer)
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
      self.textView = tv

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
      self.window = win

      self.applyBuffer(initialBuffer)
      win.makeKeyAndOrderFront(nil)
    }
  }

  private func applyBuffer(_ buffer: [String]) {
    guard let tv = textView else { return }
    let full = buffer.joined(separator: "\n")
    tv.string = full.isEmpty ? "" : full + "\n"
    tv.scrollToEndOfDocument(nil)
  }

  private func appendLog(_ entry: String) {
    DispatchQueue.main.async { [weak self] in
      guard
        let self,
        let tv = self.textView,
        let win = self.window,
        win.isVisible
      else {
        return
      }

      let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: "Menlo", size: 11) ?? NSFont.systemFont(ofSize: 11),
      ]
      tv.textStorage?.append(NSAttributedString(string: entry + "\n", attributes: attrs))
      tv.scrollToEndOfDocument(nil)
    }
  }
}
