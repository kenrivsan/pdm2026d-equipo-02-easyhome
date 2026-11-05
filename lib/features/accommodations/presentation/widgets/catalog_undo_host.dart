import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/catalog_deletion_controller.dart';

/// Montar una vez alrededor del Scaffold, fuera de estados/filtros del listado.
/// El controller debe vivir lo mismo que la pantalla, no lo mismo que una fila.
class CatalogUndoHost<S extends Object> extends StatefulWidget {
  const CatalogUndoHost({
    required this.controller,
    required this.child,
    this.duration = const Duration(seconds: 5),
    super.key,
  });

  final CatalogDeletionController<S> controller;
  final Widget child;
  final Duration duration;

  @override
  State<CatalogUndoHost<S>> createState() => _CatalogUndoHostState<S>();
}

class _CatalogUndoHostState<S extends Object>
    extends State<CatalogUndoHost<S>> {
  StreamSubscription<CatalogDeletionEvent<S>>? _subscription;
  GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey();
  final _pending = <CatalogUndoTicket<S>, CatalogDeletionController<S>>{};

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _subscription = widget.controller.events.listen(_show);
  }

  @override
  void didUpdateWidget(CatalogUndoHost<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      unawaited(_subscription?.cancel());
      _releaseTickets();
      // Un messenger por pantalla/controlador: no deja acciones viejas en
      // otras rutas ni intenta cerrar SnackBars que aún están en la cola.
      _messengerKey = GlobalKey();
      _listen();
    }
  }

  void _show(CatalogDeletionEvent<S> event) {
    if (!mounted) return;
    final controller = widget.controller;
    final ticket = event.ticket;
    if (ticket != null) _pending[ticket] = controller;
    var actionTaken = false;
    final message = switch (event.kind) {
      CatalogDeletionKind.deleted => 'Alojamiento eliminado.',
      CatalogDeletionKind.deleteFailed => 'No se pudo borrar el alojamiento.',
      CatalogDeletionKind.restored => 'Alojamiento restaurado.',
      CatalogDeletionKind.restoreFailed =>
        'No se pudo restaurar el alojamiento.',
    };
    final bar = _messengerKey.currentState!.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: widget.duration,
        persist: false,
        action:
            ticket == null
                ? null
                : SnackBarAction(
                  label:
                      event.kind == CatalogDeletionKind.restoreFailed
                          ? 'Reintentar'
                          : 'Deshacer',
                  onPressed: () {
                    actionTaken = true;
                    _pending.remove(ticket);
                    unawaited(controller.undo(ticket));
                  },
                ),
      ),
    );
    unawaited(
      bar.closed.then((_) {
        if (!actionTaken && ticket != null) {
          _pending.remove(ticket);
          controller.expire(ticket);
        }
      }),
    );
  }

  void _releaseTickets() {
    for (final entry in _pending.entries) {
      entry.value.expire(entry.key);
    }
    _pending.clear();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _releaseTickets();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaffoldMessenger(key: _messengerKey, child: widget.child);
}
