import 'package:flutter/material.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/router/app_router.dart';
import 'package:pr_list/core/services/log_service.dart';
import 'package:pr_list/core/services/pr_sync_service.dart';
import 'package:pr_list/shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();
  Logger('main').info('App starting...');
  final initResult = await initDependencies();
  if (initResult.isLeft) {
    Logger('main').severe('Bootstrap failed: ${initResult.left.message}');
    runApp(const _BootstrapErrorApp());
    return;
  }
  Logger('main').info('Dependencies initialized');
  getIt<LogService>().start();
  Logger('main').info('LogService started, PrSyncService starting...');
  getIt<PrSyncService>().start();
  Logger('main').info('App running');
  runApp(const ProviderScope(child: PrListApp()));
}

void _setupLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });
}

class PrListApp extends StatelessWidget {
  const PrListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PR List',
      routerConfig: appRouter,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Startup failed'))),
    );
  }
}
