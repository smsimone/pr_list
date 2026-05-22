import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
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
  }

  @override
  void dispose() {
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
                validator: (value) =>
                    value == null || value.trim().isEmpty ? l10n.branch : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ticketController,
                decoration: InputDecoration(labelText: l10n.jiraTicket),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(labelText: l10n.prLink),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _ticketClosed,
                onChanged: (value) {
                  setState(() => _ticketClosed = value ?? false);
                },
                title: Text(l10n.ticketClosed),
                controlAffinity: ListTileControlAffinity.leading,
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
            final notifier = ref.read(prListNotifierProvider.notifier);
            if (widget.existing == null) {
              await notifier.addPr(
                projectAlias: _projectController.text.trim(),
                branch: _branchController.text.trim(),
                jiraTicket: _ticketController.text.trim().isEmpty
                    ? null
                    : _ticketController.text.trim(),
                prLink: _linkController.text.trim().isEmpty
                    ? null
                    : _linkController.text.trim(),
              );
            } else {
              await notifier.updatePr(
                id: widget.existing!.id,
                projectAlias: _projectController.text.trim(),
                branch: _branchController.text.trim(),
                jiraTicket: _ticketController.text.trim().isEmpty
                    ? null
                    : _ticketController.text.trim(),
                prLink: _linkController.text.trim().isEmpty
                    ? null
                    : _linkController.text.trim(),
                isTicketClosed: _ticketClosed,
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
