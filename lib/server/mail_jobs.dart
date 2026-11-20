import 'dart:async';

import '../l10n/l10n.dart';

/// Where a "send to Kindle" job currently is.
enum MailJobStage { queued, downloading, sending, done, failed }

/// Where the attachment comes from.
enum MailJobSource { catalog, local }

class MailJob {
  MailJob({
    required this.id,
    this.url,
    this.localUri,
    this.title,
    this.mime,
    this.source = MailJobSource.catalog,
    this.retryHref,
  });

  final String id;

  /// Remote book for [MailJobSource.catalog].
  final Uri? url;

  /// `content://` document URI for [MailJobSource.local].
  final String? localUri;

  final String? title;
  final String? mime;
  final MailJobSource source;

  /// Page the retry link goes back to, used by local folders.
  final String? retryHref;

  final DateTime createdAt = DateTime.now();

  MailJobStage stage = MailJobStage.queued;
  String? error;

  bool get isFinished =>
      stage == MailJobStage.done || stage == MailJobStage.failed;

  bool get isActive => !isFinished;

  String get displayTitle {
    final value = title?.trim() ?? '';
    return value.isEmpty ? l10n.bookFallbackTitle : value;
  }

  String get stageLabel {
    switch (stage) {
      case MailJobStage.queued:
        return l10n.mailStageQueued;
      case MailJobStage.downloading:
        return l10n.mailStageDownloading;
      case MailJobStage.sending:
        return l10n.mailStageSending;
      case MailJobStage.done:
        return l10n.mailStageDone;
      case MailJobStage.failed:
        return l10n.mailStageFailed;
    }
  }

  void startDownloading() {
    stage = MailJobStage.downloading;
  }

  void startSending() {
    stage = MailJobStage.sending;
  }

  void succeed() {
    stage = MailJobStage.done;
    error = null;
  }

  void fail(String message) {
    stage = MailJobStage.failed;
    error = message;
  }
}

typedef MailJobRunner = Future<void> Function(MailJob job);

/// Runs email jobs one at a time and keeps their recent status.
///
/// The Kindle browser gets a status page immediately; the actual download and
/// SMTP exchange happen in the background so that the browser does not time
/// out on a large book.
class MailJobQueue {
  MailJobQueue({required this.run, this.maxJobs = 40});

  final MailJobRunner run;
  final int maxJobs;

  final Map<String, MailJob> _jobs = {};
  final List<MailJob> _pending = [];
  final List<Completer<void>> _idleWaiters = [];

  int _sequence = 0;
  bool _working = false;
  bool _disposed = false;

  MailJob enqueue({required Uri url, String? title, String? mime}) {
    final job = MailJob(id: _nextId(), url: url, title: title, mime: mime);
    _jobs[job.id] = job;
    _pending.add(job);
    _prune();
    _pump();
    return job;
  }

  MailJob enqueueLocal({
    required String localUri,
    String? title,
    String? mime,
    String? retryHref,
  }) {
    final job = MailJob(
      id: _nextId(),
      localUri: localUri,
      title: title,
      mime: mime,
      source: MailJobSource.local,
      retryHref: retryHref,
    );
    _jobs[job.id] = job;
    _pending.add(job);
    _prune();
    _pump();
    return job;
  }

  MailJob? byId(String id) => _jobs[id];

  /// Completes when the pending queue is empty and no job is running.
  Future<void> drain() {
    if (!_working && _pending.isEmpty) return Future<void>.value();
    final completer = Completer<void>();
    _idleWaiters.add(completer);
    return completer.future;
  }

  void dispose() {
    _disposed = true;
    _pending.clear();
    _jobs.clear();
    _completeIdleWaiters();
  }

  String _nextId() {
    _sequence++;
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$stamp-${_sequence.toRadixString(36)}';
  }

  void _pump() {
    if (_working || _disposed) return;
    _working = true;
    unawaited(_work());
  }

  Future<void> _work() async {
    try {
      while (_pending.isNotEmpty && !_disposed) {
        final job = _pending.removeAt(0);
        if (_disposed) break;
        try {
          await run(job);
          if (!job.isFinished) job.succeed();
        } catch (error) {
          job.fail(error.toString());
        }
      }
    } finally {
      _working = false;
      if (_disposed || _pending.isEmpty) {
        _completeIdleWaiters();
      } else {
        _pump();
      }
    }
  }

  void _completeIdleWaiters() {
    final waiters = List<Completer<void>>.of(_idleWaiters);
    _idleWaiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  /// Keeps only the newest [maxJobs] finished jobs (active ones are kept).
  void _prune() {
    if (_jobs.length <= maxJobs) return;
    final finished = _jobs.values.where((job) => job.isFinished).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final job in finished) {
      if (_jobs.length <= maxJobs) break;
      _jobs.remove(job.id);
    }
  }
}
