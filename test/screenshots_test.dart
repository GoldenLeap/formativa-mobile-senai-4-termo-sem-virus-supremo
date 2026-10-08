import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_locais/main.dart';

import 'helpers/fake_local_service.dart';

const _generateScreenshots = bool.fromEnvironment('GENERATE_SCREENSHOTS');
const _boundaryKey = ValueKey('documentation-screenshot-boundary');

Future<void> loadSdkFonts() async {
  final configFile = File('.dart_tool/package_config.json');
  final config =
      jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
  final packages = (config['packages'] as List).cast<Map<String, dynamic>>();
  final flutter = packages.singleWhere(
    (package) => package['name'] == 'flutter',
  );
  final packageUri = configFile.absolute.uri.resolve(
    flutter['rootUri'] as String,
  );
  final sdkRoot = Directory.fromUri(packageUri).parent.parent;
  final fontDirectory = '${sdkRoot.path}/bin/cache/artifacts/material_fonts';

  for (final (family, filename) in [
    ('Roboto', 'roboto-regular.ttf'),
    ('MaterialIcons', 'materialicons-regular.otf'),
  ]) {
    final loader = FontLoader(family);
    loader.addFont(
      File('$fontDirectory/$filename').readAsBytes().then(
        (bytes) =>
            bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
    await loader.load();
  }
}

void repaintSubtree(RenderObject object) {
  object.markNeedsPaint();
  object.visitChildren(repaintSubtree);
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  // Route transitions retain layers. Paint every child again before exporting.
  repaintSubtree(boundary);
  await tester.pump();
  expect(boundary.debugNeedsPaint, isFalse);
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      final png = bytes!;
      await Directory('docs/prints').create(recursive: true);
      await File('docs/prints/$name.png').writeAsBytes(
        png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
        flush: true,
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  testWidgets(
    'captures documentation screens using the explicit 18-place fixture',
    (tester) async {
      const safeArea = FakeViewPadding(top: 32, bottom: 24);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = safeArea;
      tester.view.viewPadding = safeArea;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final service = FakeLocalService();
      addTearDown(service.dispose);

      await tester.runAsync(loadSdkFonts);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundaryKey,
          child: MyApp(service: service),
        ),
      );
      await capture(tester, '01-mapa');

      await tester.enterText(find.byType(TextField), 'Academia');
      await tester.tap(find.byTooltip('Pesquisar'));
      await capture(tester, '02-resultados');

      await tester.tap(find.text('Academia Fitness'));
      await capture(tester, '03-detalhes');

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cadastrar local'));
      await capture(tester, '04-cadastro');
    },
    skip: !_generateScreenshots,
  );
}
