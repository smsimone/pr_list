import 'package:flutter/material.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:pr_list/core/services/secure_storage_service.dart';

class PatSettingsDialog extends StatefulWidget {
  const PatSettingsDialog({super.key});

  @override
  State<PatSettingsDialog> createState() => _PatSettingsDialogState();
}

class _PatSettingsDialogState extends State<PatSettingsDialog> {
  final _patController = TextEditingController();
  late AppLocalizations _l10n;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_l10n.azurePatTitle),
      content: TextField(
        controller: _patController,
        decoration: InputDecoration(labelText: _l10n.azurePatLabel),
        obscureText: true,
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(_l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving
              ? null
              : () async {
                  final value = _patController.text.trim();
                  if (value.isEmpty) {
                    return;
                  }
                  setState(() => _isSaving = true);
                  final storage = GetIt.instance<SecureStorageService>();
                  await storage.setAzurePat(value);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          child: Text(_l10n.save),
        ),
      ],
    );
  }
}
