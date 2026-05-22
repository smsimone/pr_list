import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/utils/failure.dart';
import 'package:pr_list/features/projects/projects_providers.dart';
import 'package:path/path.dart' as p;

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
  bool _isSaving = false;
  String? _submitError;
  final Logger _logger = Logger('ProjectFormDialog');

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
    _logger.info('Opening folder picker');
    try {
      final String? directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) {
        _logger.info('Folder picker cancelled by user');
        return;
      }
      _logger.info('Folder selected: $directory');
      _pathController.text = directory;
    } catch (err) {
      _logger.severe('Folder picker failed: $err');
    }
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
                    ? l10n.validationProjectAliasRequired
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _pathController,
                      decoration: InputDecoration(labelText: l10n.projectPath),
                      validator: (value) => _validatePath(value, l10n),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _pickFolder,
                    child: Text(l10n.pickFolder),
                  ),
                ],
              ),
              if (_submitError != null) ...<Widget>[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : () => _saveProject(l10n),
          child: Text(l10n.save),
        ),
      ],
    );
  }

  String? _validatePath(String? value, AppLocalizations l10n) {
    final String path = value?.trim() ?? '';
    if (path.isEmpty) {
      return l10n.validationProjectPathRequired;
    }
    if (!p.isAbsolute(path)) {
      return l10n.validationProjectPathMustBeAbsolute;
    }
    final Directory dir = Directory(path);
    if (!dir.existsSync()) {
      return l10n.validationProjectPathNotFound;
    }
    return null;
  }

  Future<void> _saveProject(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
      _submitError = null;
    });
    final String path = _pathController.text.trim();
    _logger.info('Saving project at path: $path');

    final GitClient gitClient = getIt<GitClient>();
    final hasRemoteResult = await gitClient.hasRemote(
      workingDirectory: path,
    );
    if (!mounted) {
      return;
    }
    if (hasRemoteResult.isLeft) {
      final Failure failure = hasRemoteResult.left;
      _logger.warning('Git validation failed: ${failure.message}');
      _logger.warning('Git error cause: ${failure.cause}');
      final String detail = failure.cause != null
          ? '\n${failure.cause}'
          : '';
      setState(() {
        _isSaving = false;
        _submitError = '${l10n.validationProjectRepoInvalid}$detail';
      });
      return;
    }
    if (!hasRemoteResult.right) {
      _logger.info('Git repository has no remotes configured');
      setState(() {
        _isSaving = false;
        _submitError = l10n.validationProjectMissingRemote;
      });
      return;
    }

    final notifier = ref.read(projectsNotifierProvider.notifier);
    final result = widget.existing == null
        ? await notifier.addProject(
            alias: _aliasController.text.trim(),
            path: _pathController.text.trim(),
          )
        : await notifier.updateProject(
            id: widget.existing!.id,
            alias: _aliasController.text.trim(),
            path: _pathController.text.trim(),
          );
    if (!mounted) {
      return;
    }
    if (result.isLeft) {
      setState(() {
        _isSaving = false;
        _submitError = l10n.genericSaveError;
      });
      return;
    }
    Navigator.of(context).pop();
  }
}
