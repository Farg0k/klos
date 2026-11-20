import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../components/info_box.dart';
import '../../generated/l10n.dart';
import '../settings_screen/bloc/settings_bloc.dart';
import 'components/settings_sheet.dart';
import 'components/sheet_result.dart';

/// Opens the local folder sheet.
Future<void> showFolderSheet(BuildContext context) =>
    showSettingsSheet(context, builder: (_) => const FolderSheet());

/// Connects and disconnects the phone folder the Kindle can read.
class FolderSheet extends StatefulWidget {
  const FolderSheet({super.key});

  @override
  State<FolderSheet> createState() => _FolderSheetState();
}

class _FolderSheetState extends SettingsSheetState<FolderSheet> {
  late String _uri;
  late String _name;
  bool _picking = false;
  String? _error;

  @override
  void initFields() {
    _uri = draft.localFolderUri;
    _name = draft.localFolderName;
  }

  @override
  void syncDraft() {
    draft = draft.withLocalFolder(uri: _uri, name: _name);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final error = _error;

    return SettingsSheet(
      icon: Icons.folder_outlined,
      title: s.localFiles,
      onDismiss: save,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _uri.isEmpty ? Icons.folder_off_outlined : Icons.folder_open,
                color: _uri.isEmpty ? scheme.onSurfaceVariant : scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uri.isEmpty
                          ? s.localFolderDefaultName
                          : (_name.trim().isEmpty
                                ? s.localFolderDefaultName
                                : _name),
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _uri.isEmpty
                          ? s.localFolderNotConnectedShort
                          : s.localFolderConnectedShort,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.localFolderHint,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _picking ? null : _pick,
              icon: _picking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open),
              label: Text(s.chooseFolder),
            ),
            if (_uri.isNotEmpty)
              TextButton.icon(
                onPressed: _picking ? null : _reset,
                icon: const Icon(Icons.restart_alt),
                label: Text(s.resetFolder),
              ),
          ],
        ),
        if (_uri.isEmpty) ...[
          const SizedBox(height: 12),
          InfoBox(icon: Icons.info_outline, text: s.localFolderDefaultNote),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          SheetResult(message: error, ok: false),
        ],
      ],
    );
  }

  Future<void> _pick() async {
    final bloc = context.read<SettingsBloc>();
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final folder = await bloc.pickLocalFolder();
      if (folder == null) return;
      setState(() {
        _uri = folder.uri;
        _name = folder.name;
      });
      save();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _reset() {
    setState(() {
      _uri = '';
      _name = '';
      _error = null;
    });
    save();
  }
}
