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
import '../favorites_screen/bloc/favorites_bloc.dart';
import '../server_settings/components/settings_sheet.dart';
import 'bloc/catalog_bloc.dart';

/// OPDS catalog rendered inside the app.
///
/// Subcatalogs open as a new screen, so the back button returns to the previous
/// level. Books can be saved to favorites with the bookmark button, and the
/// search icon runs an OpenSearch query when the catalog supports it.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({
    super.key,
    required this.url,
    required this.settings,
    this.title,
  });

  final Uri url;
  final AppSettings settings;

  /// Title shown while the first page loads; the feed title replaces it.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CatalogBloc(settings: settings, initialUrl: url)
            ..add(const CatalogStarted()),
      child: _CatalogView(settings: settings, fallbackTitle: title),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView({required this.settings, this.fallbackTitle});

  final AppSettings settings;
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        final feed = state.feed;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              feed?.title ?? fallbackTitle ?? s.browseCatalog,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (state.canSearch)
                IconButton(
                  onPressed: state.isLoading
                      ? null
                      : () => _openSearch(context),
                  tooltip: s.searchCatalog,
                  icon: const Icon(Icons.search),
                ),
              IconButton(
                onPressed: state.isLoading
                    ? null
                    : () => context.read<CatalogBloc>().add(
                        const CatalogReloadRequested(),
                      ),
                tooltip: s.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _body(context, state),
        );
      },
    );
  }

  /// Small sheet with the search field. The query goes to [CatalogBloc], so
  /// the results open as another page of the same history.
  Future<void> _openSearch(BuildContext context) async {
    final initialQuery = context.read<CatalogBloc>().state.query ?? '';
    final query = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => _SearchSheet(initialQuery: initialQuery),
    );
    final trimmed = query?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) return;
    context.read<CatalogBloc>().add(CatalogSearchRequested(trimmed));
  }

  Widget _body(BuildContext context, CatalogState state) {
    if (state.status == CatalogStatus.failure && state.feed == null) {
      return _error(context, state.error);
    }
    if (state.feed == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CatalogBloc>().add(const CatalogReloadRequested());
      },
      child: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, favorites) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
              if (state.query != null) _queryLabel(context, state.query!),
              if (state.status == CatalogStatus.failure)
                _error(context, state.error),
              _list(context, state.feed!, favorites),
              _pager(context, state.feed!),
            ],
          );
        },
      ),
    );
  }

  Widget _queryLabel(BuildContext context, String query) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        '${s.searchResults} $query',
        style: textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _list(BuildContext context, OpdsFeed feed, FavoritesState favorites) {
    final s = S.of(context);
    if (feed.entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: InfoBox(icon: Icons.menu_book_outlined, text: s.catalogEmpty),
      );
    }
    return Column(
      children: [
        for (final entry in feed.entries)
          _EntryTile(
            entry: entry,
            settings: settings,
            saved: favorites.contains(Favorite.keyFor(entry)),
          ),
      ],
    );
  }

  Widget _pager(BuildContext context, OpdsFeed feed) {
    final s = S.of(context);
    final state = context.watch<CatalogBloc>().state;
    final canGoBack = state.canGoPrevious;
    final canGoForward = feed.nextPage != null;
    if (!canGoBack && !canGoForward) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: canGoBack
                ? () => context.read<CatalogBloc>().add(
                    const CatalogPreviousRequested(),
                  )
                : null,
            child: Text(s.catalogBack),
          ),
          const Spacer(),
          FilledButton(
            onPressed: canGoForward
                ? () => context.read<CatalogBloc>().add(
                    const CatalogNextRequested(),
                  )
                : null,
            child: Text(s.catalogForward),
          ),
        ],
      ),
    );
  }

  Widget _error(BuildContext context, String? message) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.catalogLoadFailed,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(message ?? s.catalogLoadFailedHint),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.read<CatalogBloc>().add(
                  const CatalogReloadRequested(),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(s.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.settings,
    required this.saved,
  });

  final OpdsEntry entry;
  final AppSettings settings;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final navigation = entry.navigationLinks;
    final isFolder = entry.isFolder;
    final key = Favorite.keyFor(entry);
    final author = entry.author?.trim() ?? '';
    final formats = _formatLabels(entry);
    // Descriptions of non-book entries (an author's biography, how many books
    // a subcatalog holds) have no other place to show up in the app, while the
    // Kindle page renders them under the title. Book summaries stay in the
    // details sheet so the list remains compact.
    final summary = entry.hasDownloads ? '' : (entry.summary?.trim() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isFolder
            ? () => _openFolder(context, navigation.first)
            : () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                title: entry.title,
                link: entry.coverLink,
                settings: settings,
                icon: isFolder
                    ? Icons.folder_outlined
                    : Icons.menu_book_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
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
                    if (summary.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          summary,
                          maxLines: 3,
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
              if (key != null)
                IconButton(
                  onPressed: () => context.read<FavoritesBloc>().add(
                    FavoriteToggled(
                      entry,
                      catalogUrl: settings.catalogUrl?.toString() ?? '',
                    ),
                  ),
                  tooltip: saved ? s.favoriteRemove : s.favoriteAdd,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    color: saved ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                )
              else if (isFolder)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFolder(BuildContext context, OpdsLink link, {String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CatalogScreen(
          url: link.href,
          settings: settings,
          title: title ?? entry.title,
        ),
      ),
    );
  }

  /// Title shown for a navigation link, falling back to "Open series".
  static String _seriesTitle(OpdsLink link, String fallback) {
    final title = (link.title ?? '').trim();
    return title.isEmpty ? fallback : title;
  }

  static List<String> _formatLabels(OpdsEntry entry) {
    final labels = <String>{};
    for (final link in entry.downloadLinks) {
      labels.add(EbookFormat.labelForMime(link.type));
    }
    return labels.toList(growable: false);
  }

  void _showDetails(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final formats = _formatLabels(entry);

    showSettingsSheet(
      context,
      builder: (sheetContext) {
        return BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (sheetContext, favorites) {
            final key = Favorite.keyFor(entry);
            final isSaved = favorites.contains(key);
            return SettingsSheet(
              icon: Icons.menu_book_outlined,
              title: entry.title,
              children: [
                if ((entry.author ?? '').trim().isNotEmpty) ...[
                  Text(entry.author!, style: textTheme.titleSmall),
                  const SizedBox(height: 12),
                ],
                if ((entry.summary ?? '').trim().isNotEmpty) ...[
                  Text(entry.summary!),
                  const SizedBox(height: 12),
                ],
                if (formats.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [for (final label in formats) FormatChip(label)],
                  ),
                  const SizedBox(height: 16),
                ],
                if (entry.downloadLinks.isNotEmpty) ...[
                  DownloadToFolderButton(
                    entry: entry,
                    settings: settings,
                    onFinished: () => Navigator.of(sheetContext).pop(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (entry.navigationLinks.isNotEmpty) ...[
                  for (final link in entry.navigationLinks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _openFolder(
                            context,
                            link,
                            title: _seriesTitle(link, s.openSeries),
                          );
                        },
                        icon: const Icon(Icons.folder_outlined),
                        label: Text(
                          _seriesTitle(link, s.openSeries),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                if (key != null)
                  OutlinedButton.icon(
                    onPressed: () => sheetContext.read<FavoritesBloc>().add(
                      FavoriteToggled(
                        entry,
                        catalogUrl: settings.catalogUrl?.toString() ?? '',
                      ),
                    ),
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    label: Text(isSaved ? s.favoriteRemove : s.favoriteAdd),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Search field shown above the catalog.
///
/// The controller belongs to this widget, so it is disposed together with the
/// sheet. Disposing it right after `showModalBottomSheet` returns is too early:
/// the sheet is still animating away and keeps rebuilding the field, which then
/// uses a disposed controller.
class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.initialQuery});

  final String initialQuery;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.searchCatalog,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  border: settingsInputBorder,
                  hintText: s.searchHint,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(s.searchButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
