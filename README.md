# Mapa de Locais

Aplicativo Flutter com mapa, resultados, detalhes e gerenciamento de locais no Cloud Firestore. O projeto Firebase é `mapa-locais-flutter`, e a coleção usada é `locais`.

## Executar

```sh
flutter pub get
flutter run
```

No emulador usado na entrega:

```sh
flutter run -d emulator-5554
```

## Usar

- No mapa, escolha a cidade e pesquise por nome, endereço ou categoria. Toque na lupa, no botão de lista ou na tecla de pesquisa para abrir os resultados.
- Nos resultados, use as categorias e o botão de filtros para definir a avaliação mínima. Toque em um cartão para abrir os detalhes.
- Nos detalhes, o coração salva o favorito no Firestore. O menu **Gerenciar local** permite editar ou excluir, com confirmação antes da exclusão. **Ver no mapa** retorna ao marcador selecionado.
- Para cadastrar, use o botão **+** nos resultados ou **Perfil → Cadastrar local**. O mesmo formulário é usado na edição.
- **Perfil → Adicionar locais de exemplo** cadastra somente exemplos ausentes, preservando os registros existentes.

O Firestore recebeu 18 locais preenchidos, distribuídos entre São Paulo, Campinas e Jundiai. Um documento vazio anterior foi preservado, totalizando 19 documentos. Os exemplos estão em [seed_locais.dart](lib/data/seed_locais.dart) e [locais-exemplo.json](docs/locais-exemplo.json).

## Entrega e testes

[Checklist de entrega](docs/ENTREGA.md), [testes documentados](docs/TESTES.md) e [verificação do Firebase](docs/firebase-status.md).

```sh
flutter analyze
flutter test
```

Para gerar os quatro prints de teste com os mesmos dados de exemplo:

```sh
flutter test --dart-define=GENERATE_SCREENSHOTS=true test/screenshots_test.dart
```

Para gerar a imagem do relatório usando a consulta real anexada do Firestore:

```sh
flutter test tool/firestore_report_test.dart
```

Os prints estão no [índice de imagens](docs/prints/README.md), com capturas do Android e dos testes. A [imagem do Firestore](docs/prints/05-firestore.png) mostra dados reais retornados pela API REST em um relatório identificado; a [verificação](docs/firebase-status.md) explica sua origem.

## Escopo desta versão

O mapa é ilustrativo, com zoom e posições relativas dos locais; as ruas, o ponto azul e as distâncias de exemplo não são GPS ou rotas reais. Fotos não cadastradas usam o placeholder do layout. Telefone e endereço podem ser consultados e copiados; **Agendar** permite escolher uma data e um horário, sem realizar uma reserva.

Favoritos usam o campo `favorito` de cada documento, compartilhado nesta versão sem login. As regras de teste existentes do Firestore permitem o acesso até **07/11/2026** e foram mantidas.
