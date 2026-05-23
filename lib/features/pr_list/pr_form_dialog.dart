import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/core/services/branch_cache_service.dart';
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
  final _logger = Logger('PrFormDialog');
  final _formKey = GlobalKey<FormState>();
  late AppLocalizations _l10n;
  late TextEditingController _projectController;
  late TextEditingController _branchController;
  late TextEditingController _ticketController;
  late TextEditingController _linkController;
  bool _ticketClosed = false;
  bool _isSaving = false;
  String? _submitError;
  List<String> _branches = [];
  bool _branchesLoading = false;
  bool _projectSelected = false;

  @override
  void initState() {
    super.initState();
    final mode = widget.existing == null ? 'create' : 'edit';
    _logger.info('Dialog opened ($mode) for PR: ${widget.existing?.branch ?? "new"}');
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

    if (widget.existing != null) {
      _projectSelected = true;
      _loadBranches(widget.existing!.projectAlias);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
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

  void _onTicketChanged() {
    if (_ticketController.text.trim().isEmpty && _ticketClosed) {
      setState(() => _ticketClosed = false);
    }
  }

  Future<void> _loadBranches(String projectAlias) async {
    final project = ref
        .read(projectsNotifierProvider)
        .items
        .where((p) => p.alias == projectAlias)
        .firstOrNull;
    if (project == null) return;

    setState(() => _branchesLoading = true);

    final cacheService = getIt<BranchCacheService>();
    final result = await cacheService.getBranches(project.path);

    if (!mounted) return;

    setState(() {
      if (result.isRight) {
        _branches = _deduplicateBranches(result.right);
      }
      _branchesLoading = false;
    });
  }

  String? _validateBranch(String? value) {
    final branch = value?.trim() ?? '';
    if (branch.isEmpty) {
      return _l10n.validationBranchRequired;
    }
    if (branch.contains(RegExp(r'\s'))) {
      return _l10n.validationBranchNoSpaces;
    }
    return null;
  }

  List<String> _deduplicateBranches(List<String> branches) {
    final seen = <String>{};
    final result = <String>[];
    for (final branch in branches) {
      final normalized = branch.startsWith('origin/')
          ? branch.substring(7)
          : branch;
      if (seen.add(normalized)) {
        result.add(normalized);
      }
    }
    return result;
  }

  String? _validatePrLink(String? value) {
    final link = value?.trim() ?? '';
    if (link.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return _l10n.validationInvalidPrUrl;
    }
    return null;
  }

  String? _validateTicket(String? value) {
    final ticket = value?.trim() ?? '';
    if (ticket.isEmpty) return null;
    final uri = Uri.tryParse(ticket);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return _l10n.validationInvalidPrUrl;
    }
    return null;
  }

  String _resolveSubmitError(
    PrOperationException exception,
  ) {
    switch (exception.code) {
      case PrOperationErrorCode.projectNotFound:
        return _l10n.validationProjectNotFound;
      case PrOperationErrorCode.invalidProjectRepository:
        return _l10n.validationProjectRepoInvalid;
      case PrOperationErrorCode.branchNotFound:
        return _l10n.validationBranchNotFound;
      case PrOperationErrorCode.persistenceFailure:
        return _l10n.genericSaveError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsNotifierProvider);
    return AlertDialog(
      title: Text(widget.existing == null ? _l10n.addPr : _l10n.editPr),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(
                        text: _projectController.text,
                      ),
                      optionsBuilder: (TextEditingValue value) {
                        final query = value.text.trim().toLowerCase();
                        final aliases = projectsState.items
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
                        setState(() => _projectSelected = true);
                        _loadBranches(value);
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
                                labelText: _l10n.projectAlias,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? _l10n.projectAlias
                                  : null,
                              onChanged: (value) {
                                _projectController.text = value;
                                if (_projectSelected) {
                                  setState(() => _projectSelected = false);
                                }
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
                    child: Text(_l10n.createAlias),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Autocomplete<String>(
                initialValue: TextEditingValue(
                  text: _branchController.text,
                ),
                optionsBuilder: (TextEditingValue value) {
                  if (_branchesLoading || _branches.isEmpty) {
                    return [];
                  }
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) {
                    return _branches;
                  }
                  return _branches
                      .where((b) => b.toLowerCase().contains(query))
                      .toList();
                },
                onSelected: (value) {
                  _branchController.text = value;
                },
                fieldViewBuilder:
                    (
                      context,
                      textController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                  if (textController.text != _branchController.text) {
                    textController.text = _branchController.text;
                  }
                  return TextFormField(
                    enabled: _projectSelected,
                    controller: textController,
                    focusNode: focusNode,
                    onTap: () {
                      if (_branches.isNotEmpty) {
                        textController.value = TextEditingValue(
                          text: textController.text,
                          selection: TextSelection.collapsed(
                            offset: textController.text.length,
                          ),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      labelText: _l10n.branch,
                      suffixIcon: _branchesLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    validator: (value) => _validateBranch(value),
                    onChanged: (value) {
                      _branchController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: _projectSelected,
                controller: _ticketController,
                decoration: InputDecoration(labelText: _l10n.jiraTicket),
                validator: (value) => _validateTicket(value),
                onChanged: (_) {
                  if (_submitError != null) {
                    setState(() => _submitError = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: _projectSelected,
                controller: _linkController,
                decoration: InputDecoration(labelText: _l10n.prLink),
                validator: (value) => _validatePrLink(value),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _ticketClosed,
                onChanged: _ticketController.text.trim().isEmpty || !_projectSelected
                    ? null
                    : (value) {
                        setState(() => _ticketClosed = value ?? false);
                      },
                title: Text(_l10n.ticketClosed),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_submitError != null) ...[
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
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(_l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) {
                    _logger.info('Form validation failed, not saving');
                    return;
                  }
                  setState(() {
                    _isSaving = true;
                    _submitError = null;
                  });
                  final notifier = ref.read(prListNotifierProvider.notifier);
                  final jiraTicket =
                      _ticketController.text.trim().isEmpty
                      ? null
                      : _ticketController.text.trim();
                  final prLink = _linkController.text.trim().isEmpty
                      ? null
                      : _linkController.text.trim();
                  final isNew = widget.existing == null;
                  _logger.info(
                    'Saving PR: branch=${_branchController.text.trim()}, '
                    'project=${_projectController.text.trim()}, '
                    'link=${_linkController.text.trim()}',
                  );
                  final result = isNew
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
                  if (result.isLeft) {
                    _logger.warning('Save failed: ${result.left.code} (${result.left.details})');
                    setState(() {
                      _isSaving = false;
                      _submitError = _resolveSubmitError(
                        result.left,
                      );
                    });
                    return;
                  }
                  _logger.info('PR saved successfully');
                  Navigator.of(this.context).pop();
                },
          child: Text(_l10n.save),
        ),
      ],
    );
  }
}
