import 'package:flutter/material.dart';

import '../release_notes.dart';

/// The release notes as a short list of plain lines.
///
/// The notes come from GitHub as Markdown and can be long; this keeps them
/// readable inside the bottom sheet instead of showing the raw source.
class ReleaseNotesView extends StatelessWidget {
  const ReleaseNotesView({super.key, required this.markdown});

  /// The raw `body` of the GitHub release.
  final String markdown;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final notes = parseReleaseNotes(markdown);

    // Nothing readable left — a release whose notes were only GitHub's compare
    // link. An empty block is better than the raw Markdown.
    if (notes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.bullet) ...[
                  Text(
                    '•',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    note.text,
                    style: note.heading
                        ? textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
