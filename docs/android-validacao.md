# Validação no Android

Executado em 08/10/2026 no emulador Android `emulator-5554` (`sdk_gphone16k x86_64`). O APK de depuração foi compilado, instalado e iniciado com sucesso. A versão final também foi compilada com `flutter build apk --debug --no-pub`.

O aplicativo usou o Firebase `mapa-locais-flutter`, sem substituir o serviço por uma fixture. Foram observados os marcadores de São Paulo e, após trocar a cidade, os quatro locais de Jundiai.

| Ação observada | Resultado | Imagem |
| --- | --- | --- |
| Abrir o mapa de São Paulo | Marcadores, ponto ilustrativo, pesquisa, camadas e navegação visíveis. | [Mapa](prints/android/01-mapa.png) |
| Pesquisar `Academia` e abrir resultados | Cinco academias de São Paulo, ordenadas por distância. | [Resultados](prints/android/02-resultados.png) |
| Abrir Academia Fitness | Nome, avaliação, endereço, horário, ações, descrição, fotos de exemplo e botão de retorno visíveis. | [Detalhes](prints/android/03-detalhes.png) |
| Voltar à lista e tocar em cadastrar | Formulário aberto com cidade São Paulo. Fechado sem salvar. | [Cadastro](prints/android/04-cadastro.png) |
| Fechar o formulário, voltar ao mapa e escolher Jundiai | Quatro marcadores exibidos e pesquisa limpa. App deixado aberto nesse estado. | Conferido pela hierarquia nativa da tela. |

As capturas usam `adb shell screencap` e `adb pull`, com resolução de 1080 × 2400. Nenhum cadastro, edição, favorito ou exclusão foi feito durante as capturas. Esses comportamentos têm testes de interface e uma verificação separada das operações reais do Firestore, descritos em [TESTES.md](TESTES.md).

As fotos dos locais de exemplo não possuem URLs cadastradas e aparecem como placeholders, conforme o layout. O mapa continua ilustrativo.
