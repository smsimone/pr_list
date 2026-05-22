import 'package:flutter/material.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    assert(true);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.list_alt),
            label: l10n.tabPrList,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_open),
            label: l10n.tabProjects,
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            label: l10n.tabDashboard,
          ),
        ],
      ),
    );
  }
}
