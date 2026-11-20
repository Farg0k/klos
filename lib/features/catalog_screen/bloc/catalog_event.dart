part of 'catalog_bloc.dart';

sealed class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class CatalogStarted extends CatalogEvent {
  const CatalogStarted();
}

class CatalogReloadRequested extends CatalogEvent {
  const CatalogReloadRequested();
}

/// Runs an OpenSearch query against the feed on screen.
class CatalogSearchRequested extends CatalogEvent {
  const CatalogSearchRequested(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class CatalogNextRequested extends CatalogEvent {
  const CatalogNextRequested();
}

class CatalogPreviousRequested extends CatalogEvent {
  const CatalogPreviousRequested();
}
