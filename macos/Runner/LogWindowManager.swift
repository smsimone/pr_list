import Cocoa
import FlutterMacOS

class LogWindowManager: NSObject {
  static let shared = LogWindowManager()

  private var channel: FlutterMethodChannel?
  private var window: NSWindow?
  private var textView: NSTextView?
  private var searchField: NSSearchField?
  private var searchPanel: NSWindow?
  private var searchStart: Int = 0

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
      case "clearLogWindow":
        self.clearLog()
      case "searchLogWindow":
        if let query = call.arguments as? String {
          self.findNext(query)
        }
      default:
        result(FlutterMethodNotImplemented)
        return
      }

      result(nil)
    }

    // Register for keyboard shortcuts
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self, let win = self.window, win.isKeyWindow else {
        return event
      }
      if event.modifierFlags.contains(.command) {
        if event.charactersIgnoringModifiers == "f" {
          self.showSearchPanel()
          return nil
        }
        if event.charactersIgnoringModifiers == "l" {
          self.clearLog()
          return nil
        }
      }
      return event
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

  private func clearLog() {
    DispatchQueue.main.async { [weak self] in
      guard let tv = self?.textView else { return }
      tv.string = ""
      self?.searchStart = 0
    }
  }

  private func findNext(_ query: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self, let tv = self.textView, !query.isEmpty else { return }
      let text = tv.string as NSString
      let range = text.range(
        of: query,
        options: .caseInsensitive,
        range: NSRange(location: self.searchStart, length: text.length - self.searchStart)
      )
      if range.location != NSNotFound {
        tv.setSelectedRange(range)
        tv.scrollRangeToVisible(range)
        self.searchStart = range.location + 1
      } else {
        // Wrap around
        let wrapped = text.range(
          of: query,
          options: .caseInsensitive,
          range: NSRange(location: 0, length: text.length)
        )
        if wrapped.location != NSNotFound {
          tv.setSelectedRange(wrapped)
          tv.scrollRangeToVisible(wrapped)
          self.searchStart = wrapped.location + 1
        } else {
          NSSound.beep()
        }
      }
    }
  }

  private func showSearchPanel() {
    guard let win = window else { return }

    if let panel = searchPanel, panel.isVisible {
      panel.makeKeyAndOrderFront(nil)
      return
    }

    let panel = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 320, height: 40),
      styleMask: [.titled, .closable, .utilityWindow],
      backing: .buffered,
      defer: false
    )
    panel.isReleasedWhenClosed = false
    panel.title = "Find"
    panel.level = .floating

    let content = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 40))

    let searchField = NSSearchField(frame: NSRect(x: 8, y: 8, width: 190, height: 24))
    searchField.sendsWholeSearchString = false
    searchField.sendsSearchStringImmediately = false
    searchField.target = self
    searchField.action = #selector(searchFieldAction(_:))
    searchField.bezelStyle = .texturedRounded

    let btn = NSButton(frame: NSRect(x: 206, y: 8, width: 100, height: 24))
    btn.title = "Find Next"
    btn.bezelStyle = .rounded
    btn.target = self
    btn.action = #selector(findNextAction(_:))

    content.addSubview(searchField)
    content.addSubview(btn)
    panel.contentView = content

    // Position near parent
    var parentFrame = win.frame
    panel.setFrameTopLeftPoint(NSPoint(x: parentFrame.minX + 10, y: parentFrame.maxY - 40))

    self.searchField = searchField
    self.searchPanel = panel
    panel.makeKeyAndOrderFront(nil)
  }

  @objc private func searchFieldAction(_ sender: NSSearchField) {
    let query = sender.stringValue
    if !query.isEmpty {
      searchStart = 0
      findNext(query)
    }
  }

  @objc private func findNextAction(_ sender: NSButton) {
    guard let query = searchField?.stringValue, !query.isEmpty else { return }
    searchStart = 0
    findNext(query)
  }
}
