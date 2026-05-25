import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/pr_list/pr_list_notifier.dart';
import 'package:pr_list/features/projects/project_form_dialog.dart';
import 'package:pr_list/features/projects/projects_providers.dart';
import 'package:pr_list/shared/utils/ticket_utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late TextEditingController _ticketController;
  late TextEditingController _linkController;
  bool _ticketClosed = false;
  bool _isSaving = false;
  bool _isVerifying = false;
  String? _submitError;
  bool _projectSelected = false;

  @override
  void initState() {
    super.initState();
    final mode = widget.existing == null ? 'create' : 'edit';
    _logger.info('Dialog opened ($mode)');
    _projectController = TextEditingController(
      text: widget.existing?.projectAlias ?? '',
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
    _ticketController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _onTicketChanged() {
    if (_ticketController.text.trim().isEmpty && _ticketClosed) {
      setState(() => _ticketClosed = false);
    }
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

  String _resolveSubmitError(PrOperationException exception) {
    switch (exception.code) {
      case PrOperationErrorCode.projectNotFound:
        return _l10n.validationProjectNotFound;
      case PrOperationErrorCode.persistenceFailure:
        return _l10n.genericSaveError;
    }
  }

  Widget? _buildUrlSuffix(String? text) {
    if (!isValidUrl(text)) return null;
    return IconButton(
      icon: const Icon(Icons.open_in_new, size: 18),
      onPressed: () => launchUrl(Uri.parse(text!.trim())),
    );
  }

  Future<void> _verifyEnvironments() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifica ambienti'),
        content: const Text(
          'La verifica potrebbe richiedere del tempo.\n'
          'Continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Procedi'),
          ),
        ],
      ),
    );
    if (shouldProceed != true || !mounted) return;

    setState(() => _isVerifying = true);
    final syncService = ref.read(prSyncServiceProvider);
    final result = await syncService.verifyEnvironmentsForPr(
      widget.existing!.id,
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isRight
              ? 'Verifica ambienti completata'
              : 'Errore: ${result.left.message}',
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.deletePrTitle),
        content: Text(_l10n.deletePrMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_l10n.delete),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) {
      return;
    }
    final result = await ref
        .read(prListNotifierProvider.notifier)
        .deletePr(widget.existing!.id);
    if (!mounted) {
      return;
    }
    if (result.isLeft) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.genericDeleteError)),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsNotifierProvider);
    final commitSha = widget.existing?.lastCommitSha;
    return AlertDialog(
      title: Text(widget.existing == null
          ? _l10n.addPr
          : (widget.existing!.providerPrId != null
              ? _l10n.editPrNum(widget.existing!.id.toString())
              : _l10n.editPr)),
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
              TextFormField(
                enabled: _projectSelected,
                controller: _ticketController,
                decoration: InputDecoration(
                  labelText: _l10n.jiraTicket,
                  suffixIcon: _buildUrlSuffix(_ticketController.text),
                ),
                validator: (value) => _validateTicket(value),
                onChanged: (_) => setState(() {
                  if (_submitError != null) _submitError = null;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: _projectSelected,
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: _l10n.prLink,
                  suffixIcon: _buildUrlSuffix(_linkController.text),
                ),
                validator: (value) => _validatePrLink(value),
                onChanged: (_) => setState(() {}),
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
              if (widget.existing?.ticketStatus != null &&
                  widget.existing!.ticketStatus!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(
                    text: '${_l10n.ticketSyncStatus}: ${widget.existing!.ticketStatus}',
                  ),
                  readOnly: true,
                  decoration: const InputDecoration(isDense: true),
                ),
              ],
              if (commitSha != null && commitSha.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: commitSha),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: _l10n.lastCommit,
                    isDense: true,
                  ),
                ),
              ],
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
      actionsAlignment: widget.existing != null
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: (_isSaving || _isVerifying) ? null : _confirmDelete,
            child: Text(_l10n.delete),
          ),
        if (widget.existing != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : OutlinedButton(
                    onPressed: (_isSaving || _isVerifying) ? null : _verifyEnvironments,
                    child: const Text('Verifica ambienti'),
                  ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: (_isSaving || _isVerifying)
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(_l10n.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: (_isSaving || _isVerifying)
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
                        'Saving PR: project=${_projectController.text.trim()}, '
                        'link=${_linkController.text.trim()}',
                      );
                      final result = isNew
                          ? await notifier.addPr(
                              projectAlias: _projectController.text.trim(),
                              jiraTicket: jiraTicket,
                              prLink: prLink,
                            )
                          : await notifier.updatePr(
                              id: widget.existing!.id,
                              projectAlias: _projectController.text.trim(),
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
                          _submitError = _resolveSubmitError(result.left);
                        });
                        return;
                      }
                      _logger.info('PR saved successfully');
                      Navigator.of(this.context).pop();
                    },
              child: Text(_l10n.save),
            ),
          ],
        ),
      ],
    );
  }
}
