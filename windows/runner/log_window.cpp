#include "log_window.h"

#include <limits>
#include <sstream>



namespace {

constexpr const wchar_t kLogWindowClassName[] = L"PR_LIST_LOG_WINDOW";
constexpr const wchar_t kSearchDialogClassName[] = L"PR_LIST_SEARCH_DIALOG";
constexpr int kLogBufferSize = 1000;
constexpr int kSearchDlgWidth = 400;
constexpr int kSearchDlgHeight = 100;
constexpr int kIdSearchEdit = 100;
constexpr int kIdFindNextBtn = 101;
constexpr int kIdClearBtn = 102;

bool RegisterLogWindowClass() {
  WNDCLASS wc{};
  wc.lpfnWndProc = LogWindowManager::WndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.lpszClassName = kLogWindowClassName;
  wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
  return RegisterClass(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
}

bool RegisterSearchDialogClass() {
  WNDCLASS wc{};
  wc.lpfnWndProc = LogWindowManager::SearchWndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.lpszClassName = kSearchDialogClassName;
  wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
  return RegisterClass(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
}

HFONT CreateLogFont() {
  LOGFONT lf{};
  lf.lfHeight = -13;
  lf.lfWeight = FW_NORMAL;
  lf.lfCharSet = ANSI_CHARSET;
  lf.lfPitchAndFamily = FIXED_PITCH | FF_MODERN;
  wcscpy_s(lf.lfFaceName, L"Consolas");
  return CreateFontIndirect(&lf);
}

HFONT CreateDialogFont() {
  LOGFONT lf{};
  lf.lfHeight = -13;
  lf.lfWeight = FW_NORMAL;
  lf.lfCharSet = DEFAULT_CHARSET;
  lf.lfPitchAndFamily = VARIABLE_PITCH | FF_SWISS;
  wcscpy_s(lf.lfFaceName, L"Segoe UI");
  return CreateFontIndirect(&lf);
}

}  // namespace

LogWindowManager& LogWindowManager::GetInstance() {
  static LogWindowManager instance;
  return instance;
}

LogWindowManager::~LogWindowManager() {
  if (log_font_) {
    DeleteObject(log_font_);
  }
  CloseSearchDialog();
}

void LogWindowManager::Setup(flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.pr_list/log_window",
      &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<
                 flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto& method = call.method_name();
        if (method == "openLogWindow") {
          std::vector<std::string> buffer;
          const auto* args =
              std::get_if<flutter::EncodableList>(call.arguments());
          if (args) {
            for (const auto& item : *args) {
              if (auto* str = std::get_if<std::string>(&item)) {
                buffer.push_back(*str);
              }
            }
          }
          OpenWindow(buffer);
          result->Success();
        } else if (method == "onLog") {
          if (auto* entry =
                  std::get_if<std::string>(call.arguments())) {
            AppendLog(*entry);
          }
          result->Success();
        } else if (method == "clearLogWindow") {
          ClearLog();
          result->Success();
        } else if (method == "searchLogWindow") {
          if (auto* entry =
                  std::get_if<std::string>(call.arguments())) {
            std::wstring wtext;
            int len = MultiByteToWideChar(CP_UTF8, 0,
                                          entry->c_str(),
                                          static_cast<int>(entry->size()),
                                          nullptr, 0);
            if (len > 0) {
              wtext.resize(static_cast<size_t>(len));
              MultiByteToWideChar(CP_UTF8, 0, entry->c_str(),
                                  static_cast<int>(entry->size()),
                                  &wtext[0], len);
            }
            FindNext(wtext);
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
}

void LogWindowManager::OpenWindow(
    const std::vector<std::string>& initial_buffer) {
  if (log_window_ && IsWindowVisible(log_window_)) {
    BringWindowToTop(log_window_);
    ShowWindow(log_window_, SW_SHOW);
    return;
  }

  RegisterLogWindowClass();
  RegisterSearchDialogClass();

  if (!log_font_) {
    log_font_ = CreateLogFont();
  }

  log_window_ = CreateWindowEx(
      0, kLogWindowClassName, L"Logs",
      WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, CW_USEDEFAULT,
      CW_USEDEFAULT, 800, 500, nullptr, nullptr,
      GetModuleHandle(nullptr), this);

  if (!log_window_) {
    return;
  }

  CreateEditControl();
  SendInitialBuffer(initial_buffer);

  // Create menu bar with Edit submenu
  HMENU editMenu = CreatePopupMenu();
  AppendMenu(editMenu, MF_STRING, ID_EDIT_FIND, L"Find\tCtrl+F");
  AppendMenu(editMenu, MF_STRING, ID_EDIT_CLEAR, L"Clear Log\tCtrl+L");
  HMENU menuBar = CreateMenu();
  AppendMenu(menuBar, MF_POPUP | MF_STRING,
             reinterpret_cast<UINT_PTR>(editMenu), L"Edit");
  SetMenu(log_window_, menuBar);

  ShowWindow(log_window_, SW_SHOWNORMAL);
  UpdateWindow(log_window_);
}

void LogWindowManager::CreateEditControl() {
  edit_control_ = CreateWindowEx(
      WS_EX_CLIENTEDGE, L"EDIT", L"",
      ES_MULTILINE | ES_READONLY | ES_AUTOVSCROLL |
          ES_AUTOHSCROLL | WS_VSCROLL | WS_HSCROLL |
          WS_CHILD | WS_VISIBLE,
      0, 0, 0, 0, log_window_,
      reinterpret_cast<HMENU>(static_cast<INT_PTR>(1)), GetModuleHandle(nullptr),
      nullptr);

  if (edit_control_ && log_font_) {
    SendMessage(edit_control_, WM_SETFONT,
                reinterpret_cast<WPARAM>(log_font_), TRUE);
  }

  // Subclass to intercept keyboard shortcuts (Ctrl+F, Ctrl+L)
  original_edit_proc_ = reinterpret_cast<WNDPROC>(
      SetWindowLongPtr(edit_control_, GWLP_WNDPROC,
                       reinterpret_cast<LONG_PTR>(EditWndProc)));
}

void LogWindowManager::SendInitialBuffer(
    const std::vector<std::string>& initial_buffer) {
  if (!edit_control_) {
    return;
  }

  std::wostringstream wss;
  for (const auto& line : initial_buffer) {
    int len = MultiByteToWideChar(CP_UTF8, 0, line.c_str(),
                                  static_cast<int>(line.size()),
                                  nullptr, 0);
    if (len > 0) {
      std::wstring wline(static_cast<size_t>(len), L'\0');
      MultiByteToWideChar(CP_UTF8, 0, line.c_str(),
                          static_cast<int>(line.size()),
                          &wline[0], len);
      wss << wline << L"\r\n";
    }
  }
  std::wstring text = wss.str();

  SetWindowText(edit_control_, text.c_str());

  int nChars = GetWindowTextLength(edit_control_);
  SendMessage(edit_control_, EM_SETSEL,
              static_cast<WPARAM>(nChars),
              static_cast<LPARAM>(nChars));
  SendMessage(edit_control_, EM_SCROLLCARET, 0, 0);
}

void LogWindowManager::AppendLog(const std::string& entry) {
  if (!edit_control_) {
    return;
  }

  int len = MultiByteToWideChar(CP_UTF8, 0, entry.c_str(),
                                static_cast<int>(entry.size()),
                                nullptr, 0);
  if (len <= 0) {
    return;
  }
  std::wstring wentry(static_cast<size_t>(len), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, entry.c_str(),
                      static_cast<int>(entry.size()), &wentry[0],
                      len);
  wentry += L"\r\n";

  constexpr WPARAM kSelectEnd = std::numeric_limits<WPARAM>::max();
  SendMessage(edit_control_, EM_SETSEL, kSelectEnd,
              static_cast<LPARAM>(-1));
  SendMessage(edit_control_, EM_REPLACESEL,
              static_cast<WPARAM>(FALSE),
              reinterpret_cast<LPARAM>(wentry.c_str()));

  int nChars = GetWindowTextLength(edit_control_);
  SendMessage(edit_control_, EM_SETSEL,
              static_cast<WPARAM>(nChars),
              static_cast<LPARAM>(nChars));
  SendMessage(edit_control_, EM_SCROLLCARET, 0, 0);
}

void LogWindowManager::ClearLog() {
  if (!edit_control_) {
    return;
  }
  SetWindowText(edit_control_, L"");
  search_start_pos_ = 0;
}

void LogWindowManager::FindNext(const std::wstring& text) {
  if (!edit_control_ || text.empty()) {
    return;
  }

  search_string_ = text;

  // Get the full text from the edit control
  int textLen = GetWindowTextLength(edit_control_);
  if (textLen <= 0) {
    search_start_pos_ = 0;
    return;
  }

  std::wstring content(static_cast<size_t>(textLen), L'\0');
  GetWindowText(edit_control_, &content[0], textLen + 1);

  // Search from current position
  size_t found = content.find(text, static_cast<size_t>(search_start_pos_));

  // If not found, wrap around from beginning
  if (found == std::wstring::npos) {
    search_start_pos_ = 0;
    found = content.find(text, 0);
  }

  if (found != std::wstring::npos) {
    int start = static_cast<int>(found);
    int end = start + static_cast<int>(text.size());
    SendMessage(edit_control_, EM_SETSEL,
                static_cast<WPARAM>(start),
                static_cast<LPARAM>(end));
    SendMessage(edit_control_, EM_SCROLLCARET, 0, 0);
    search_start_pos_ = end;
  }

  // Update search dialog if open
  if (search_dialog_ && IsWindowVisible(search_dialog_)) {
    HWND edit = GetDlgItem(search_dialog_, kIdSearchEdit);
    if (edit) {
      SetWindowText(edit, search_string_.c_str());
    }
  }
}

void LogWindowManager::ShowSearchDialog() {
  if (search_dialog_ && IsWindowVisible(search_dialog_)) {
    BringWindowToTop(search_dialog_);
    SetFocus(GetDlgItem(search_dialog_, kIdSearchEdit));
    return;
  }

  if (!log_window_) {
    return;
  }

  RECT parentRect;
  GetWindowRect(log_window_, &parentRect);
  int x = parentRect.left + 10;
  int y = parentRect.top + 40;

  // Compute window size so client area is exactly kSearchDlgWidth x kSearchDlgHeight
  RECT clientRect = {0, 0, kSearchDlgWidth, kSearchDlgHeight};
  DWORD dlgStyle = WS_POPUP | WS_CAPTION | WS_SYSMENU;
  DWORD dlgExStyle = WS_EX_TOOLWINDOW | WS_EX_TOPMOST;
  AdjustWindowRectEx(&clientRect, dlgStyle, FALSE, dlgExStyle);
  int winW = clientRect.right - clientRect.left;
  int winH = clientRect.bottom - clientRect.top;

  search_dialog_ = CreateWindowEx(
      dlgExStyle,
      kSearchDialogClassName, L"Find",
      dlgStyle,
      x, y, winW, winH,
      log_window_, nullptr, GetModuleHandle(nullptr), this);

  if (!search_dialog_) {
    return;
  }

  HFONT dlgFont = CreateDialogFont();

  // Row 1: label + edit + Find Next button
  CreateWindowEx(0, L"STATIC", L"Find what:",
                 WS_CHILD | WS_VISIBLE,
                 8, 8, 60, 24,
                 search_dialog_,
                 reinterpret_cast<HMENU>(static_cast<INT_PTR>(103)),
                 GetModuleHandle(nullptr), nullptr);

  CreateWindowEx(0, L"EDIT", search_string_.c_str(),
                 WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
                 72, 8, 190, 24,
                 search_dialog_,
                 reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdSearchEdit)),
                 GetModuleHandle(nullptr), nullptr);

  CreateWindowEx(0, L"BUTTON", L"Find Next",
                 WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                 270, 8, 120, 26,
                 search_dialog_,
                 reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdFindNextBtn)),
                 GetModuleHandle(nullptr), nullptr);

