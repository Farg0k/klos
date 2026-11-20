import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../books/ebook_formats.dart';
import '../../components/book_cover.dart';
import '../../components/download_to_folder_button.dart';
import '../../components/format_chip.dart';
import '../../components/info_box.dart';
import '../../entity/app_settings.dart';
import '../../entity/favorite.dart';
import '../../generated/l10n.dart';
import '../../opds/opds_feed.dart';
import '../home_screen/bloc/home_bloc.dart';
import '../server_settings/components/settings_sheet.dart';
import 'bloc/favorites_bloc.dart';

/// Books saved from the catalog in the app.
///
/// The list is also served to the Kindle at `/favorites`; the help sheet tells
/// where to find that page.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.favorites)),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, home) {
          return BlocBuilder<FavoritesBloc, FavoritesState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (state.isEmpty)
                    InfoBox(
                      icon: Icons.bookmarks_outlined,
                      text: s.favoritesEmpty,
                    )
                  else
                    for (final favorite in state.favorites)
                      _FavoriteTile(
                        favorite: favorite,
                        settings: home.settings,
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.favorite, required this.settings});

  final Favorite favorite;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final formats = _formatLabels(favorite);
    final author = favorite.author?.trim() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, favorite),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                title: favorite.title,
                link: _coverLink(favorite),
                settings: settings,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (author.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (formats.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final label in formats) FormatChip(label),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => context.read<FavoritesBloc>().add(
                  FavoriteRemoved(favorite.key),
                ),
                tooltip: s.favoriteRemove,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<String> _formatLabels(Favorite favorite) {
    final labels = <String>{};
    for (final link in favorite.links) {
      if (!link.isAcquisition) continue;
      labels.add(EbookFormat.labelForMime(link.type));
    }
    return labels.toList(growable: false);
  }

  /// Best cover link stored with the favorite.
  static OpdsLink? _coverLink(Favorite favorite) {
    OpdsLink? full;
    for (final link in favorite.links) {
      if (link.isThumbnail) return link;
      if (link.isCover) full ??= link;
    }
    return full;
  }

  void _showDetails(BuildContext context, Favorite favorite) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    showSettingsSheet(
      context,
      builder: (sheetContext) => SettingsSheet(
        icon: Icons.bookmark,
        title: favorite.title,
        children: [
          if ((favorite.author ?? '').trim().isNotEmpty) ...[
            Text(favorite.author!, style: textTheme.titleSmall),
            const SizedBox(height: 12),
          ],
          if ((favorite.summary ?? '').trim().isNotEmpty) ...[
            Text(favorite.summary!),
            const SizedBox(height: 12),
          ],
          if (_formatLabels(favorite).isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final label in _formatLabels(favorite)) FormatChip(label),
              ],
            ),
            const SizedBox(height: 16),
          ],
          DownloadToFolderButton(
            entry: favorite.toEntry(),
            settings: settings,
            onFinished: () => Navigator.of(sheetContext).pop(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                context.read<FavoritesBloc>().add(
                  FavoriteRemoved(favorite.key),
                );
                Navigator.of(sheetContext).pop();
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(s.favoriteRemove),
            ),
          ),
        ],
      ),
    );
  }
}
