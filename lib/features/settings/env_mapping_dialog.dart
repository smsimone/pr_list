import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/features/settings/env_mapping_providers.dart';

class EnvMappingDialog extends ConsumerStatefulWidget {
  const EnvMappingDialog({super.key});

  @override
  ConsumerState<EnvMappingDialog> createState() => _EnvMappingDialogState();
}

class _EnvMappingDialogState extends ConsumerState<EnvMappingDialog> {
  late AppLocalizations _l10n;
  final _controllers = <_RowControllers>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    final mappingsAsync = ref.watch(envMappingsProvider);

    return AlertDialog(
      title: Text(_l10n.envMappingsTitle),
      content: SizedBox(
        width: 480,
        child: mappingsAsync.when(
          data: (mappings) {
            if (_controllers.isEmpty) {
              _initControllers(mappings);
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final c = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text('${index + 1}.',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: c.name,
                              decoration: InputDecoration(
                                labelText: _l10n.envMappingNameLabel,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: c.pattern,
                              decoration: InputDecoration(
                                labelText: _l10n.envMappingPatternLabel,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _controllers.length > 1
                                ? () {
                                    setState(() {
                                      c.name.dispose();
                                      c.pattern.dispose();
                                      _controllers.removeAt(index);
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _controllers.add(_RowControllers(
                          name: TextEditingController(),
                          pattern: TextEditingController(),
                        ));
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(_l10n.genericError),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_l10n.save),
        ),
      ],
    );
  }

  void _initControllers(List<EnvironmentMapping> mappings) {
    if (mappings.isEmpty) {
      _controllers.add(_RowControllers(
        name: TextEditingController(),
        pattern: TextEditingController(),
      ));
      return;
    }
    for (final m in mappings) {
      _controllers.add(_RowControllers(
        name: TextEditingController(text: m.environmentName),
        pattern: TextEditingController(text: m.branchPattern),
      ));
    }
  }

  Future<void> _save() async {
    final items = _controllers.map((c) {
      final name = c.name.text.trim();
      final pattern = c.pattern.text.trim();
      return EnvironmentMappingsCompanion.insert(
        sortOrder: _controllers.indexOf(c),
        environmentName: name.isEmpty ? _l10n.envMappingDefault : name,
        branchPattern: pattern.isEmpty ? _l10n.envMappingDefault : pattern,
      );
    }).toList();

    final result = await ref
        .read(envMappingRepositoryProvider)
        .saveAll(items);
    if (!mounted) return;
    if (result.isLeft) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.genericSaveError)),
      );
      return;
    }
    ref.invalidate(envMappingsProvider);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.name.dispose();
      c.pattern.dispose();
    }
    super.dispose();
  }
}

class _RowControllers {
  final TextEditingController name;
  final TextEditingController pattern;

  _RowControllers({required this.name, required this.pattern});
}
