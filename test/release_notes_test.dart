import 'package:flutter_test/flutter_test.dart';
import 'package:klos/features/update/release_notes.dart';

void main() {
  group('parseReleaseNotes', () {
    test('turns the bullets of the changelog into lines', () {
      final notes = parseReleaseNotes('''
## 1.0.2

- klos checks GitHub Releases by itself when it starts.
- A newer release is announced on the home screen.

## 1.0.1

- Update check in **Settings → About the app**.
''');

      expect(notes.map((note) => note.text), [
        '1.0.2',
        'klos checks GitHub Releases by itself when it starts.',
        'A newer release is announced on the home screen.',
        '1.0.1',
        'Update check in Settings → About the app.',
      ]);
      expect(notes[0].heading, isTrue);
      expect(notes[1].bullet, isTrue);
      expect(notes[3].heading, isTrue);
    });

    test('drops the compare link GitHub adds to generated notes', () {
      final notes = parseReleaseNotes(
        '**Full Changelog**: https://github.com/Farg0k/klos/compare/v1.0.1...v1.0.2',
      );

      expect(notes, isEmpty);
    });

    test('keeps the label of a link and loses the address', () {
      final notes = parseReleaseNotes(
        '- See [the release page](https://github.com/Farg0k/klos/releases).',
      );

      expect(notes.single.text, 'See the release page.');
    });

    test('removes inline formatting and collapses spaces', () {
      final notes = parseReleaseNotes('- Fixed `crash` in __dark__ mode');

      expect(notes.single.text, 'Fixed crash in dark mode');
    });

    test('joins a bullet that is wrapped over several lines', () {
      final notes = parseReleaseNotes('''
- Release notes in «About the app» are shown as a readable list instead of raw
  Markdown, and no longer include GitHub's bare compare link.
- Every release now carries a real changelog, taken from `CHANGELOG.md`.
''');

      expect(notes, hasLength(2));
      expect(
        notes[0].text,
        'Release notes in «About the app» are shown as a readable list instead '
        'of raw Markdown, and no longer include GitHub\'s bare compare link.',
      );
      expect(notes[0].bullet, isTrue);
      expect(
        notes[1].text,
        'Every release now carries a real changelog, taken from CHANGELOG.md.',
      );
    });

    test('joins a wrapped paragraph into one entry', () {
      final notes = parseReleaseNotes('''
A failed check never blocks the app
and keeps the home screen clean.
''');

      expect(
        notes.single.text,
        'A failed check never blocks the app and keeps the home screen clean.',
      );
      expect(notes.single.bullet, isFalse);
    });

    test('keeps plain paragraphs from hand-written notes', () {
      final notes = parseReleaseNotes(
        'The local server keeps working without the network.',
      );

      expect(
        notes.single.text,
        'The local server keeps working without the network.',
      );
      expect(notes.single.bullet, isFalse);
      expect(notes.single.heading, isFalse);
    });

    test('returns nothing for empty notes', () {
      expect(parseReleaseNotes('   \n\n '), isEmpty);
    });
  });
}
