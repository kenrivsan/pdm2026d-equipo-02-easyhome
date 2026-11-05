import 'package:flutter/material.dart';

import '../../domain/entities/accommodation.dart';
import '../controllers/catalog_deletion_controller.dart';

/// La lista reactiva retira la fila mediante una consulta confirmada del repo.
/// No mantener una copia local de alojamientos ni borrar desde onDismissed.
class CatalogDismissible<S extends Object> extends StatelessWidget {
  CatalogDismissible({
    required this.alojamiento,
    required this.controller,
    required this.child,
  }) : super(key: ValueKey(alojamiento.id));

  final Accommodation alojamiento;
  final CatalogDeletionController<S> controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder:
          (context, _) => Dismissible(
            key: ValueKey(alojamiento.id),
            direction:
                controller.isLocked(alojamiento.id)
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
            background: Container(
              color: Theme.of(context).colorScheme.errorContainer,
              alignment: AlignmentDirectional.centerEnd,
              padding: const EdgeInsets.all(20),
              child: const Icon(Icons.delete_outline, semanticLabel: 'Borrar'),
            ),
            confirmDismiss: (_) async {
              await controller.deleteById(alojamiento.id);
              // changes puede desmontar esta fila antes de completar el Future.
              // La consulta manda: no dejar un Dismissible descartado en el árbol
              // ni quitar una fila optimistamente si la escritura falla.
              return false;
            },
            child: child,
          ),
    );
  }
}
