# Passagem — app Cleveroption

Para quem pega na app depois do Azulindo (estagiário, estágio terminado em
novembro de 2026). Diz em que estado a app ficou, o que falta, e como a pôr
no site e nas lojas. As regras do código estão no `AGENTS.md`; o contrato com
a API no `portal_investidor-main/API_CONTRACT.md`; os textos das lojas em
`portal_investidor-main/loja/FICHA_DA_LOJA.md`.

Escrito a 18 de novembro de 2026. Se alguma coisa aqui deixar de ser verdade,
corrija este ficheiro.

---

## Em que estado está

- **App Flutter para Android e iOS**, ramo `api-alinhada` do repositório
  `Azulindo/portal_investidor` (público). `flutter analyze` limpo e 276 testes
  a passar. Testada num Samsung A35 contra a API de produção.
- Identificador **`pt.cleveroption.app`** (Android e iOS). Definitivo: o
  Firebase está registado com ele, e mudá-lo depois de publicar é publicar
  uma app nova.
- Versão **1.0.0+1**. Ainda não está em loja nenhuma.
- A API é a do Miguel: `https://api.cleveroption.pt/api`.

O que a app faz: login e sessão (renovação automática), painel "Os Seus
Imóveis" igual à área reservada do site, página de cada empreendimento
(galeria, fases da obra, frações com ficha, acabamentos, mapa, vídeo),
portfólio e "Em comercialização", mapa com filtros, faturas e documentos,
notificações (sininho e push), alterar palavra-passe, contactos e privacidade.

---

## Coisas que não estão no repositório (e onde estão)

O repositório é público, por isso nada disto pode lá entrar. **Pedir ao
Azulindo em mão ou por pasta partilhada da empresa — nunca por email ou
WhatsApp.**

| O quê | Para que serve | Onde está |
| --- | --- | --- |
| `upload-keystore.jks` + palavra-passe | Assinar a app. **Perdê-la é deixar de poder atualizar a app na Play Store.** | No PC do Azulindo, em `C:\Cleveroption-chave\`. Criada a 18/11/2026 com `CN=David Tavares, O=Cleveroption, L=Gaia, C=PT`, alias `upload`. Guardar no gestor de palavras-passe da empresa e ter uma segunda cópia. |
| `android/key.properties` | Diz ao Gradle onde está a chave e a palavra-passe. | Criar a partir de `android/key.properties.exemplo`. |
| `android/app/google-services.json` | Notificações push. | Consola do Firebase, projeto `cleveroption-df8f8`, app `pt.cleveroption.app`. |
| `CARTO_KEY` | Mapas (sem ela caem no OpenStreetMap). | Conta CARTO; o Azulindo tem o valor. Passa-se por variável de ambiente, nunca escrita no código. |
| Chave da conta de serviço do Firebase | O servidor enviar os push. | **Só no servidor da API** (Miguel). Nunca na app nem no repositório. |

---

## Gerar a app

```powershell
cd portal_investidor-main
$env:CARTO_KEY = "a-chave-do-carto"
powershell -ExecutionPolicy Bypass -File loja\gerar_pacote.ps1        # .aab para a Play Store
powershell -ExecutionPolicy Bypass -File loja\gerar_pacote.ps1 -Apk   # .apk para a página /app do site
```

O script põe o servidor de produção e a CARTO_KEY, e **recusa** um pacote
sem `key.properties` (sairia com a chave de debug) ou sem
`google-services.json` (sairia sem push). No fim mostra quem assinou: tem de
dizer `CN=David Tavares`.

**Em cada versão nova**, subir o número em dois sítios, que um teste obriga a
estarem iguais: `version:` no `pubspec.yaml` (os dois números, antes e
depois do `+`; o de depois tem de subir sempre, a Google recusa um repetido)
e `lib/config/versao_app.dart`.

Instalar num telemóvel ligado por cabo: `adb install -r --user 0 <apk>`. Um
APK com outra assinatura (por exemplo de debug) não atualiza por cima: é
preciso desinstalar primeiro.

---

## Pôr a app no site (Android, antes da Play Store)

O site (`website-cleveroption-1`, ramo `Gui` do Azulindo) já tem a página
`/app` com o botão de download, e a rota `/api/app-versao` que a app consulta
para avisar quem tem uma versão antiga. Falta:

1. Juntar o ramo `Gui` ao `main` do site (combinar com o Miguel).
2. Pôr o `.apk` no servidor do site, por exemplo em `public/downloads/`
   (o `.apk` não vai para o git).
3. No servidor do site, definir:
   ```
   APP_ANDROID_APK_URL=/downloads/cleveroption-1.0.0.apk
   APP_ANDROID_VERSAO=1.0.0
   ```
4. Em cada versão nova: novo `.apk`, e mudar as duas variáveis. A app
   instalada avisa sozinha "Há uma versão nova".

Quando a app estiver na Play Store, define-se `APP_PLAY_STORE_URL` e o botão
passa a apontar para a loja (que atualiza sozinha).

No iPhone não há como instalar a app pelo site, só pela App Store. Até lá, a Área Reservada do site pode ir para o ecrã principal (Safari → Partilhar → Adicionar ao ecrã principal) e, a partir do iOS 16.4, recebe as mesmas notificações push: está no site (`app/manifest.ts`, `public/sw.js`, `components/AtivarNotificacoes.tsx`), com as variáveis `NEXT_PUBLIC_FIREBASE_*` definidas antes do build. Precisa de a API aceitar `"web"` no `DEVICE_PLATFORMS`.

---

## Pôr a app nas lojas

**Começar pelas contas, porque é o que demora** (dias a semanas):

| | Google Play | Apple |
| --- | --- | --- |
| Custo | 25 USD, uma vez | 99 USD por ano |
| Tipo | Conta de **organização** (não pessoal) | Conta de **organização** |
| Precisa de | Verificação da empresa | Número **D-U-N-S** da empresa (gratuito, mas lento) |

Contas de organização por duas razões: a app é da empresa e não de quem a
desenvolve; e uma conta pessoal nova na Google Play tem de fazer 14 dias de
teste fechado com 12 testers antes de poder publicar.

### Android

1. Criar a app na Play Console: português (Portugal), **gratuita** (não se
   pode passar a paga depois).
2. **Play App Signing: carregar a NOSSA chave** (`upload-keystore.jks`) como
   chave de assinatura da app, em vez de deixar a Google criar uma. Senão
   quem instalou pelo site não consegue atualizar pela loja.
3. Gerar o `.aab` com `loja\gerar_pacote.ps1` e enviá-lo para um **teste
   interno** primeiro.
4. Ficha da loja, classificação de conteúdos, segurança dos dados: textos e
   respostas em `loja/FICHA_DA_LOJA.md`. Ícones e gráfico de destaque já
   estão em `loja/` (gerados por `loja\gerar.ps1`).
5. A política de privacidade é `https://cleveroption.pt/privacidade` (já tem
   "Como apagar a sua conta" e as notificações). **O site tem de estar no ar
   antes de submeter.**

