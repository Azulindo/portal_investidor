# Portal do Investidor

A app da Clever Option para quem investe: a carteira, o estado das obras, as
encomendas e as faturas. Espelha a Área Reservada do site, com um desenho mais
despido.

O contrato com a API está em [`API_CONTRACT.md`](API_CONTRACT.md).

## Como correr

```bash
flutter pub get
flutter run --dart-define=USE_MOCK=true --dart-define=SKIP_LOGIN=true
```

## Opções de build

Passam-se com `--dart-define=NOME=valor`, tanto no `run` como no `build`.

| Opção | Omissão | Para que serve |
| --- | --- | --- |
| `USE_MOCK` | `false` | Usa os dados de `lib/services/dados_de_exemplo.dart` em vez da API. Dá para ver a app toda sem servidor. |
| `SKIP_LOGIN` | `false` | Entra direto no painel, sem passar pelo login. Só faz sentido com `USE_MOCK`. |
| `API_BASE_URL` | emulador | O endereço da API. Sem isto aponta para o `10.0.2.2:3000` do emulador Android. |
| `CARTO_KEY` | vazio | A chave das telas do mapa. **Ver abaixo.** |

### A chave do mapa

Os mapas usam o `flutter_map` com telas do CARTO, as mesmas do site. Desde
outubro de 2026 o CARTO deixou de servir essas telas sem chave: devolve-as com
"API KEY REQUIRED" carimbado por cima.

É a mesma chave que o site tem em `NEXT_PUBLIC_CARTO_KEY`, no `.env.local` do
`website-cleveroption-1`:

```bash
flutter build apk --release --dart-define=CARTO_KEY=<a-chave>
```

Sem ela a app não fica partida: cai no OpenStreetMap, que não precisa de
chave. O mapa fica mais simples, mas legível.

A chave não está escrita no código de propósito, porque este repositório é
público. Numa app ela acaba sempre por ir dentro do pacote e quem quiser
consegue lê-la — quem a protege é a restrição no painel do CARTO, como no
site. O que o `--dart-define` evita é que ela fique no histórico do git.

## Testes

```bash
flutter analyze
flutter test
```

## Mais sobre Flutter

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
