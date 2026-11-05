import '../entities/accommodation.dart';
import '../entities/catalog_filter.dart';

/// Puerto de lectura del grupo #1. No es un segundo almacenamiento.
///
/// El adaptador del repositorio compartido aplicará todos los filtros y
/// devolverá únicamente alojamientos disponibles en su orden estable.
/// El provider no filtra una copia local ni conoce el mecanismo de persistencia.
abstract interface class CatalogReader {
  Future<List<Accommodation>> query(CatalogFilter filter);

  /// Revisión creciente después de confirmar un alta, baja o restauración.
  /// Compatible con `Stream<int>` del repositorio compartido del grupo #2.
  Stream<int> get changes;
}
