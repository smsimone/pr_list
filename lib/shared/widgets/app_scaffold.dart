import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/core/services/log_service.dart';
import 'package:pr_list/core/services/update_notifier.dart';
import 'package:pr_list/features/pr_list/pr_form_dialog.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/projects/project_form_dialog.dart';
import 'package:pr_list/features/projects/projects_providers.dart';
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
          if (currentIndex == 0) const _FilterButton(),
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

class _FilterButton extends ConsumerWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(prListFilterProvider);
    final projects = ref.watch(projectsNotifierProvider).items;
    final hasActiveFilter = filter.selectedProjectAliases.isNotEmpty ||
        filter.ticketStatus != TicketStatusFilter.all;

    return IconButton(
      icon: Icon(
        Icons.filter_alt,
        color: hasActiveFilter
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
      tooltip: l10n.filterProject,
      onPressed: () {
        final button = context.findRenderObject() as RenderBox;
        final navigator = Navigator.of(context);
        final overlay =
            navigator.context.findRenderObject() as RenderBox;
        final position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(
              button.size.bottomRight(Offset.zero),
              ancestor: overlay,
            ),
          ),
          Offset.zero & overlay.size,
        );

        showMenu<void>(
          context: context,
          position: position,
          items: [
            _FilterMenuEntry(
              initialFilter: filter,
              projects: projects,
              onProjectToggle: (alias) {
                final current =
                    Set<String>.from(filter.selectedProjectAliases);
                if (current.contains(alias)) {
                  current.remove(alias);
                } else {
                  current.add(alias);
                }
                ref.read(prListFilterProvider.notifier).state =
                    filter.copyWith(selectedProjectAliases: current);
              },
              onTicketStatusChange: (status) {
                ref.read(prListFilterProvider.notifier).state =
                    filter.copyWith(ticketStatus: status);
              },
            ),
          ],
        );
      },
    );
  }
}

class _FilterMenuEntry extends PopupMenuEntry<void> {
  final PrListFilter initialFilter;
  final List<Project> projects;
  final ValueChanged<String> onProjectToggle;
  final ValueChanged<TicketStatusFilter> onTicketStatusChange;

  const _FilterMenuEntry({
    required this.initialFilter,
    required this.projects,
    required this.onProjectToggle,
    required this.onTicketStatusChange,
  });

  @override
  double get height {
    var h = 0.0;
    if (projects.isNotEmpty) {
      h += 28.0;
      h += projects.length * 44.0;
      h += 1.0;
    }
    h += 28.0;
    h += TicketStatusFilter.values.length * 44.0;
    return h;
  }

  @override
  bool represents(void value) => false;

  @override
  _FilterMenuEntryState createState() => _FilterMenuEntryState();
}

class _FilterMenuEntryState extends State<_FilterMenuEntry> {
  late Set<String> _selectedProjects;
  late TicketStatusFilter _ticketStatus;

  @override
  void initState() {
    super.initState();
    _selectedProjects =
        Set<String>.from(widget.initialFilter.selectedProjectAliases);
    _ticketStatus = widget.initialFilter.ticketStatus;
  }

  String _statusLabel(TicketStatusFilter s) {
    final l10n = AppLocalizations.of(context)!;
    switch (s) {
      case TicketStatusFilter.all:
        return l10n.ticketStatusAll;
      case TicketStatusFilter.open:
        return l10n.ticketStatusOpen;
      case TicketStatusFilter.closed:
        return l10n.ticketStatusClosed;
      case TicketStatusFilter.withoutTicket:
        return l10n.ticketStatusWithout;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.projects.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                l10n.filterProject,
                style: textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final project in widget.projects)
              CheckboxListTile(
                value: _selectedProjects.contains(project.alias),
                onChanged: (_) {
                  setState(() {
                    if (_selectedProjects.contains(project.alias)) {
                      _selectedProjects.remove(project.alias);
                    } else {
                      _selectedProjects.add(project.alias);
                    }
                  });
                  widget.onProjectToggle(project.alias);
                },
                title: Text(project.alias),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.filterTicketStatus,
              style: textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final s in TicketStatusFilter.values)
            RadioListTile<TicketStatusFilter>(
              value: s,
              groupValue: _ticketStatus,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _ticketStatus = v);
                widget.onTicketStatusChange(v);
              },
              title: Text(_statusLabel(s)),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
        ],
      ),
    );
  }
}
