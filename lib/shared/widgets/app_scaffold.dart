import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/core/services/log_service.dart';
import 'package:pr_list/core/services/update_notifier.dart';
import 'package:pr_list/features/pr_list/pr_form_dialog.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/projects/project_form_dialog.dart';
import 'package:pr_list/features/settings/env_mapping_dialog.dart';
import 'package:pr_list/features/settings/pat_settings_dialog.dart';
import 'package:pr_list/shared/widgets/update_available_dialog.dart';

class AppScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  @override
  void initState() {
    super.initState();
    ref.read(updateStateProvider.notifier).checkForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = widget.navigationShell.currentIndex;
    final viewMode = ref.watch(prListViewModeProvider);
    final nextRunAsync = ref.watch(schedulerNextRunProvider);
    final isSyncRunning = ref.watch(prSyncServiceProvider).isSyncRunning;
    ref.listen(updateStateProvider, (_, state) {
      if (state.status == UpdateStateStatus.available) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const UpdateAvailableDialog(),
        );
      }
      if (state.status == UpdateStateStatus.installing) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForTab(l10n, currentIndex)),
        actions: [
          TextButton.icon(
            onPressed: isSyncRunning
                ? null
                : () async {
                    final triggerSync = ref.read(triggerPrSyncProvider);
                    await triggerSync();
                  },
            icon: const Icon(Icons.schedule),
            label: Text(_buildSchedulerLabel(l10n, nextRunAsync.value)),
          ),
          if (currentIndex == 0)
            IconButton(
              tooltip: viewMode == PrListViewMode.groupedList
                  ? l10n.viewKanban
                  : l10n.viewList,
              onPressed: () {
                ref.read(prListViewModeProvider.notifier).state =
                    viewMode == PrListViewMode.groupedList
                        ? PrListViewMode.kanban
                        : PrListViewMode.groupedList;
              },
              icon: Icon(
                viewMode == PrListViewMode.groupedList
                    ? Icons.view_kanban
                    : Icons.view_list,
              ),
            ),
          IconButton(
            tooltip: l10n.envSettings,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const EnvMappingDialog(),
            ),
            icon: const Icon(Icons.alt_route),
          ),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const PatSettingsDialog(),
            ),
            icon: const Icon(Icons.vpn_key),
          ),
          IconButton(
            tooltip: l10n.tabLogs,
            onPressed: () => getIt<LogService>().openLogWindow(),
            icon: const Icon(Icons.terminal),
          ),
        ],
      ),
      body: widget.navigationShell,
      floatingActionButton: _fabForTab(currentIndex, context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => widget.navigationShell.goBranch(index),
        destinations: [
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

  String _titleForTab(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.tabPrList;
      case 1:
        return l10n.tabProjects;
      case 2:
        return l10n.tabDashboard;
      default:
        return '';
    }
  }

  Widget? _fabForTab(int index, BuildContext context) {
    switch (index) {
      case 0:
        return FloatingActionButton(
          onPressed: () =>
              showDialog(context: context, builder: (_) => const PrFormDialog()),
          child: const Icon(Icons.add),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () =>
              showDialog(context: context, builder: (_) => const ProjectFormDialog()),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  String _buildSchedulerLabel(AppLocalizations l10n, DateTime? nextRun) {
    if (nextRun == null) {
      return l10n.schedulerNotScheduled;
    }
    final remaining = nextRun.difference(DateTime.now());
    final positive = remaining.isNegative ? Duration.zero : remaining;
    final minutes = positive.inMinutes;
    final seconds = positive.inSeconds.remainder(60);
    return l10n.schedulerCountdown(minutes, seconds);
  }
}
