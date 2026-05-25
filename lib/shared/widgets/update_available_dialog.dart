import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/core/services/models/update_info.dart';
import 'package:pr_list/core/services/update_notifier.dart';

class UpdateAvailableDialog extends ConsumerWidget {
  const UpdateAvailableDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateStateProvider);

    return switch (state.status) {
      UpdateStateStatus.available => _availableContent(context, ref, state.info!),
      UpdateStateStatus.downloading => _progressContent(context, state.progress),
      UpdateStateStatus.installing => _installingContent(context),
      UpdateStateStatus.error => _errorContent(context, ref, state.errorMessage),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _availableContent(BuildContext context, WidgetRef ref, UpdateInfo info) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.updateAvailableTitle),
      content: Text(l10n.updateAvailableBody(info.version)),
      actions: [
        TextButton(
          onPressed: () => ref.read(updateStateProvider.notifier).dismiss(),
          child: Text(l10n.actionSkip),
        ),
        FilledButton(
          onPressed: () => ref.read(updateStateProvider.notifier).downloadAndInstall(),
          child: Text(l10n.actionDownload),
        ),
      ],
    );
  }

  Widget _progressContent(BuildContext context, double progress) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.updateDownloading),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: progress > 0 ? progress : null),
          const SizedBox(height: 8),
          Text('${(progress * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _installingContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.updateInstalling),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Please wait...'),
        ],
      ),
    );
  }

  Widget _errorContent(BuildContext context, WidgetRef ref, String? error) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.updateError),
      content: Text(error ?? l10n.updateErrorUnknown),
      actions: [
        FilledButton(
          onPressed: () => ref.read(updateStateProvider.notifier).dismiss(),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}
