#ifndef RUNNER_LOG_WINDOW_H_
#define RUNNER_LOG_WINDOW_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <vector>

#include <windows.h>

class LogWindowManager {
 public:
  static LogWindowManager& GetInstance();

  void Setup(flutter::BinaryMessenger* messenger);
  static LRESULT CALLBACK WndProc(HWND hwnd,
                                  UINT message,
                                  WPARAM wparam,
                                  LPARAM lparam);
  static LRESULT CALLBACK EditWndProc(HWND hwnd,
                                      UINT message,
                                      WPARAM wparam,
                                      LPARAM lparam);
  static LRESULT CALLBACK SearchWndProc(HWND hwnd,
                                        UINT message,
                                        WPARAM wparam,
                                        LPARAM lparam);

  void ClearLog();
  void FindNext(const std::wstring& text);

 private:
  LogWindowManager() = default;
  ~LogWindowManager();

  void OpenWindow(const std::vector<std::string>& initial_buffer);
  void AppendLog(const std::string& entry);

  void CreateEditControl();
  void SendInitialBuffer(const std::vector<std::string>& initial_buffer);
  void ShowSearchDialog();
  void CloseSearchDialog();

  HWND log_window_ = nullptr;
  HWND edit_control_ = nullptr;
  HWND search_dialog_ = nullptr;
  HFONT log_font_ = nullptr;
  WNDPROC original_edit_proc_ = nullptr;

  std::wstring search_string_;
  int search_start_pos_ = 0;

  static constexpr int ID_EDIT_FIND = 200;
  static constexpr int ID_EDIT_CLEAR = 201;
  static constexpr UINT WM_FIND_NEXT_MSG = WM_USER + 100;

  std::unique_ptr<
      flutter::MethodChannel<flutter::EncodableValue>>
      channel_;
};

#endif  // RUNNER_LOG_WINDOW_H_
