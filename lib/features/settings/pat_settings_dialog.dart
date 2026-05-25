import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:pr_list/core/services/secure_storage_service.dart';

class _CredentialRow {
  final String serviceName;
  final TextEditingController tokenController;

  _CredentialRow({
    required this.serviceName,
    required this.tokenController,
  });
}

class PatSettingsDialog extends StatefulWidget {
  const PatSettingsDialog({super.key});

  @override
  State<PatSettingsDialog> createState() => _PatSettingsDialogState();
}

class _PatSettingsDialogState extends State<PatSettingsDialog> {
  final _logger = Logger('PatSettingsDialog');
  late AppLocalizations _l10n;
  final _rows = <_CredentialRow>[];
  final _jiraUrlController = TextEditingController();
  final _jiraEmailController = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    if (!_initialized) {
      _init();
      _initialized = true;
    }
  }

  Future<void> _init() async {
    final storage = GetIt.instance<SecureStorageService>();

    _rows.add(_CredentialRow(
      serviceName: 'Azure DevOps',
      tokenController: TextEditingController(),
    ));
    _rows.add(_CredentialRow(
      serviceName: 'Jira',
      tokenController: TextEditingController(),
    ));

    final azurePat = await storage.getAzurePat();
    if (azurePat.isRight && azurePat.right != null) {
      _rows[0].tokenController.text = azurePat.right!;
    }

    final jiraPat = await storage.getJiraPat();
    if (jiraPat.isRight && jiraPat.right != null) {
      _rows[1].tokenController.text = jiraPat.right!;
    }

    final jiraUrl = await storage.getJiraInstanceUrl();
    if (jiraUrl.isRight && jiraUrl.right != null) {
      _jiraUrlController.text = jiraUrl.right!;
    }

    final jiraEmail = await storage.getJiraEmail();
    if (jiraEmail.isRight && jiraEmail.right != null) {
      _jiraEmailController.text = jiraEmail.right!;
    }

    setState(() {});
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.tokenController.dispose();
    }
    _jiraUrlController.dispose();
    _jiraEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_l10n.credentialsTitle),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _l10n.serviceName,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _l10n.token,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
                for (final row in _rows)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(row.serviceName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextField(
                          controller: row.tokenController,
                          decoration: const InputDecoration(
                            isDense: true,
                          ),
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jiraEmailController,
              decoration: InputDecoration(
                labelText: 'Jira email',
                hintText: 'user@example.com',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _jiraUrlController,
              decoration: InputDecoration(
                labelText: _l10n.jiraInstanceUrlLabel,
                hintText: 'https://mycompany.atlassian.net',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(_l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_l10n.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    _logger.info('Saving credentials...');
    setState(() => _isSaving = true);
    final storage = GetIt.instance<SecureStorageService>();

    final azureValue = _rows[0].tokenController.text.trim();
    if (azureValue.isNotEmpty) {
      await storage.setAzurePat(azureValue);
    }

    final jiraValue = _rows[1].tokenController.text.trim();
    if (jiraValue.isNotEmpty) {
      await storage.setJiraPat(jiraValue);
    }

    final jiraUrlValue = _jiraUrlController.text.trim();
    if (jiraUrlValue.isNotEmpty) {
      await storage.setJiraInstanceUrl(jiraUrlValue);
    }

    final jiraEmailValue = _jiraEmailController.text.trim();
    if (jiraEmailValue.isNotEmpty) {
      await storage.setJiraEmail(jiraEmailValue);
    }

    _logger.info('Credentials saved, closing dialog');
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }
}
