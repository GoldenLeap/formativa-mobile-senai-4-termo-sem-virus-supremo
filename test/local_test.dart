import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_locais/data/seed_locais.dart';
import 'package:mapa_locais/models/local.dart';

void main() {
  test('legacy Firestore documents retain defaults for added fields', () {
    final local = Local.fromMap('legacy', {
      'nome': 'Local antigo',
      'categoria': 'Academia',
      'cidade': 'São Paulo',
      'avaliacao': 4,
      'distancia': '1.5',
      'horario': '08:00 - 18:00',
      'descricao': 'Documento anterior à expansão do cadastro.',
      'favorito': true,
    });

    expect(local.id, 'legacy');
    expect(local.avaliacao, 4.0);
    expect(local.distancia, 1.5);
    expect(local.favorito, isTrue);
    expect(local.endereco, isEmpty);
    expect(local.telefone, isEmpty);
    expect(local.fotos, isEmpty);
    expect(local.totalAvaliacoes, 0);
    expect(local.mapX, .5);
    expect(local.mapY, .5);
  });

  test(
    'complete documents round trip without losing details or map position',
    () {
      final original = seedLocais.first.copyWith(
        fotos: ['https://example.com/academia.jpg'],
        favorito: true,
      );
      final restored = Local.fromMap(original.id, original.toMap());

      expect(restored.id, original.id);
      expect(restored.toMap(), original.toMap());
      expect(restored.endereco, 'Rua das Flores, 120');
      expect(restored.totalAvaliacoes, 124);
      expect(restored.mapX, .17);
      expect(restored.fotos, ['https://example.com/academia.jpg']);
    },
  );

  test(
    'copyWith changes selected fields while retaining stored information',
    () {
      final original = seedLocais.first;
      final updated = original.copyWith(
        nome: 'Academia editada',
        endereco: 'Rua Nova, 42',
        favorito: true,
      );

      expect(updated.nome, 'Academia editada');
      expect(updated.endereco, 'Rua Nova, 42');
      expect(updated.favorito, isTrue);
      expect(updated.id, original.id);
      expect(updated.telefone, original.telefone);
      expect(updated.mapX, original.mapX);
      expect(updated.mapY, original.mapY);
      expect(original.favorito, isFalse);
      expect(original.endereco, 'Rua das Flores, 120');
    },
  );
}
