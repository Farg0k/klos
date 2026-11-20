import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';

/// A user-facing mail sharing problem.
class ShareException implements Exception {
  ShareException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Directory where books are prepared before the mail app opens.
///
/// Files are kept for a while because the receiving mail app may read the
/// attachment after its composer is closed.
Future<Directory> shareCacheDirectory() async {
  Directory base;
  try {
    base = await getTemporaryDirectory();
  } catch (_) {
    base = Directory.systemTemp;
  }
  final directory = Directory(p.join(base.path, 'klos_share'));
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return directory;
}

/// Removes prepared books that are older than [maxAge].
Future<void> cleanupOldShares({
  Duration maxAge = const Duration(days: 1),
}) async {
  try {
    final directory = await shareCacheDirectory();
    final now = DateTime.now();
    await for (final entity in directory.list(followLinks: false)) {
      try {
        final stat = await entity.stat();
        if (now.difference(stat.modified) > maxAge) {
          await entity.delete(recursive: true);
        }
      } catch (_) {
        // A file may disappear while the directory is being scanned.
      }
    }
  } catch (_) {
    // Cache cleanup is best-effort and must never block the app.
  }
}

/// Opens the phone's mail app with a prepared book attached.
///
/// Android's `ACTION_SEND` accepts `EXTRA_EMAIL`, so the Kindle address is
/// already filled in. The implementation lives in `MainActivity.kt`; it needs
/// a real Android runtime, which is why it is a platform channel and not a
/// pure-Dart API.
class ShareService {
  const ShareService();

  static const MethodChannel _channel = MethodChannel('klos/share');

  Future<void> shareFile({
    required File file,
    required String title,
    required String mime,
    required String to,
  }) async {
    final safeTitle = title.trim().isEmpty
        ? p.basename(file.path)
        : title.trim();
    try {
      await _channel.invokeMethod<void>('sendEmail', {
        'path': file.path,
        'mime': mime,
        'to': to.trim(),
        'subject': safeTitle,
        'text': l10n.shareBody(safeTitle),
        'chooser': l10n.shareChooserTitle,
      });
    } on PlatformException catch (error) {
      final message = switch (error.code) {
        'bad_args' => l10n.shareMissingArgs,
        'missing_file' => l10n.shareMissingFile,
        'send_failed' => l10n.shareOpenFailed,
        _ => error.message?.trim(),
      };
      throw ShareException(
        message == null || message.isEmpty ? l10n.shareOpenFailed : message,
      );
    } on MissingPluginException {
      throw ShareException(l10n.shareAndroidOnly);
    }
  }
}