### iOS

- **Precisa de um Mac** (ou do Codemagic pago: há um `codemagic.yaml` na
  raiz, que hoje só faz um build não assinado).
- Registar o Bundle ID `pt.cleveroption.app`, certificados, TestFlight.
- Push no iPhone: chave APNs da conta Apple carregada no Firebase, o
  `GoogleService-Info.plist`, e as capabilities no Xcode.
- **A Apple exige uma conta de demonstração** com dados para a revisão
  (pedir ao Miguel). Sem ela a app é rejeitada à primeira.

---

## O que falta, e de quem

| Falta | De quem |
| --- | --- |
| Receber a chave de assinatura e guardá-la (2 cópias) | Tutor, do Azulindo |
| Convite de **Proprietário** no Firebase (`cleveroption-df8f8`) para uma conta da empresa | Azulindo convida, empresa aceita |
| Contas Google Play e Apple de organização; D-U-N-S | Empresa |
| Aprovar os textos da ficha e o email de suporte (fica público) | Tutor |
| Juntar o ramo `Gui` do site ao `main` e pôr no ar | Azulindo/Miguel |
| Conta de demonstração com dados | Miguel |
| `invoice_date_due` nas faturas (data de vencimento) | Miguel |
| Aceitar `"web"` no `DEVICE_PLATFORMS` (notificações no atalho do iPhone) | Miguel |
| Opcional: mandar o `href` no `data` dos push (hoje a app vai buscá-lo) | Miguel |
| Mac ou Codemagic pago, para o iOS | Orçamento |

### Na app, se houver tempo

- Biometria: adiada por decisão (o `local_auth` está no pubspec, sem uso).
- `flutter_local_notifications` está fixo na 22: a 23 exige o SDK 37, que o
  AGP 8.11 não conhece. Subir quando se subir o AGP.
- A ficha da fração e o ecrã das faturas ainda estão no navy; o painel e o
  empreendimento já estão claros, como o site (ver "Zona clara" no
  `AGENTS.md`).

---

## Para o Claude de quem pegar nisto

- Lê o `AGENTS.md` antes de mexer: tem as decisões fechadas e as armadilhas.
- Os caminhos `C:\site_teste\...` no `AGENTS.md` são do PC do Azulindo.
- Nunca escrevas a `CARTO_KEY`, palavras-passe ou o conteúdo do
  `key.properties` em ficheiros do repositório, em commits ou na conversa.
  Antes de cada commit, confirma que não vai nenhum `google-services.json`,
  `*.jks`, `key.properties`, `.apk` ou `.env`.
- Não faças push nem commit sem pedir.
