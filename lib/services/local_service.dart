import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/seed_locais.dart';
import '../models/local.dart';

class LocalService {
  LocalService({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _database => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get locais =>
      _database.collection('locais');

  Stream<List<Local>> listarLocais() => locais.snapshots().map((snapshot) {
    final locais = snapshot.docs
        .map((doc) => Local.fromMap(doc.id, doc.data()))
        .toList();
    locais.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return locais;
  });

  Stream<Local?> observarLocal(String id) => locais
      .doc(id)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? Local.fromMap(snapshot.id, snapshot.data()!)
            : null,
      );

  Future<void> add(Local local) async {
    await locais.add(local.toMap());
  }

  Future<void> update(Local local) =>
      locais.doc(local.id).update(local.toMap());

  Future<void> delete(String id) => locais.doc(id).delete();

  Future<void> favorite(String id, bool fav) =>
      locais.doc(id).update({'favorito': fav});

  /// Cria apenas os exemplos ausentes, mantendo os documentos já cadastrados.
  Future<void> seedDefaults() async {
    final existentes = await locais.get();
    final ids = existentes.docs.map((doc) => doc.id).toSet();
    final faltantes = seedLocais.where((local) => !ids.contains(local.id));
    if (faltantes.isEmpty) return;

    final batch = _database.batch();
    for (final local in faltantes) {
      batch.set(locais.doc(local.id), local.toMap());
    }
    await batch.commit();
  }
}
