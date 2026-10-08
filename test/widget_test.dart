import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_locais/data/seed_locais.dart';
import 'package:mapa_locais/main.dart';
import 'package:mapa_locais/models/local.dart';
import 'package:mapa_locais/screens/details_screen.dart';
import 'package:mapa_locais/screens/results_screen.dart';
import 'package:mapa_locais/widgets/local_card.dart';
import 'package:mapa_locais/widgets/local_form.dart';
import 'package:mapa_locais/widgets/map_background.dart';

import 'helpers/fake_local_service.dart';

FakeLocalService createService({
  bool failReads = false,
  bool failWrites = false,
}) {
  final service = FakeLocalService(
    failReads: failReads,
    failWrites: failWrites,
  );
  addTearDown(service.dispose);
  return service;
}

void configurePhone(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<FakeLocalService> pumpMap(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  FakeLocalService? service,
}) async {
  configurePhone(tester, size);
  final fake = service ?? createService();
  await tester.pumpWidget(MyApp(key: UniqueKey(), service: fake));
  await tester.pumpAndSettle();
  return fake;
}

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  configurePhone(tester, const Size(390, 844));
  await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: screen));
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> fillField(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(field(label));
  await tester.enterText(field(label), value);
  await tester.pump();
}

Future<void> saveForm(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(find.text('Salvar local'));
  await tester.tap(find.text('Salvar local'));
  await tester.pumpAndSettle();
}

Future<void> openPlace(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Academia Fitness'));
  await tester.pumpAndSettle();
  expect(find.byType(DetailsScreen), findsOneWidget);
}

