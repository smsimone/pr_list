import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/features/projects/projects_providers.dart';

class ProjectFormDialog extends ConsumerStatefulWidget {
  final Project? existing;
  final String? initialAlias;

  const ProjectFormDialog({super.key, this.existing, this.initialAlias});

  @override
  ConsumerState<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends ConsumerState<ProjectFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _aliasController;
  late TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(
      text: widget.existing?.alias ?? widget.initialAlias ?? '',
    );
    _pathController = TextEditingController(text: widget.existing?.path ?? '');
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    final String? directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) {
      return;
    }
    _pathController.text = directory;
  }

  @override
  Widget build(BuildContext context) {
    assert(true);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.addProject : l10n.editProject),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _aliasController,
                decoration: InputDecoration(labelText: l10n.projectAlias),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.projectAlias
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _pathController,
                      decoration: InputDecoration(labelText: l10n.projectPath),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.projectPath
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _pickFolder,
                    child: Text(l10n.pickFolder),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            final notifier = ref.read(projectsNotifierProvider.notifier);
            if (widget.existing == null) {
              await notifier.addProject(
                alias: _aliasController.text.trim(),
                path: _pathController.text.trim(),
              );
            } else {
              await notifier.updateProject(
                id: widget.existing!.id,
                alias: _aliasController.text.trim(),
                path: _pathController.text.trim(),
              );
            }
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
