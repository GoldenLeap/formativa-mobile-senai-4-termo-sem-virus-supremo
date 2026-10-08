import 'dart:convert';
import 'dart:io';

import 'package:mapa_locais/data/seed_locais.dart';

void main() {
  final file = File('docs/locais-exemplo.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'collection': 'locais',
      'documents': {for (final local in seedLocais) local.id: local.toMap()},
    }),
  );
  stdout.writeln('${seedLocais.length} locais exportados para ${file.path}.');
}
