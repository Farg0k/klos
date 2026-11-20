/// One line of the release notes, already cleaned of Markdown.
///
/// The notes on GitHub are Markdown written for the browser. The sheet has no
/// Markdown renderer, so the raw text would show as `**bold**` and
/// `[link](url)`; a short list reads better on a phone anyway.
class ReleaseNote {
  const ReleaseNote(this.text, {this.bullet = false, this.heading = false});

  /// Text without Markdown markers, with wrapped lines joined.
  final String text;

  /// Whether the line was a list item in the source.
  final bool bullet;

  /// Whether the line was a heading in the source.
  final bool heading;

  @override
  String toString() => 'ReleaseNote($text)';
}

/// Turns the Markdown of a GitHub release into plain lines.
///
/// Links keep their label and lose the address, because a bottom sheet cannot
/// open one without leaving the app. Empty lines disappear: the sheet adds its
/// own spacing.
///
/// Changelog entries are wrapped at 80 columns, so a bullet usually spans
/// several source lines. A line that does not start a block of its own is a
/// continuation of the previous one and is joined to it, otherwise a single
/// change would be shown as two.
List<ReleaseNote> parseReleaseNotes(String markdown) {
  final notes = <ReleaseNote>[];
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    // GitHub adds this footer to generated notes; it is a link to a compare
    // page, not a change.
    if (line.contains('Full Changelog')) continue;

    if (line.startsWith('#')) {
      final heading = _clean(line.replaceAll(RegExp(r'^#+\s*'), ''));
      if (heading.isNotEmpty) notes.add(ReleaseNote(heading, heading: true));
      continue;
    }

    const markers = ['- ', '* ', '+ '];
    final marker = markers.where(line.startsWith).firstOrNull;
    if (marker != null) {
      final text = _clean(line.substring(marker.length));
      if (text.isNotEmpty) notes.add(ReleaseNote(text, bullet: true));
      continue;
    }

    final text = _clean(line);
    if (text.isEmpty) continue;

    // A plain line after a bullet continues it; join instead of adding a new
    // entry. A wrapped paragraph joins the paragraph above it the same way.
    final previous = notes.isEmpty ? null : notes.last;
    if (previous != null && !previous.heading) {
      notes[notes.length - 1] = ReleaseNote(
        '${previous.text} $text'.trim(),
        bullet: previous.bullet,
      );
      continue;
    }

    notes.add(ReleaseNote(text));
  }
  return notes;
}

/// Drops the inline Markdown the release notes usually contain.
String _clean(String line) {
  var text = line;
  // [label](https://example.com) -> label
  text = text.replaceAllMapped(
    RegExp(r'\[([^\]]*)\]\([^)]*\)'),
    (match) => match.group(1) ?? '',
  );
  // **bold**, __bold__, *italic*, _italic_, `code`
  text = text.replaceAll(RegExp(r'\*\*|__|`'), '');
  text = text.replaceAll(RegExp(r'(?<!\w)[*_](\S[^*_]*)[*_]'), r'$1');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
