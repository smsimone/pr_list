import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/pr_list/pr_list_notifier.dart';
import 'package:pr_list/features/projects/project_form_dialog.dart';
import 'package:pr_list/features/projects/projects_providers.dart';

class PrFormDialog extends ConsumerStatefulWidget {
  final PullRequest? existing;

  const PrFormDialog({super.key, this.existing});

  @override
  ConsumerState<PrFormDialog> createState() => _PrFormDialogState();
}

class _PrFormDialogState extends ConsumerState<PrFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _projectController;
  late TextEditingController _branchController;
  late TextEditingController _ticketController;
  late TextEditingController _linkController;
  bool _ticketClosed = false;
  bool _isSaving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _projectController = TextEditingController(
      text: widget.existing?.projectAlias ?? '',
    );
    _branchController = TextEditingController(
      text: widget.existing?.branch ?? '',
    );
    _ticketController = TextEditingController(
      text: widget.existing?.jiraTicket ?? '',
    );
    _linkController = TextEditingController(
      text: widget.existing?.prLink ?? '',
    );
    _ticketClosed = widget.existing?.isTicketClosed ?? false;
    _ticketController.addListener(_onTicketChanged);
  }

  @override
  void dispose() {
    _ticketController.removeListener(_onTicketChanged);
    _projectController.dispose();
    _branchController.dispose();
    _ticketController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _onBranchChanged(String value) {
    if (value.startsWith('fix/NFSN-') &&
        _ticketController.text.trim().isEmpty) {
      _ticketController.text = 'NFSN-****';
    }
  }

  void _onTicketChanged() {
    if (_ticketController.text.trim().isEmpty && _ticketClosed) {
      setState(() => _ticketClosed = false);
    }
  }

  String? _validateBranch(String? value, AppLocalizations l10n) {
    final String branch = value?.trim() ?? '';
    if (branch.isEmpty) {
      return l10n.validationBranchRequired;
    }
    if (branch.contains(RegExp(r'\s'))) {
      return l10n.validationBranchNoSpaces;
    }
    return null;
  }

  String? _validatePrLink(String? value, AppLocalizations l10n) {
    final String link = value?.trim() ?? '';
    if (link.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return l10n.validationInvalidPrUrl;
    }
    return null;
  }

  String _resolveSubmitError(
    AppLocalizations l10n,
    PrOperationException exception,
  ) {
    switch (exception.code) {
      case PrOperationErrorCode.projectNotFound:
        return l10n.validationProjectNotFound;
      case PrOperationErrorCode.invalidProjectRepository:
        return l10n.validationProjectRepoInvalid;
      case PrOperationErrorCode.branchNotFound:
        return l10n.validationBranchNotFound;
      case PrOperationErrorCode.persistenceFailure:
        return l10n.genericSaveError;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(true);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final projectsState = ref.watch(projectsNotifierProvider);
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.addPr : l10n.editPr),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(
                        text: _projectController.text,
                      ),
                      optionsBuilder: (TextEditingValue value) {
                        final String query = value.text.trim().toLowerCase();
                        final List<String> aliases = projectsState.items
                            .map((p) => p.alias)
                            .toList();
                        if (query.isEmpty) {
                          return aliases;
                        }
                        return aliases
                            .where(
                              (alias) => alias.toLowerCase().contains(query),
                            )
                            .toList();
                      },
                      onSelected: (value) {
                        _projectController.text = value;
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            if (textController.text !=
                                _projectController.text) {
                              textController.text = _projectController.text;
                            }
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: l10n.projectAlias,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? l10n.projectAlias
                                  : null,
                              onChanged: (value) {
                                _projectController.text = value;
                              },
                            );
                          },
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => ProjectFormDialog(
                        initialAlias: _projectController.text.trim().isEmpty
                            ? null
                            : _projectController.text.trim(),
                      ),
                    ),
                    child: Text(l10n.createAlias),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _branchController,
                decoration: InputDecoration(labelText: l10n.branch),
                onChanged: _onBranchChanged,
                validator: (value) => _validateBranch(value, l10n),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ticketController,
                decoration: InputDecoration(labelText: l10n.jiraTicket),
                onChanged: (_) {
                  if (_submitError != null) {
                    setState(() => _submitError = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(labelText: l10n.prLink),
                validator: (value) => _validatePrLink(value, l10n),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _ticketClosed,
                onChanged: _ticketController.text.trim().isEmpty
                    ? null
                    : (value) {
                        setState(() => _ticketClosed = value ?? false);
                      },
                title: Text(l10n.ticketClosed),
                controlAffinity: ListTileControlAffinity.leading,
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
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  setState(() {
                    _isSaving = true;
                    _submitError = null;
                  });
                  final notifier = ref.read(prListNotifierProvider.notifier);
                  final String? jiraTicket =
                      _ticketController.text.trim().isEmpty
                      ? null
                      : _ticketController.text.trim();
                  final String? prLink = _linkController.text.trim().isEmpty
                      ? null
                      : _linkController.text.trim();
                  final result = widget.existing == null
                      ? await notifier.addPr(
                          projectAlias: _projectController.text.trim(),
                          branch: _branchController.text.trim(),
                          jiraTicket: jiraTicket,
                          prLink: prLink,
                        )
                      : await notifier.updatePr(
                          id: widget.existing!.id,
                          projectAlias: _projectController.text.trim(),
                          branch: _branchController.text.trim(),
                          jiraTicket: jiraTicket,
                          prLink: prLink,
                          isTicketClosed: _ticketClosed,
                        );
                  if (!mounted) {
                    return;
                  }
                  final AppLocalizations currentL10n = AppLocalizations.of(
                    this.context,
                  )!;
                  if (result.isLeft) {
                    setState(() {
                      _isSaving = false;
                      _submitError = _resolveSubmitError(
                        currentL10n,
                        result.left,
                      );
                    });
                    return;
                  }
                  Navigator.of(this.context).pop();
                },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
