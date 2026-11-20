import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';

import '../entity/app_settings.dart';
import '../books/ebook_archive.dart';
import '../l10n/l10n.dart';
import '../opds/opds_client.dart';
import '../server/file_names.dart';

/// A user-facing email delivery problem.
class KindleMailException implements Exception {
  KindleMailException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Downloads a book into a temporary file and emails it to Kindle.
///
/// Books are never kept: the temporary attachment is deleted right after the
/// SMTP server accepts the message.
class KindleMailer {
  /// Amazon rejects messages larger than 25 MB.
  static const int maxAttachmentBytes = 25 * 1024 * 1024;

  static const Duration _sendTimeout = Duration(seconds: 180);

  Future<void> sendBook({
    required AppSettings settings,
    required Uri url,
    String? title,
    String? mime,
    void Function()? onSending,
  }) async {
    if (!settings.emailConfigured) {
      throw KindleMailException(l10n.mailNotConfigured);
    }

    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );
    File? temp;
    try {
      final remote = await client.openDownload(url);
      final remoteMime = remote.response.headers.contentType?.mimeType;
      if (remoteMime == 'text/html' &&
          (mime == null || !mime.contains('html'))) {
        await remote.response.drain<void>();
        throw KindleMailException(l10n.opdsHtmlInsteadOfFile);
      }

      var effectiveMime = _effectiveMime(remoteMime, mime);
      final declaredLength = remote.response.contentLength;
      if (declaredLength > maxAttachmentBytes) {
        await remote.response.drain<void>();
        throw KindleMailException(_tooLargeMessage);
      }

      final contentEncoding = remote.response.headers.value(
        HttpHeaders.contentEncodingHeader,
      );
      final encoded = contentEncoding != null && contentEncoding.isNotEmpty;

      final dir = await _tempDirectory();
      final target = File(
        '${dir.path}${Platform.pathSeparator}'
        'klos_${DateTime.now().microsecondsSinceEpoch}.part',
      );
      temp = target;

      final iterator = StreamIterator<List<int>>(remote.response);
      try {
        // Peek at the first bytes: a ZIP may hide the EPUB/FB2 that the link
        // promises, and Amazon accepts only a real book file.
        final head = BytesBuilder(copy: false);
        while (head.length < 4 && await iterator.moveNext()) {
          head.add(iterator.current);
        }
        final headBytes = head.takeBytes();

        if (!encoded && looksLikeZip(headBytes)) {
          final builder = BytesBuilder(copy: false)..add(headBytes);
          while (await iterator.moveNext()) {
            builder.add(iterator.current);
            if (builder.length > maxArchiveBookBytes) {
              throw KindleMailException(_tooLargeMessage);
            }
          }
          final resolved = resolveBook(
            builder.takeBytes(),
            purpose: BookPurpose.email,
            maxBytes: maxAttachmentBytes,
          );
          effectiveMime = resolved.mime ?? effectiveMime;
          await target.writeAsBytes(resolved.bytes, flush: true);
        } else {
          var written = 0;
          final sink = target.openWrite();
          try {
            if (headBytes.isNotEmpty) {
              written += headBytes.length;
              sink.add(headBytes);
            }
            while (await iterator.moveNext()) {
              written += iterator.current.length;
              if (written > maxAttachmentBytes) {
                throw KindleMailException(_tooLargeMessage);
              }
              sink.add(iterator.current);
            }
            await sink.flush();
          } finally {
            await sink.close();
          }
        }
      } finally {
        await iterator.cancel();
      }

      final attachmentName = _attachmentName(
        url: remote.url,
        title: title,
        mime: effectiveMime,
      );
      final safeTitle = (title ?? '').trim().isEmpty
          ? attachmentName
          : title!.trim();

      onSending?.call();
      await _send(
        settings: settings,
        subject: safeTitle,
        text: l10n.mailBody(safeTitle, attachmentName),
        file: target,
        fileName: attachmentName,
        contentType: effectiveMime,
      );
    } finally {
      client.close();
      if (temp != null) await _deleteQuietly(temp);
    }
  }

  /// Emails book bytes that are already in memory.
  ///
  /// Used for files from the local folder, which have no HTTP address.
  /// A temporary attachment is written and deleted right after sending.
  Future<void> sendBookBytes({
    required AppSettings settings,
    required Uint8List bytes,
    String? title,
    String mime = 'application/octet-stream',
    void Function()? onSending,
  }) async {
    if (!settings.emailConfigured) {
      throw KindleMailException(l10n.mailNotConfigured);
    }
    if (bytes.isEmpty) {
      throw KindleMailException(l10n.opdsEmptyFile);
    }
    if (bytes.length > maxAttachmentBytes) {
      throw KindleMailException(_tooLargeMessage);
    }

    final attachmentName = _attachmentName(
      url: Uri.parse('local://book'),
      title: title,
      mime: mime,
    );
    final safeTitle = (title ?? '').trim().isEmpty
        ? attachmentName
        : title!.trim();

    final dir = await _tempDirectory();
    final temp = File(
      '${dir.path}${Platform.pathSeparator}'
      'klos_${DateTime.now().microsecondsSinceEpoch}.part',
    );
    try {
      await temp.writeAsBytes(bytes, flush: true);
      onSending?.call();
      await _send(
        settings: settings,
        subject: safeTitle,
        text: l10n.mailBody(safeTitle, attachmentName),
        file: temp,
        fileName: attachmentName,
        contentType: mime,
      );
    } finally {
      await _deleteQuietly(temp);
    }
  }

