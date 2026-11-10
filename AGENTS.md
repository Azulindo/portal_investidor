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
- **Os tokens dos emails colam-se à mão.** Deep links ficaram de parte: exigem
  ficheiros no domínio, que é do lado do backend.
- **Na web usa-se SharedPreferences para o token**, não o cofre: o
  `flutter_secure_storage` não arranca numa build de release para web.
- **Biometria adiada** por decisão do Azulindo, apesar de o `local_auth` estar
  no pubspec.

## Armadilhas que já custaram tempo

- **Uma build de release para web pode rebentar onde a de profile passa.** Se
  for preciso verificar no browser, use release — profile esconde erros.
- **Telas do CARTO com 2049 bytes** são o carimbo "API KEY REQUIRED", em
  qualquer ponto do mapa. Quer dizer que falta a `CARTO_KEY`.
- **`SizedBox` sem largura numa `Column`** alinhada à esquerda colapsa para
  zero se o filho for um `Row` só com `Expanded`. E um `Row` centra os filhos
  por omissão, portanto um `ColoredBox` sem filho fica com altura zero. As
  duas coisas passam no analyze e nos testes.
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