  // Row 2: Clear Log button
  CreateWindowEx(0, L"BUTTON", L"Clear Log",
                 WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                 8, 44, 382, 30,
                 search_dialog_,
                 reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdClearBtn)),
                 GetModuleHandle(nullptr), nullptr);

  if (dlgFont) {
    HWND child = GetWindow(search_dialog_, GW_CHILD);
    while (child) {
      SendMessage(child, WM_SETFONT,
                  reinterpret_cast<WPARAM>(dlgFont), TRUE);
      child = GetWindow(child, GW_HWNDNEXT);
    }
    DeleteObject(dlgFont);
  }

  // Pre-fill and select the last search string
  HWND edit = GetDlgItem(search_dialog_, kIdSearchEdit);
  if (edit && !search_string_.empty()) {
    SetWindowText(edit, search_string_.c_str());
    SendMessage(edit, EM_SETSEL, 0, -1);
  }
  if (edit) {
    SetFocus(edit);
  }

  ShowWindow(search_dialog_, SW_SHOWNORMAL);
  UpdateWindow(search_dialog_);
}

void LogWindowManager::CloseSearchDialog() {
  if (search_dialog_) {
    DestroyWindow(search_dialog_);
    search_dialog_ = nullptr;
  }
}

LRESULT CALLBACK LogWindowManager::SearchWndProc(HWND hwnd,
                                                  UINT message,
                                                  WPARAM wparam,
                                                  LPARAM lparam) {
  switch (message) {
    case WM_COMMAND:
      if (LOWORD(wparam) == kIdFindNextBtn) {
        // Send find message to parent log window
        HWND edit = GetDlgItem(hwnd, kIdSearchEdit);
        if (edit) {
          int len = GetWindowTextLength(edit);
          if (len > 0) {
            std::wstring text(static_cast<size_t>(len) + 1, L'\0');
            GetWindowText(edit, &text[0], len + 1);
            text.resize(static_cast<size_t>(len));
            HWND parent = GetParent(hwnd);
            if (parent) {
              // Store string in a shared place and post message
              LogWindowManager& self = GetInstance();
              self.search_string_ = text;
              self.search_start_pos_ = 0;
              PostMessage(parent, WM_FIND_NEXT_MSG, 0, 0);
            }
          }
        }
        return 0;
      }
      if (LOWORD(wparam) == kIdClearBtn) {
        HWND parent = GetParent(hwnd);
        if (parent) {
          PostMessage(parent, WM_FIND_NEXT_MSG + 1, 0, 0);
        }
        return 0;
      }
      break;

    case WM_CLOSE:
      DestroyWindow(hwnd);
      return 0;

    case WM_DESTROY: {
      LogWindowManager* self = reinterpret_cast<LogWindowManager*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (self) {
        self->search_dialog_ = nullptr;
      }
      return 0;
    }

    case WM_NCCREATE: {
      auto* cs = reinterpret_cast<CREATESTRUCT*>(lparam);
      SetWindowLongPtr(hwnd, GWLP_USERDATA,
                       reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
      return DefWindowProc(hwnd, message, wparam, lparam);
    }

    case WM_SETFOCUS: {
      HWND edit = GetDlgItem(hwnd, kIdSearchEdit);
      if (edit) {
        SetFocus(edit);
      }
      return 0;
    }
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT CALLBACK LogWindowManager::EditWndProc(HWND hwnd,
                                               UINT message,
                                               WPARAM wparam,
                                               LPARAM lparam) {
  auto& self = GetInstance();
  if (message == WM_KEYDOWN) {
    bool ctrl = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
    if (ctrl) {
      switch (wparam) {
        case 'F':
          self.ShowSearchDialog();
          return 0;
        case 'L':
          self.ClearLog();
          return 0;
      }
    }
  }
  return CallWindowProc(self.original_edit_proc_, hwnd, message,
                         wparam, lparam);
}

LRESULT CALLBACK LogWindowManager::WndProc(HWND hwnd,
                                           UINT message,
                                           WPARAM wparam,
                                           LPARAM lparam) {
  switch (message) {
    case WM_SIZE: {
      HWND edit = GetDlgItem(hwnd, 1);
      if (edit) {
        RECT rc;
        GetClientRect(hwnd, &rc);
        SetWindowPos(edit, nullptr, 0, 0, rc.right, rc.bottom,
                     SWP_NOZORDER);
      }
      return 0;
    }

    case WM_DESTROY: {
      LogWindowManager* self = reinterpret_cast<LogWindowManager*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (self) {
        self->log_window_ = nullptr;
        self->edit_control_ = nullptr;
      }
      return 0;
    }

    case WM_NCCREATE: {
      auto* cs = reinterpret_cast<CREATESTRUCT*>(lparam);
      SetWindowLongPtr(hwnd, GWLP_USERDATA,
                       reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
      return DefWindowProc(hwnd, message, wparam, lparam);
    }

    case WM_COMMAND: {
      int id = LOWORD(wparam);
      LogWindowManager* self = reinterpret_cast<LogWindowManager*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (id == ID_EDIT_FIND && self) {
        self->ShowSearchDialog();
        return 0;
      }
      if (id == ID_EDIT_CLEAR && self) {
        self->ClearLog();
        return 0;
      }
      break;
    }

    case WM_KEYDOWN: {
      bool ctrl = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
      if (ctrl) {
        switch (wparam) {
          case 'F': {
            LogWindowManager* self = reinterpret_cast<LogWindowManager*>(
                GetWindowLongPtr(hwnd, GWLP_USERDATA));
            if (self) {
              self->ShowSearchDialog();
            }
            return 0;
          }
          case 'L': {
            LogWindowManager* self = reinterpret_cast<LogWindowManager*>(
                GetWindowLongPtr(hwnd, GWLP_USERDATA));
            if (self) {
              self->ClearLog();
            }
            return 0;
          }
        }
      }
      break;
    }

    case WM_FIND_NEXT_MSG: {
      LogWindowManager* self = reinterpret_cast<LogWindowManager*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (self && !self->search_string_.empty()) {
        self->FindNext(self->search_string_);
      }
      return 0;
    }

    case WM_FIND_NEXT_MSG + 1: {
      LogWindowManager* self = reinterpret_cast<LogWindowManager*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (self) {
        self->ClearLog();
      }
      return 0;
    }
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}
