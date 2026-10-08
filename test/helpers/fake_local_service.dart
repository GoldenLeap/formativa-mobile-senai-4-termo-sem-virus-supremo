import 'dart:async';

import 'package:mapa_locais/data/seed_locais.dart';
import 'package:mapa_locais/models/local.dart';
import 'package:mapa_locais/services/local_service.dart';

/// In-memory fixture for widget tests and reproducible documentation images.
class FakeLocalService extends LocalService {
  FakeLocalService({
    Iterable<Local> initial = seedLocais,
    this.failReads = false,
    this.failWrites = false,
  }) : _records = {for (final local in initial) local.id: local},
       super();

  final Map<String, Local> _records;
  final _changes = StreamController<List<Local>>.broadcast();
  int _nextId = 1;
  bool _disposed = false;
  bool failReads;
  bool failWrites;

  List<Local> get current {
    final values = _records.values.toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return List.unmodifiable(values);
  }

  @override
  Stream<List<Local>> listarLocais() {
    if (failReads) return Stream.error(StateError('Firestore indisponível'));
    return Stream.multi((controller) {
      if (_disposed) {
        controller.closeSync();
        return;
      }
      final subscription = _changes.stream.listen(
        controller.addSync,
        onError: controller.addErrorSync,
        onDone: controller.closeSync,
      );
      controller.onCancel = subscription.cancel;
      controller.addSync(current);
    }, isBroadcast: true);
  }

  @override
  Stream<Local?> observarLocal(String id) => listarLocais().map((values) {
    for (final local in values) {
      if (local.id == id) return local;
    }
    return null;
  });

  void _checkWrite() {
    if (_disposed) throw StateError('Serviço encerrado');
    if (failWrites) throw StateError('Falha ao escrever no Firestore');
  }

  void _notify() {
    if (!_disposed) _changes.add(current);
  }

  @override
  Future<void> add(Local local) async {
    _checkWrite();
    final id = local.id.isEmpty ? 'fake-${_nextId++}' : local.id;
    _records[id] = local.copyWith(id: id);
    _notify();
  }

  @override
  Future<void> update(Local local) async {
    _checkWrite();
    if (!_records.containsKey(local.id)) throw StateError('Local inexistente');
    _records[local.id] = local;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    _checkWrite();
    _records.remove(id);
    _notify();
  }

  @override
  Future<void> favorite(String id, bool fav) async {
    _checkWrite();
    final local = _records[id];
    if (local == null) throw StateError('Local inexistente');
    _records[id] = local.copyWith(favorito: fav);
    _notify();
  }

  @override
  Future<void> seedDefaults() async {
    _checkWrite();
    for (final local in seedLocais) {
      _records.putIfAbsent(local.id, () => local);
    }
    _notify();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _changes.close();
  }
}
