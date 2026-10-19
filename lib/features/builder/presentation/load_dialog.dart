import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/config.dart';
import '../domain/draft.dart';
import '../domain/validators.dart';
import 'branding_section.dart';

/// "Load existing config": open by appId (latest version) or import JSON.
Future<void> showLoadDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _LoadDialog(),
  );
}

class _LoadDialog extends ConsumerStatefulWidget {
  const _LoadDialog();

  @override
  ConsumerState<_LoadDialog> createState() => _LoadDialogState();
}

class _LoadDialogState extends ConsumerState<_LoadDialog> {
  final _controller = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done(AppConfigDraft draft, {String? note}) {
    ref.read(draftProvider.notifier).replace(draft);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (note != null) messenger.showSnackBar(SnackBar(content: Text(note)));
    router.go('/builder/${WizardSection.info.name}');
  }

  Future<void> _byAppId() async {
    final l10n = AppLocalizations.of(context);
    final id = _controller.text.trim();
    final latest = await ref.read(configRepositoryProvider).getLatest(id);
    if (!mounted) return;
    if (latest == null) {
      setState(() => _message = l10n.appNotFound);
      return;
    }
    final draft = await ref.read(configServiceProvider).draftFromStored(latest);
    if (!mounted) return;
    _done(draft);
  }

  Future<void> _importFile() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ref.read(filePickProvider)(const ['json']);
    if (picked == null) return;
    try {
      final config = AppConfig.fromJsonString(utf8.decode(picked.bytes));
      final errors = ref
          .read(schemaValidatorProvider)
          .validate(config.toJson());
      if (errors.isNotEmpty) throw FormatException(errors.first);
      if (!mounted) return;
      _done(AppConfigDraft.fromConfig(config), note: l10n.loadedFromJsonNote);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = l10n.importFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.loadDialogTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l10n.fieldAppId,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _byAppId(),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _byAppId, child: Text(l10n.loadByAppId)),
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: _importFile,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.importJsonFile),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
