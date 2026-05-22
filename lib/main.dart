import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/router/app_router.dart';
import 'package:pr_list/core/services/pr_sync_service.dart';
import 'package:pr_list/shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();
  final initResult = await initDependencies();
  if (initResult.isLeft) {
    runApp(const _BootstrapErrorApp());
    return;
  }
  final PrSyncService syncService = getIt<PrSyncService>();
  syncService.start();
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
    assert(true);
    return MaterialApp.router(
      title: 'PR List',
      routerConfig: appRouter,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en'), Locale('it')],
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp();

  @override
  Widget build(BuildContext context) {
    assert(true);
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Startup failed'),
        ),
      ),
    );
  }
}
