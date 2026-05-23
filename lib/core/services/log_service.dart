import 'dart:async';

import 'package:logging/logging.dart';
import 'package:flutter/services.dart';

class LogService {
  static const _channel = MethodChannel('com.pr_list/log_window');
  static const _maxEntries = 1000;

  final _controller = StreamController<LogRecord>.broadcast();
  final List<LogRecord> _buffer = [];
  StreamSubscription? _subscription;

  void start() {
    Logger.root.info('LogService started');
    _subscription = Logger.root.onRecord.listen(_onLog);
  }

  void _onLog(LogRecord record) {
    _buffer.add(record);
    if (_buffer.length > _maxEntries) _buffer.removeAt(0);
    _controller.add(record);
    _channel.invokeMethod('onLog', _formatRecord(record));
  }

  void openLogWindow() {
    final buffer = _buffer.map(_formatRecord).toList();
    _channel.invokeMethod('openLogWindow', buffer);
  }

  String _formatRecord(LogRecord r) =>
      '${r.level.name}: ${r.time}: ${r.loggerName}: ${r.message}';

  Stream<LogRecord> get stream => _controller.stream;
  List<LogRecord> get entries => List.unmodifiable(_buffer);

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
