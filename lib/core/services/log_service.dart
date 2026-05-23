import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class LogService {
  static const _channel = MethodChannel('com.pr_list/log_window');
  static const _maxEntries = 1000;

  final _controller = StreamController<LogRecord>.broadcast();
  final List<LogRecord> _buffer = [];
  StreamSubscription? _subscription;

  void start() {
    _subscription = Logger.root.onRecord.listen(_onLog);
  }

  void _onLog(LogRecord record) {
    _buffer.add(record);
    if (_buffer.length > _maxEntries) _buffer.removeAt(0);
    _controller.add(record);
    final line =
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}';
    _channel.invokeMethod('onLog', line);
  }

  void openLogWindow() => _channel.invokeMethod('openLogWindow');

  Stream<LogRecord> get stream => _controller.stream;
  List<LogRecord> get entries => List.unmodifiable(_buffer);

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
