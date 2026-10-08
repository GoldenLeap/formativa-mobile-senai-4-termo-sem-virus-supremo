# Checklist de entrega

Verificado em 08/10/2026. Implementação mantida em widgets Flutter, modelo `Local` e serviço `LocalService`, sem novas dependências.

| Item | Status | Evidência |
| --- | --- | --- |
| Projeto Flutter executando | ✅ | APK compilado e app iniciado no emulador Android `emulator-5554`. |
| Firebase conectado ao projeto | ✅ | Configurações Flutter/Android existentes; app lendo o projeto `mapa-locais-flutter`. |
| Cloud Firestore configurado | ✅ | Banco `(default)` ativo, `FIRESTORE_NATIVE`, região `nam5`. |
| Coleção `locais` criada | ✅ | Consulta real da coleção com HTTP 200. |
| Pelo menos 10 locais cadastrados | ✅ | 18 locais preenchidos; 19 documentos contando o registro vazio anterior preservado. |
| Tela de mapa implementada | ✅ | Mapa ilustrativo com zoom, marcadores dos documentos, pesquisa e seleção de cidade. |
| Tela de resultados implementada | ✅ | Cartões, pesquisa, cidade, categorias e avaliação mínima. |
| Tela de detalhes implementada | ✅ | Informações, fotos/placeholder, favorito, menu de edição/exclusão e retorno ao mapa. |
| Leitura do Firestore funcionando | ✅ | Streams na lista, mapa e detalhes; leitura remota e execução Android confirmadas. |
| Cadastro funcionando | ✅ | Formulário validado, `LocalService.add`, teste de interface e criação remota confirmada. |
| Edição funcionando | ✅ | Mesmo formulário, preservação do ID, `LocalService.update` e verificação remota. |
| Exclusão funcionando | ✅ | Confirmação antes de excluir; teste de cancelamento/confirmação e remoção remota de documento temporário. |
| Favoritos funcionando | ✅ | Campo persistido no Firestore, filtro na aba Favoritos e verificação remota. |
| Pesquisa funcionando | ✅ | Nome, endereço, categoria e cidade; busca ignora acentos e caixa. |
| Filtros funcionando | ✅ | Categoria, cidade, favoritos e avaliação mínima combinados. |
| Navegação funcionando | ✅ | Mapa → Resultados → Detalhes → Mapa, Favoritos e Perfil; retorno ao mapa vindo do Perfil coberto por teste. |
| Testes documentados | ✅ | [TESTES.md](TESTES.md). |
| Prints das telas anexados | ✅ | [Índice de imagens](prints/README.md), com Android e capturas de teste. |
| Print do Firestore anexado | ✅* | [Dados reais do Firestore](prints/05-firestore.png). |

\* O print do Firestore é um relatório dos documentos reais consultados pela API REST, com essa origem indicada na imagem. Não é uma captura do Firebase Console. Caso a avaliação exija especificamente o Console, a tela a capturar está em [coleção locais](https://console.firebase.google.com/project/mapa-locais-flutter/firestore/databases/-default-/data/~2Flocais).

## Arquivos de evidência

- [Verificação do Firebase e condições de acesso](firebase-status.md).
- [Consulta real do banco e dos documentos](firestore-verificacao.json).
- [Cadastro, leitura, edição, favorito e exclusão reais](firestore-crud.json).
- [Relatório navegável dos documentos](firestore.html).
- [Dados de exemplo usados no cadastro](locais-exemplo.json).

## Limites definidos para manter a versão simples

O mapa e o ponto azul são ilustrativos; não há GPS ou cálculo de rotas. Os 18 locais são exemplos, com informações e avaliações de demonstração. Favoritos são compartilhados pelo campo do documento, sem contas de usuário. Telefone/endereço são apresentados para consulta e cópia, e a escolha de data/hora não faz reserva nem salva um agendamento.

As regras de teste que já estavam no projeto permitem acesso até **07/11/2026**. Nenhuma regra remota foi alterada nesta entrega. O documento vazio anterior permaneceu no banco; filtros de cidade o deixam fora dos resultados.
