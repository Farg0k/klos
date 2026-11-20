import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/l10n.dart';
import '../../catalog_screen/catalog_screen.dart';
import '../../favorites_screen/bloc/favorites_bloc.dart';
import '../../favorites_screen/favorites_screen.dart';
import '../../server_settings/catalog_sheet.dart';
import '../bloc/home_bloc.dart';

/// Quick access to the in-app catalog and the books saved from it.
class LibraryCard extends StatelessWidget {
  const LibraryCard({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = state.settings;
    final favorites = context.watch<FavoritesBloc>().state;

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  s.library,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _LibraryTile(
            onTap: () {
              final url = settings.catalogUrl;
              if (url == null) {
                showCatalogSheet(context);
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CatalogScreen(url: url, settings: settings),
                ),
              );
            },
            leading: const Icon(Icons.menu_book_outlined),
            title: s.browseCatalog,
            subtitle: s.browseCatalogHint,
            active: settings.isConfigured,
          ),
          const Divider(height: 1),
          _LibraryTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
            ),
            leading: Icon(
              favorites.isEmpty ? Icons.bookmarks_outlined : Icons.bookmarks,
            ),
            title: s.favorites,
            subtitle: favorites.isEmpty
                ? s.favoritesEmptyShort
                : s.favoritesCount(favorites.count),
            active: !favorites.isEmpty,
          ),
        ],
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: IconTheme(
        data: IconThemeData(
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
        child: leading,
      ),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    );
  }
}
