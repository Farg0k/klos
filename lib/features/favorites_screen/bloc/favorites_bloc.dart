import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../entity/favorite.dart';
import '../../../opds/opds_feed.dart';
import '../../../services/i_objectbox_service.dart';
import '../../../utils/locator.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

/// Keeps the books saved from the catalog in memory so every screen shows the
/// same state without reading the database again.
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc() : this._(locator<IObjectBoxService>());

  FavoritesBloc._(this._objectbox)
    : super(FavoritesState(favorites: _objectbox.getFavorites())) {
    on<FavoriteToggled>(_onToggled);
    on<FavoriteRemoved>(_onRemoved);
  }

  final IObjectBoxService _objectbox;

  void _onToggled(FavoriteToggled event, Emitter<FavoritesState> emit) {
    final key = Favorite.keyFor(event.entry);
    if (key == null) return;

    if (state.contains(key)) {
      _objectbox.removeFavorite(key);
    } else {
      final favorite = Favorite.fromEntry(
        event.entry,
        catalogUrl: event.catalogUrl,
      );
      if (favorite == null) return;
      _objectbox.saveFavorite(favorite);
    }
    emit(FavoritesState(favorites: _objectbox.getFavorites()));
  }

  void _onRemoved(FavoriteRemoved event, Emitter<FavoritesState> emit) {
    _objectbox.removeFavorite(event.key);
    emit(FavoritesState(favorites: _objectbox.getFavorites()));
  }
}
