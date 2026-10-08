# Testes da entrega

Validação em 08/10/2026. Os testes automatizados de interface usam um serviço em memória explícito, o aplicativo usa `LocalService` e Cloud Firestore. A verificação do banco real foi realizada separadamente.

## Testes automatizados

```sh
flutter analyze
flutter test
```

A análise não apresentou erros ou avisos. Foram aprovados 16 testes de modelo e comportamento: três em `test/local_test.dart` e 13 em `test/widget_test.dart`.

| Área | O que foi verificado |
| --- | --- |
| Modelo | Leitura de documentos antigos, conversão de campos, serialização e edição sem perder informações. |
| Mapa | Locais recebidos pelo serviço, tela de 390 × 844, tela de 320 × 568 com teclado, busca e troca de cidade. |
| Controles | Camada aplicada e centralização restaurando o zoom. |
| Resultados | Nome, categoria, endereço e acentos; combinação de categoria e avaliação mínima. |
| Navegação | Resultados → detalhes → mapa e Perfil → gerenciar → Mapa. |
| Favoritos | Gravação, recuperação após recriar a tela e remoção. |
| Cadastro | Campos obrigatórios, avaliação entre 0 e 5 e criação válida. |
| Edição | Preservação do ID e atualização da página pelos eventos do serviço. |
| Exclusão | Cancelamento preserva o local; confirmação remove e atualiza o mapa. |
| Falhas | Erros de leitura/escrita ficam visíveis; dados de exemplo não substituem silenciosamente o Firestore. |

## Firestore real

Conexão com `mapa-locais-flutter`, banco `(default)` e coleção `locais`. Foram cadastrados somente os 18 IDs de exemplo que ainda não existiam, com condição `exists: false`. O documento original foi preservado.

Em um documento temporário exclusivo da verificação, foram confirmados criação, leitura, edição de nome, favorito `true` e exclusão. A leitura após excluir retornou HTTP 404. As operações passaram sem autenticação, sob as mesmas regras existentes usadas pelo app. Os detalhes estão em [firestore-crud.json](firestore-crud.json) e [firestore-verificacao.json](firestore-verificacao.json).

## Execução Android e imagens

O app foi compilado e iniciado no emulador `emulator-5554`, com leitura dos documentos reais. As capturas nativas estão em [prints/android](prints/android); as observações da navegação ficam em [android-validacao.md](android-validacao.md).

Para reproduzir os prints com a fixture explícita de 18 locais:

```sh
flutter test --dart-define=GENERATE_SCREENSHOTS=true test/screenshots_test.dart
```

Esse teste é ignorado na execução padrão para não gerar imagens a cada rodada. Ele carrega as fontes do SDK e captura mapa, resultados, detalhes e cadastro em 390 × 844, exportando PNG a 2×. São imagens de teste, sem leitura remota.

```sh
flutter test tool/firestore_report_test.dart
```

Este comando regenera [05-firestore.png](prints/05-firestore.png) a partir dos JSONs reais anexados, conferindo a quantidade de documentos e os resultados registrados do CRUD. Ele não refaz as operações remotas. A imagem informa que mostra um relatório REST, e não o Firebase Console.
