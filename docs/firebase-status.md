# Firebase e Cloud Firestore

Verificação feita em 08/10/2026, às 15:37, horário de Brasília.

- Projeto Firebase: `mapa-locais-flutter`, ativo e acessível pela conta já autenticada na CLI.
- Configuração Flutter existente em `lib/firebase_options.dart`; configuração Android em `android/app/google-services.json`.
- Banco `(default)` do Cloud Firestore existente, modo `FIRESTORE_NATIVE`, região `nam5`.
- Coleção `locais` consultada remotamente com HTTP 200, inclusive sem autenticação, conforme as regras usadas pelo aplicativo.
- 18 locais de exemplo cadastrados com os IDs do arquivo [locais-exemplo.json](locais-exemplo.json). O cadastro usou a condição `exists: false` e preservou os documentos anteriores.
- Total após a entrega: 19 documentos, sendo 18 locais preenchidos e um documento vazio anterior, mantido sem alteração.
- Cadastro, leitura, edição e alteração de favorito passaram pela API REST sem autenticação em um documento temporário criado para a verificação.
- Exclusão passou somente nesse documento temporário; uma leitura posterior retornou HTTP 404. Alteração e exclusão usaram a condição `updateTime` para evitar sobrescrever uma edição concorrente.

Os resultados completos estão em [firestore-verificacao.json](firestore-verificacao.json) e [firestore-crud.json](firestore-crud.json), sem credenciais. Esses testes confirmam o banco real e as regras de acesso; os testes de interface do aplicativo são documentados separadamente.

As regras remotas existentes permitem leitura e escrita durante o período de teste, até **07/11/2026**. Elas foram consultadas e mantidas. Após essa data, precisam ser revistas no Firebase para o aplicativo continuar acessando o banco.

A imagem [05-firestore.png](prints/05-firestore.png) é uma captura de um relatório local dos dados reais retornados pela API REST. Ela identifica explicitamente a origem dos dados e não é uma captura do Firebase Console. Para uma entrega que exija o Console, anexar também a tela da coleção em [Firebase Console](https://console.firebase.google.com/project/mapa-locais-flutter/firestore/databases/-default-/data/~2Flocais).

Ambiente disponível para execução: emulador Android `emulator-5554`, Node.js e Chrome/Edge instalados. Não foi necessário instalar Playwright.