Future<void> chooseManagement(WidgetTester tester, String action) async {
  await tester.tap(find.byTooltip('Gerenciar local'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

Widget formLauncher(FakeLocalService service, {Local? local}) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: FilledButton(
        onPressed: () => showLocalForm(context, service, local: local),
        child: const Text('Abrir cadastro'),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'map displays the selected city and places supplied by the service',
    (tester) async {
      final service = await pumpMap(tester);

      expect(service.current, hasLength(18));
      expect(find.text('São Paulo'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
        'Buscar locais, endereços ou categorias...',
      );
      expect(find.byTooltip('Academia Fitness'), findsOneWidget);
      expect(find.byTooltip('Parque da Cidade'), findsOneWidget);
      for (final label in ['Mapa', 'Favoritos', 'Perfil']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byTooltip('Centralizar mapa'), findsOneWidget);
      expect(find.byTooltip('Camadas do mapa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small phone keeps map geometry stable while searching with the keyboard',
    (tester) async {
      await pumpMap(tester, size: const Size(320, 568));
      final mapSize = tester.getSize(find.byType(MapBackground));
      addTearDown(tester.view.resetViewInsets);

      try {
        await tester.tap(find.byType(TextField));
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'cafe');
        await tester.pumpAndSettle();

        expect(find.byTooltip('Café da Esquina'), findsOneWidget);
        expect(tester.getSize(find.byType(MapBackground)), mapSize);
        expect(tester.takeException(), isNull);
      } finally {
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byTooltip('Centralizar mapa'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search matches category, address and accents and recovers from no results',
    (tester) async {
      await pumpMap(tester);

      for (final (query, matchingPlace) in [
        ('ACADEMIA', 'Academia Fitness'),
        ('Academias', 'Academia Fitness'),
        ('Hospital', 'Hospital Central'),
        ('Hospitais', 'Hospital Central'),
        ('Rua dos Pinheiros, 45', 'Café da Esquina'),
        ('cafe', 'Café da Esquina'),
      ]) {
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();
        expect(find.byTooltip(matchingPlace), findsOneWidget);
        expect(find.byTooltip('Parque da Cidade'), findsNothing);
        if (query == 'ACADEMIA' || query == 'Academias') {
          expect(find.byTooltip('Smart Fit'), findsOneWidget);
          expect(find.byTooltip('Body Center'), findsOneWidget);
        }
      }

      await tester.enterText(
        find.byType(TextField),
        'local inexistente 987654',
      );
      await tester.pumpAndSettle();
      expect(find.text('Nenhum local encontrado'), findsOneWidget);
      expect(find.byTooltip('Academia Fitness'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Nenhum local encontrado'), findsNothing);
      expect(find.byTooltip('Academia Fitness'), findsOneWidget);
      expect(find.byTooltip('Parque da Cidade'), findsOneWidget);
    },
  );

  testWidgets('choosing Campinas changes city and visible places', (
    tester,
  ) async {
    await pumpMap(tester);
    await tester.tap(find.text('São Paulo'));
    await tester.pumpAndSettle();

    expect(find.text('Campinas'), findsOneWidget);
    expect(find.text('Jundiai'), findsOneWidget);
    await tester.tap(find.text('Campinas'));
    await tester.pumpAndSettle();

    expect(find.text('Campinas'), findsOneWidget);
    expect(find.byTooltip('Academia Movimento'), findsOneWidget);
    expect(find.byTooltip('Academia Fitness'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layers affect the map and recenter resets an actual zoom', (
    tester,
  ) async {
    await pumpMap(tester);
    await tester.tap(find.byTooltip('Camadas do mapa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apenas ruas'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MapBackground>(find.byType(MapBackground)).showParks,
      isFalse,
    );
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    controller.value = Matrix4.diagonal3Values(2, 2, 1);
    await tester.pump();
    expect(controller.value, isNot(Matrix4.identity()));

    await tester.tap(find.byTooltip('Centralizar mapa'));
    await tester.pumpAndSettle();
    expect(controller.value, Matrix4.identity());
  });

  testWidgets('results combine category and minimum rating filters', (
    tester,
  ) async {
    final service = createService();
    await pumpScreen(tester, ResultsScreen(service: service));
    await tester.tap(find.text('Academias'));
    await tester.pumpAndSettle();

    expect(find.byType(LocalCard), findsNWidgets(5));
    expect(find.text('Restaurante Verde'), findsNothing);
    await tester.tap(find.byTooltip('Filtrar por avaliação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4.5 ou mais'));
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(find.byType(LocalCard), findsNWidgets(2));
    expect(find.text('Academia Fitness'), findsOneWidget);
    expect(find.text('Smart Fit'), findsOneWidget);
    expect(find.text('Body Center'), findsNothing);
  });

  testWidgets(
    'search results open details and Ver no mapa returns to the selected place',
    (tester) async {
      await pumpMap(tester);
      await tester.enterText(find.byType(TextField), 'Academia');
      await tester.tap(find.byTooltip('Pesquisar'));
      await tester.pumpAndSettle();

      expect(find.byType(ResultsScreen), findsOneWidget);
      await tester.tap(find.text('Academia Fitness'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailsScreen), findsOneWidget);
      expect(find.text('Rua das Flores, 120 · São Paulo'), findsOneWidget);

      await tester.ensureVisible(find.text('Ver no mapa'));
      await tester.tap(find.text('Ver no mapa'));
      await tester.pumpAndSettle();

      expect(find.byType(ResultsScreen), findsNothing);
      expect(find.byType(DetailsScreen), findsNothing);
      expect(find.byTooltip('Academia Fitness'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Mapa from managed results returns from Perfil to the root map', (
    tester,
  ) async {
    await pumpMap(tester);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Seu perfil'), findsOneWidget);
    expect(find.byType(MapBackground), findsNothing);
    await tester.ensureVisible(find.text('Gerenciar locais'));
    await tester.tap(find.text('Gerenciar locais'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultsScreen), findsOneWidget);

    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultsScreen), findsNothing);
    expect(find.text('Seu perfil'), findsNothing);
    expect(find.byType(MapBackground), findsOneWidget);
    expect(find.byTooltip('Academia Fitness'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'favorite writes persist after rebuilding the app and can be removed',
    (tester) async {
      final service = await pumpMap(tester);
      await openPlace(tester);
      await tester.tap(find.byTooltip('Adicionar aos favoritos'));
      await tester.pumpAndSettle();

      expect(
        service.current
            .firstWhere((local) => local.id == seedLocais.first.id)
            .favorito,
        isTrue,
      );
      await pumpMap(tester, service: service);
      await tester.tap(find.text('Favoritos'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(LocalCard, 'Academia Fitness'),
        findsOneWidget,
      );
      await tester.tap(find.text('Academia Fitness'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remover dos favoritos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(
        service.current
            .firstWhere((local) => local.id == seedLocais.first.id)
            .favorito,
        isFalse,
      );
      expect(find.byType(LocalCard), findsNothing);
    },
  );

  testWidgets(
    'create validates required fields and rating before persisting a local',
    (tester) async {
      final service = createService();
      await pumpScreen(tester, formLauncher(service));
      await tester.tap(find.text('Abrir cadastro'));
      await tester.pumpAndSettle();
      await saveForm(tester);

      expect(service.current, hasLength(18));
      expect(find.text('Preencha este campo.'), findsNWidgets(2));
      await fillField(tester, 'Nome', 'Academia Nova');
      await fillField(tester, 'Endereço', 'Rua Nova, 42');
      await fillField(tester, 'Avaliação (0 a 5)', '6');
      await saveForm(tester);

      expect(find.text('Informe uma nota de 0 a 5.'), findsOneWidget);
      expect(service.current, hasLength(18));
      await fillField(tester, 'Avaliação (0 a 5)', '4,6');
      await saveForm(tester);

      expect(find.byType(BottomSheet), findsNothing);
      final added = service.current.singleWhere(
        (local) => local.nome == 'Academia Nova',
      );
      expect(added.id, isNotEmpty);
      expect(added.endereco, 'Rua Nova, 42');
      expect(added.avaliacao, 4.6);
      expect(added.cidade, 'São Paulo');
      expect(service.current, hasLength(19));
    },
  );

  testWidgets(
    'editing details preserves the document id and updates the live page',
    (tester) async {
      final service = await pumpMap(tester);
      await openPlace(tester);
      await chooseManagement(tester, 'Editar local');
      await fillField(tester, 'Nome', 'Academia Renovada');
      await fillField(tester, 'Endereço', 'Rua Reformada, 12');
      await saveForm(tester);

      final updated = service.current.singleWhere(
        (local) => local.id == seedLocais.first.id,
      );
      expect(updated.nome, 'Academia Renovada');
      expect(updated.endereco, 'Rua Reformada, 12');
      expect(updated.totalAvaliacoes, seedLocais.first.totalAvaliacoes);
      expect(service.current, hasLength(18));
      expect(find.text('Academia Renovada'), findsOneWidget);
      expect(find.text('Rua Reformada, 12 · São Paulo'), findsOneWidget);
    },
  );

  testWidgets(
    'delete requires confirmation and removes the place from the live map',
    (tester) async {
      final service = await pumpMap(tester);
      await openPlace(tester);
      await chooseManagement(tester, 'Excluir local');
      expect(find.text('Excluir local?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(service.current, hasLength(18));
      expect(find.byType(DetailsScreen), findsOneWidget);

      await chooseManagement(tester, 'Excluir local');
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(service.current, hasLength(17));
      expect(
        service.current.any((local) => local.id == seedLocais.first.id),
        isFalse,
      );
      expect(find.byType(DetailsScreen), findsNothing);
      expect(find.byTooltip('Academia Fitness'), findsNothing);
    },
  );

  testWidgets(
    'read and write failures show errors without substituting seed data',
    (tester) async {
      await pumpMap(tester, service: createService(failReads: true));
      expect(find.text('Não foi possível carregar os locais'), findsOneWidget);
      expect(find.byTooltip('Academia Fitness'), findsNothing);

      final service = createService(failWrites: true);
      await pumpScreen(tester, formLauncher(service));
      await tester.tap(find.text('Abrir cadastro'));
      await tester.pumpAndSettle();
      await fillField(tester, 'Nome', 'Não salvo');
      await fillField(tester, 'Endereço', 'Rua do Erro, 1');
      await saveForm(tester);

      expect(
        find.text(
          'Não foi possível salvar. Confira a conexão e as permissões do Firestore e tente novamente.',
        ),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(service.current, hasLength(18));
      expect(
        service.current.any((local) => local.nome == 'Não salvo'),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
