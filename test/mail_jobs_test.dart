import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klos/server/mail_jobs.dart';

void main() {
  test('runs jobs one by one and records results', () async {
    final order = <String>[];
    final queue = MailJobQueue(
      run: (job) async {
        order.add('start:${job.title}');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        order.add('end:${job.title}');
        if (job.title == 'bad') throw StateError('smtp down');
      },
    );

    final first = queue.enqueue(
      url: Uri.parse('http://example.com/1.epub'),
      title: 'one',
    );
    final second = queue.enqueue(
      url: Uri.parse('http://example.com/2.epub'),
      title: 'two',
    );
    final bad = queue.enqueue(
      url: Uri.parse('http://example.com/3.epub'),
      title: 'bad',
    );

    await queue.drain();

    expect(first.stage, MailJobStage.done);
    expect(second.stage, MailJobStage.done);
    expect(bad.stage, MailJobStage.failed);
    expect(bad.error, contains('smtp down'));
    expect(order, [
      'start:one',
      'end:one',
      'start:two',
      'end:two',
      'start:bad',
      'end:bad',
    ]);
  });

  test('keeps a job in the queue until the runner finishes', () async {
    final release = Completer<void>();
    final queue = MailJobQueue(
      run: (job) async {
        job.startDownloading();
        await release.future;
      },
    );

    final job = queue.enqueue(
      url: Uri.parse('http://example.com/book.epub'),
      title: 'Book',
    );

    expect(job.isActive, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(job.stage, MailJobStage.downloading);
    expect(queue.byId(job.id), same(job));

    release.complete();
    await queue.drain();
    expect(job.stage, MailJobStage.done);
  });

  test('finds jobs by id and reports unknown ids as null', () async {
    final queue = MailJobQueue(run: (job) async {});
    final job = queue.enqueue(
      url: Uri.parse('http://example.com/book.epub'),
      title: 'Book',
    );
    await queue.drain();

    expect(queue.byId(job.id), same(job));
    expect(queue.byId('missing'), isNull);
  });
}
