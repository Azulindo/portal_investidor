# Portal do Investidor — app da Cleveroption

Este ficheiro é lido a cada sessão. Só deve ter o que poupa tempo: factos que
custaram a descobrir, decisões já tomadas, e armadilhas que já apanharam
alguém. Se uma linha não evitar trabalho, apague-a.

## O essencial em três linhas

- **O projeto Flutter está em `portal_investidor-main/`, não na raiz.** A raiz
  é só o repositório. Corra tudo de lá dentro.
- A app é da **Cleveroption, uma construtora** que constrói e vende imóveis.
  **Não é uma empresa de investimentos** e não reporta valorizações nem
  rentabilidades — não existe esse dado em lado nenhum da API.
- Escreve-se tudo em **português europeu**: código, comentários, commits.

## Comandos

```bash
cd portal_investidor-main
flutter run --dart-define=USE_MOCK=true --dart-define=SKIP_LOGIN=true
flutter analyze && flutter test        # tem de ficar limpo e tudo a passar
```

**O pacote para a Google Play gera-se só com `loja\gerar_pacote.ps1`**, nunca
com o `flutter build appbundle` à mão: o script põe o servidor de produção e a
`CARTO_KEY`, e recusa um pacote assinado com a chave de debug. Sem o
`API_BASE_URL`, a app ia para a loja a apontar para o emulador. O ícone e as
imagens das lojas saem de `loja\gerar.ps1`.

Opções de build no `portal_investidor-main/README.md`. A `CARTO_KEY` não é
opcional em produção: sem ela o mapa cai no OpenStreetMap.

## O ambiente é Windows com PowerShell

- `&&` não encadeia comandos — use `;`.
- `git commit -m` com várias linhas não funciona. Escreva a mensagem num
  ficheiro e use `git commit -F ficheiro.txt`.
- `@{u}` e `@{upstream}` têm de ir entre plicas.
- `[System.IO.File]::ReadAllText` resolve caminhos relativos contra outra
  pasta. Use sempre caminhos absolutos.
- Um comando com `2>&1` que escreva em stderr sai com código 1 mesmo quando
  correu bem. Olhe para a saída, não só para o código.

## Como o código está escrito

- Nomes e comentários em português. Widgets da casa com prefixo `Co`
  (`CoCard`, `CoTitulo`, `CoImagem`, `CoBotao`, `CoCampo`).
- Cores e medidas só de `theme/co_colors.dart` e `theme/co_tokens.dart`.
  Nunca valores à mão.
- Estado com **`provider`**. Não há Riverpod, GetIt, Mockito nem
  `build_runner` — não os introduza sem combinar.
- Os comentários explicam **porquê**, não o quê. Um comentário que descreve o
  que a linha a seguir faz é ruído.

## Decisões fechadas — não voltar a discutir

- **Linguagem de construtora.** Nada de "investimento", "investidor" ou
  "valorização" em texto visível. O painel diz "Pago / Por pagar".
- **O `block` das frações é texto**, não número: há blocos com nome.
- **A contagem do sininho vem do `unreadCount`**, nunca de contar a lista — a
  API manda 30 no máximo mas conta todas.
- **O token de acesso dura 15 minutos** e renova-se sozinho em
  `/auth/refresh`, no `_obterTokenValido` do ApiService. O refresh token é
  rodado a cada troca, por isso **nunca renovar dois em paralelo** — a API
  trata um token repetido como cópia roubada e termina a sessão. Expirado
  deixou de ser o mesmo que acabado: só se manda a pessoa para o login
  quando já não há refresh token.
- **`hasDetailPage: false`** é um empreendimento só de historial: entra nas
  listas e no mapa, mas não abre — o `/project/details` responde-lhe 404.
  Campo ausente conta como `true`. Na app é o `Portfolio.temPagina` e o
  `ConstructionItem.temPagina`, e "em comercialização" exige os dois
  (`estaAVenda`), como o `aVendaNoSite` do site.
- **Os tokens dos emails colam-se à mão.** Deep links ficaram de parte: exigem
  ficheiros no domínio, que é do lado do backend.
- **Na web usa-se SharedPreferences para o token**, não o cofre: o
  `flutter_secure_storage` não arranca numa build de release para web.
- **Biometria adiada** por decisão do Azulindo, apesar de o `local_auth` estar
  no pubspec.
- **O identificador do pacote é `pt.cleveroption.app`**, igual no Android e no
  iOS (o domínio é cleveroption.pt, ao contrário). Até 18/11/2026 foi
  `com.cleveroption.portalinvestidor`; mudou antes de criar o projeto Firebase
  e antes de qualquer publicação. Mudá-lo depois de a app estar publicada é
  publicar uma app nova, com instalações a zero, e o projeto Firebase está
  registado com este nome.
- **O `targetSdk` está fixo em 36**, e não herdado do Flutter instalado: é o
  que a Google exige, e uma atualização do Flutter não deve poder baixá-lo sem
  ninguém dar por isso.
- **A assinatura de release lê o `android/key.properties`** (modelo em
  `android/key.properties.exemplo`). Sem esse ficheiro, o release assina-se
  com as chaves de debug — serve para testar, e a Play Console recusa-o.

## Armadilhas que já custaram tempo

- **Uma build de release para web pode rebentar onde a de profile passa.** Se
  for preciso verificar no browser, use release — profile esconde erros.
- **Telas do CARTO com 2049 bytes** são o carimbo "API KEY REQUIRED", em
  qualquer ponto do mapa. Quer dizer que falta a `CARTO_KEY`.
- **`SizedBox` sem largura numa `Column`** alinhada à esquerda colapsa para
  zero se o filho for um `Row` só com `Expanded`. E um `Row` centra os filhos
  por omissão, portanto um `ColoredBox` sem filho fica com altura zero. As
  duas coisas passam no analyze e nos testes.
- **`keytool -printcert -jarfile` diz "Not a signed jar file" num APK que está
  bem assinado.** Os APKs modernos usam o esquema v2, que o `keytool` não lê.
  Para ver quem assinou:
  `<SDK>/build-tools/<versão>/apksigner verify --print-certs <apk>`.
- **O `ApiService` cria o `http.Client` por dentro**, por isso não há como lhe
  meter um cliente falso. Lógica que precise de teste tem de sair para uma
  função pura (ver `FimDeSessao.motivoPara`).

## Onde está o resto

- Contrato da API: `portal_investidor-main/API_CONTRACT.md`.
- A API é `C:\site_teste\api-cleveroption` — **só leitura, nunca commitar lá**.
- O site é `C:\site_teste\website-cleveroption-1`, ramo `Gui`. A app espelha-o,
  com um desenho mais despido. Quando houver dúvida sobre texto ou regra de
  negócio, veja como o site faz.
- `C:\Cleveroption\cleveroption-website` é do tutor. **Nunca mexer**, nem para
  corrigir.
- Estado atual e lista do que falta: o Project "Cleveroption" no claude.ai,
  em `claude/estado-da-app.md` e `claude/publicar-nas-lojas.md`.

## Antes de dar trabalho por terminado

`flutter analyze` sem avisos e `flutter test` tudo a passar. Mudanças que
mexam em dependências nativas precisam também de `flutter build apk --debug`,
que é onde esse tipo de erro aparece.

Não commite sem pedir. Não faça push sem pedir.
