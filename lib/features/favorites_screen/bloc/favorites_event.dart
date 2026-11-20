part of 'favorites_bloc.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

/// Adds the book to favorites, or removes it when it is already saved.
class FavoriteToggled extends FavoritesEvent {
  const FavoriteToggled(this.entry, {this.catalogUrl = ''});

  final OpdsEntry entry;

  /// Catalog the book was opened from, stored for reference.
  final String catalogUrl;

  @override
  List<Object?> get props => [entry, catalogUrl];
}

class FavoriteRemoved extends FavoritesEvent {
  const FavoriteRemoved(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}