  /// Sends a short letter to verify SMTP and Kindle settings.
  Future<void> sendTest(AppSettings settings) async {
    if (!settings.emailConfigured) {
      throw KindleMailException(l10n.testMailNotConfigured);
    }

    final dir = await _tempDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}'
      'klos_test_${DateTime.now().microsecondsSinceEpoch}.txt',
    );
    try {
      await file.writeAsString(l10n.testMailFileContent);
      await _send(
        settings: settings,
        subject: l10n.testMailSubject,
        text: l10n.testMailBody,
        file: file,
        fileName: 'klos-test.txt',
        contentType: 'text/plain',
      );
    } finally {
      await _deleteQuietly(file);
    }
  }

  Future<void> _send({
    required AppSettings settings,
    required String subject,
    required String text,
    required File file,
    required String fileName,
    required String contentType,
  }) async {
    final message = Message()
      ..from = Address(settings.senderEmail.trim(), 'klos')
      ..recipients.add(Address(settings.kindleEmail.trim()))
      ..subject = subject
      ..text = text
      ..attachments.add(
        FileAttachment(file, contentType: contentType, fileName: fileName),
      );

    final server = SmtpServer(
      settings.smtpHost.trim(),
      port: settings.smtpPort,
      ssl: settings.smtpSsl,
      username: settings.smtpUsername.trim().isEmpty
          ? null
          : settings.smtpUsername.trim(),
      password: settings.smtpPassword.isEmpty ? null : settings.smtpPassword,
      allowInsecure: false,
    );

    await send(message, server, timeout: _sendTimeout);
  }

  static String get _tooLargeMessage => l10n.mailTooLarge;

  /// Turns library and network exceptions into short localized messages.
  static String describeError(Object error) {
    if (error is KindleMailException) return error.message;
    if (error is BookArchiveException) return error.message;
    if (error is SmtpClientAuthenticationException) {
      return l10n.smtpAuthRejected;
    }
    if (error is SmtpUnsecureException) {
      return l10n.smtpNoSecure;
    }
    if (error is SmtpMessageValidationException) {
      return l10n.smtpMessageRejected;
    }
    if (error is SmtpNoGreetingException) {
      return l10n.smtpNoGreeting;
    }
    if (error is SmtpClientCommunicationException) {
      return l10n.smtpCommunication(error.message);
    }
    if (error is MailerException) {
      return l10n.mailSendFailed(error.message);
    }
    if (error is TimeoutException) {
      return l10n.smtpTimeout;
    }
    if (error is HandshakeException) {
      return l10n.smtpTls;
    }
    if (error is SocketException) {
      return l10n.smtpConnectFailed(error.message);
    }
    if (error is OpdsException) return error.message;
    return l10n.mailSendFailed('$error');
  }

  /// Amazon needs a recognizable extension, but the OPDS MIME type is
  /// sometimes missing. Fall back to the extension in the remote URL.
  static String _attachmentName({
    required Uri url,
    String? title,
    required String mime,
  }) {
    final name = fileNameFor(url: url, title: title, mime: mime);
    final knownExtension = RegExp(
      r'\.(epub|mobi|azw3?|pdf|cbz|fb2|txt|zip|rtf|docx?|html?)$',
      caseSensitive: false,
    );
    if (knownExtension.hasMatch(name)) return name;

    final last = url.pathSegments.isEmpty ? '' : url.pathSegments.last.trim();
    final dot = last.lastIndexOf('.');
    if (dot <= 0 || dot == last.length - 1) return name;
    final extension = last.substring(dot);
    if (extension.length > 8 || extension.contains('/')) return name;
    return '$name$extension';
  }

  static String _effectiveMime(String? remoteMime, String? declared) {
    final remote = remoteMime?.split(';').first.trim();
    if (remote != null &&
        remote.isNotEmpty &&
        remote != 'application/octet-stream') {
      return remote;
    }
    final declaredType = declared?.split(';').first.trim();
    if (declaredType != null && declaredType.isNotEmpty) return declaredType;
    return remote == null || remote.isEmpty
        ? 'application/octet-stream'
        : remote;
  }

  static Future<Directory> _tempDirectory() async {
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A leftover temporary file is harmless.
    }
  }
}
