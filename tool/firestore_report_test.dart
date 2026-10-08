import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/screenshots_test.dart' show loadSdkFonts;

void main() {
  testWidgets('captures report of actual Cloud Firestore documents', (
    tester,
  ) async {
    final audit = jsonDecode(
      File('docs/firestore-verificacao.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final crud = jsonDecode(
      File('docs/firestore-crud.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final documents = (audit['collection']['body']['documents'] as List)
        .cast<Map<String, dynamic>>();
    expect(documents.length, greaterThanOrEqualTo(10));
    expect(audit['anonymousRead']['httpStatus'], 200);
    for (final check in (crud['checks'] as Map<String, dynamic>).values) {
      expect(check['passed'], true);
    }

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1250, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.runAsync(loadSdkFonts);
    const boundaryKey = ValueKey('firestore-real-report');
    String field(Map<String, dynamic> document, String key) {
      final value = document['fields'][key] as Map<String, dynamic>?;
      if (value == null) return '';
      return (value['stringValue'] ??
              value['doubleValue'] ??
              value['integerValue'] ??
              value['booleanValue'] ??
              '')
          .toString();
    }

    Widget cell(String value, {bool header = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        value,
        style: TextStyle(
          fontSize: header ? 12 : 13,
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
          color: const Color(0xff354039),
        ),
      ),
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: Scaffold(
            backgroundColor: const Color(0xfff3f4f1),
            body: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EVIDÊNCIA DA ENTREGA · DADOS CONSULTADOS PELA API REST',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: Color(0xff688278),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cloud Firestore — dados reais',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Projeto ${audit['projectId']}  ·  Banco (default)  ·  Região nam5  ·  Coleção locais',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${documents.length} documentos: ${crud['nonEmptyDocumentCount']} locais preenchidos e 1 documento anterior vazio preservado.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xff315a3e),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xffdce1dc)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3.0),
                        1: FlexColumnWidth(2.7),
                        2: FlexColumnWidth(1.4),
                        3: FlexColumnWidth(1.35),
                        4: FlexColumnWidth(.6),
                        5: FlexColumnWidth(.8),
                      },
                      border: const TableBorder(
                        horizontalInside: BorderSide(color: Color(0xffeef0ec)),
                      ),
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xffe8f0e9),
                          ),
                          children: [
                            'Documento',
                            'Nome',
                            'Categoria',
                            'Cidade',
                            'Nota',
                            'Favorito',
                          ].map((text) => cell(text, header: true)).toList(),
                        ),
                        for (final doc in documents)
                          TableRow(
                            children: [
                              cell((doc['name'] as String).split('/').last),
                              cell(
                                field(doc, 'nome').isEmpty
                                    ? '(documento anterior vazio)'
                                    : field(doc, 'nome'),
                              ),
                              cell(field(doc, 'categoria')),
                              cell(field(doc, 'cidade')),
                              cell(field(doc, 'avaliacao')),
                              cell(field(doc, 'favorito')),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cadastro: OK   ·   Leitura: OK   ·   Edição: OK   ·   Favorito: OK   ·   Exclusão: OK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff315a3e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Teste real em um documento temporário criado e excluído nesta verificação; exclusão confirmada com HTTP 404.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Consulta: ${audit['checkedAt']} (UTC) · Fonte: docs/firestore-verificacao.json e docs/firestore-crud.json',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff667169),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Esta captura é um relatório local da API REST. A interface exibida foi criada para documentar a leitura.',
                    style: TextStyle(fontSize: 12, color: Color(0xff667169)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('docs/prints').create(recursive: true);
      await File('docs/prints/05-firestore.png').writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      image.dispose();
    });
  });
}
