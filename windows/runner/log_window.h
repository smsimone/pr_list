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

 private:
  LogWindowManager() = default;
  ~LogWindowManager();

  void OpenWindow(const std::vector<std::string>& initial_buffer);
  void AppendLog(const std::string& entry);

  void CreateEditControl();
  void SendInitialBuffer(const std::vector<std::string>& initial_buffer);

  HWND log_window_ = nullptr;
  HWND edit_control_ = nullptr;
  HFONT log_font_ = nullptr;

  std::unique_ptr<
      flutter::MethodChannel<flutter::EncodableValue>>
      channel_;
};

#endif  // RUNNER_LOG_WINDOW_H_
