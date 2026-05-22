import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:pr_list/core/services/secure_storage_service.dart';

class PatSettingsDialog extends StatefulWidget {
  const PatSettingsDialog({super.key});

  @override
  State<PatSettingsDialog> createState() => _PatSettingsDialogState();
}

class _PatSettingsDialogState extends State<PatSettingsDialog> {
  final TextEditingController _patController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(true);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.azurePatTitle),
      content: TextField(
        controller: _patController,
        decoration: InputDecoration(labelText: l10n.azurePatLabel),
        obscureText: true,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving
              ? null
              : () async {
                  final String value = _patController.text.trim();
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
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
