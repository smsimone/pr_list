#include "log_window.h"

#include <sstream>

namespace {

constexpr const wchar_t kLogWindowClassName[] = L"PR_LIST_LOG_WINDOW";
constexpr int kLogBufferSize = 1000;

bool RegisterLogWindowClass() {
  WNDCLASS wc{};
  wc.lpfnWndProc = LogWindowManager::WndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.lpszClassName = kLogWindowClassName;
  wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
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

}  // namespace

LogWindowManager& LogWindowManager::GetInstance() {
  static LogWindowManager instance;
  return instance;
}

LogWindowManager::~LogWindowManager() {
  if (log_font_) {
    DeleteObject(log_font_);
  }
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
      reinterpret_cast<HMENU>(1), GetModuleHandle(nullptr),
      nullptr);

  if (edit_control_ && log_font_) {
    SendMessage(edit_control_, WM_SETFONT,
                reinterpret_cast<WPARAM>(log_font_), TRUE);
  }
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

  SendMessage(edit_control_, EM_SETSEL, -1, -1);
  SendMessage(edit_control_, EM_REPLACESEL, FALSE,
              reinterpret_cast<LPARAM>(wentry.c_str()));

  int nChars = GetWindowTextLength(edit_control_);
  SendMessage(edit_control_, EM_SETSEL,
              static_cast<WPARAM>(nChars),
              static_cast<LPARAM>(nChars));
  SendMessage(edit_control_, EM_SCROLLCARET, 0, 0);
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
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}
