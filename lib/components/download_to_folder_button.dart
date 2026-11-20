import 'package:flutter/material.dart';

import '../entity/app_settings.dart';
import '../generated/l10n.dart';
import '../local/folder_download.dart';
import '../local/local_files.dart';
import '../opds/opds_client.dart';
import '../opds/opds_feed.dart';

/// Saves a catalog book into the folder the Kindle can read.
///
/// The book goes through the same unpacking and conversion as a server
/// download, so an EPUB or a ZIP becomes a file the Kindle opens.
class DownloadToFolderButton extends StatefulWidget {
  const DownloadToFolderButton({
    super.key,
    required this.entry,
    required this.settings,
    this.onFinished,
    this.showNote = true,
  });

  final OpdsEntry entry;
  final AppSettings settings;

  /// Called after an attempt, while the button is still mounted.
  ///
  /// The details sheets use it to close themselves before the message appears,
  /// so the SnackBar is not hidden behind the sheet.
  final VoidCallback? onFinished;

  /// Whether to show the short explanation of what happens to the file.
  final bool showNote;

  @override
  State<DownloadToFolderButton> createState() => _DownloadToFolderButtonState();
}

class _DownloadToFolderButtonState extends State<DownloadToFolderButton> {
  bool _busy = false;

  Future<void> _download() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!widget.settings.hasLocalFolder) {
      widget.onFinished?.call();
      messenger.showSnackBar(SnackBar(content: Text(s.downloadFolderMissing)));
      return;
    }

    setState(() => _busy = true);
    late final String message;
    try {
      final saved = await FolderDownloader(settings: widget.settings)
          .download(widget.entry);
      message = s.savedToFolder(saved.name);
    } on LocalStorageException catch (error) {
      // The message already explains the folder problem.
      message = error.message;
    } on OpdsException catch (error) {
      message = s.saveToFolderFailed(error.message);
    } catch (error) {
      message = s.saveToFolderFailed('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (mounted) widget.onFinished?.call();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : _download,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(_busy ? s.downloadInProgress : s.downloadToFolder),
        ),
        if (widget.showNote) ...[
          const SizedBox(height: 8),
          Text(
            s.downloadToFolderNote,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
