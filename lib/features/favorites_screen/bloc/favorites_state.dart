part of 'favorites_bloc.dart';

class FavoritesState extends Equatable {
  const FavoritesState({this.favorites = const []});

  /// Saved books, newest first.
  final List<Favorite> favorites;

  bool get isEmpty => favorites.isEmpty;

  int get count => favorites.length;

  /// Whether the book with [key] is already saved.
  bool contains(String? key) {
    if (key == null) return false;
    return favorites.any((favorite) => favorite.key == key);
  }

  @override
  List<Object?> get props => [favorites];
}
