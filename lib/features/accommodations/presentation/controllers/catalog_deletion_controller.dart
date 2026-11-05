import 'dart:async';

import 'package:flutter/foundation.dart';

/// Puerto de UI provisional: S es el DeletedAccommodation de Javier cuando
/// se publique. Nunca reconstruirlo desde la tarjeta ni desde un índice filtrado.
class CatalogDeletionController<S extends Object> extends ChangeNotifier {
  CatalogDeletionController({
    required Future<S> Function(String id) deleteById,
    required Future<void> Function(S snapshot) restore,
  }) : _deleteById = deleteById,
       _restore = restore;

  final Future<S> Function(String) _deleteById;
  final Future<void> Function(S) _restore;
  final _events = StreamController<CatalogDeletionEvent<S>>.broadcast();
  final _locked = <String>{};
  final _tickets = <CatalogUndoTicket<S>>{};
  bool _disposed = false;

  Stream<CatalogDeletionEvent<S>> get events => _events.stream;
  bool isLocked(String id) => _locked.contains(id);

  Future<void> deleteById(String id) async {
    if (_disposed || !_locked.add(id)) return;
    notifyListeners();
    try {
      final snapshot = await _deleteById(id);
      if (_disposed) return;
      final ticket = CatalogUndoTicket<S>._(id, snapshot);
      _tickets.add(ticket);
      _events.add(CatalogDeletionEvent(CatalogDeletionKind.deleted, ticket));
    } catch (_) {
      if (_disposed) return;
      _locked.remove(id);
      _events.add(CatalogDeletionEvent(CatalogDeletionKind.deleteFailed, null));
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> undo(CatalogUndoTicket<S> ticket) async {
    if (_disposed || !_tickets.contains(ticket) || ticket._restoring) return;
    ticket._restoring = true;
    try {
      await _restore(ticket.snapshot);
      if (_disposed) return;
      _release(ticket);
      _events.add(CatalogDeletionEvent(CatalogDeletionKind.restored, null));
    } catch (_) {
      if (_disposed) return;
      ticket._restoring = false;
      _events.add(
        CatalogDeletionEvent(CatalogDeletionKind.restoreFailed, ticket),
      );
    }
  }

  /// Se llama cuando expira o se descarta la oportunidad de Deshacer.
  void expire(CatalogUndoTicket<S> ticket) {
    if (_disposed || ticket._restoring) return;
    _release(ticket);
  }

  void _release(CatalogUndoTicket<S> ticket) {
    if (!_tickets.remove(ticket)) return;
    _locked.remove(ticket.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tickets.clear();
    _locked.clear();
    unawaited(_events.close());
    super.dispose();
  }
}

class CatalogUndoTicket<S extends Object> {
  CatalogUndoTicket._(this.id, this.snapshot);

  final String id;
  final S snapshot;
  bool _restoring = false;
}

enum CatalogDeletionKind { deleted, deleteFailed, restored, restoreFailed }

class CatalogDeletionEvent<S extends Object> {
  const CatalogDeletionEvent(this.kind, this.ticket);

  final CatalogDeletionKind kind;
  final CatalogUndoTicket<S>? ticket;
}
