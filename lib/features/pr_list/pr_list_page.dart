import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/features/pr_list/pr_form_dialog.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/settings/pat_settings_dialog.dart';
import 'package:pr_list/shared/widgets/empty_state.dart';
import 'package:pr_list/shared/widgets/responsive_container.dart';

class PrListPage extends ConsumerWidget {
  const PrListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(true);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final state = ref.watch(prListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabPrList),
        actions: <Widget>[
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const PatSettingsDialog(),
            ),
            icon: const Icon(Icons.vpn_key),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const PrFormDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return EmptyState(message: l10n.emptyState);
          }

          return ResponsiveContainer(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final PullRequest pr = state.items[index];
                return Card(
                  child: ListTile(
                    title: Text('${pr.projectAlias} • ${pr.branch}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (pr.jiraTicket != null)
                          Text('${l10n.jiraTicket}: ${pr.jiraTicket}'),
                        if (pr.prLink != null)
                          Text('${l10n.prLink}: ${pr.prLink}'),
                        if (pr.providerStatus != null)
                          Text('${l10n.providerStatus}: ${pr.providerStatus}'),
                        if (pr.lastCommitSha != null)
                          Text('${l10n.lastCommit}: ${pr.lastCommitSha}'),
                      ],
                    ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => PrFormDialog(existing: pr),
                    ),
                  ),
                ),
              );
            },
          ),
        );
        },
      ),
    );
  }
}
