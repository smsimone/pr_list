import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/services/log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.pr_list/log_window');

  late LogService service;
  late List<MethodCall> calls;

  setUp(() {
    Logger.root.level = Level.ALL;
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return null;
    });

    service = LogService();
    service.start();
  });

  tearDown(() async {
    service.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('forwards incoming logs to native channel', () async {
    Logger('test_logger').info('hello from logger');
    await Future<void>.delayed(Duration.zero);

    final List<MethodCall> onLogCalls =
        calls.where((MethodCall c) => c.method == 'onLog').toList();

    expect(onLogCalls, isNotEmpty);
    final MethodCall onLogCall = onLogCalls.last;
    expect(onLogCall.arguments, isA<String>());
    expect(onLogCall.arguments as String, contains('test_logger'));
    expect(onLogCall.arguments as String, contains('hello from logger'));
  });

  test('openLogWindow sends buffered entries', () async {
    Logger('buffer_test').warning('buffer line');
    await Future<void>.delayed(Duration.zero);

    service.openLogWindow();
    await Future<void>.delayed(Duration.zero);

    final List<MethodCall> openCalls =
        calls.where((MethodCall c) => c.method == 'openLogWindow').toList();

    expect(openCalls, isNotEmpty);
    final MethodCall openCall = openCalls.last;
    expect(openCall.arguments, isA<List<dynamic>>());

    final List<dynamic> buffer = openCall.arguments as List<dynamic>;
    expect(buffer.whereType<String>().any((line) => line.contains('buffer_test')), isTrue);
    expect(buffer.whereType<String>().any((line) => line.contains('buffer line')), isTrue);
  });
}
