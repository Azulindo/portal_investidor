# Ficha das lojas — textos prontos a colar

Rascunho para o tutor aprovar. Serve as duas lojas (Google Play e App Store),
com os limites de caracteres de cada uma já contados.

## A regra para tudo o que se escreve na loja

A app é o portal de clientes de uma **construtora**. Não se escreve
"investimento", "investidor", "rentabilidade" nem "valorização" em sítio
nenhum: descrição, palavras-chave, legendas das capturas. Descrever a app
como acompanhamento de investimentos faz as lojas tratarem-na como app
financeira, com exigências e revisões muito mais pesadas.

## Nome

**Cleveroption** (12 de 30 caracteres). É o nome que já aparece no telemóvel.

## Subtítulo (só Apple, 30)

**A sua obra, passo a passo** (26)

## Descrição curta (só Google, 80)

**Acompanhe a sua obra, as suas frações e as suas faturas, onde estiver.** (72)

## Descrição completa (4000 nas duas)

> A Cleveroption é uma construtora. Esta é a área reservada aos nossos
> clientes: um sítio só seu para acompanhar o que se passa no imóvel que
> comprou, sem ter de telefonar a perguntar.
>
> **Acompanhe a obra**
> Veja em que fase está a construção, desde o projeto até à entrega, com as
> fotografias de cada etapa. Quando houver novidades, recebe uma notificação.
>
> **As suas frações**
> Consulte as frações que lhe pertencem: tipologia, áreas, piso, orientação e
> a planta.
>
> **Contas em ordem**
> Veja o que já pagou e o que falta pagar, aquisição a aquisição e fatura a
> fatura. Pode pedir uma fatura em falta diretamente da app.
>
> **Os empreendimentos**
> Explore os empreendimentos da Cleveroption no mapa, com galeria de
> fotografias, acabamentos e informação da zona.
>
> **Fale connosco**
> Telefone, email ou WhatsApp, a um toque de distância.
>
> O acesso é reservado a clientes da Cleveroption. Se comprou um imóvel
> connosco e ainda não tem acesso, fale com o seu contacto habitual.

Antes de publicar: confirmar contra a produção que o WhatsApp e o pedido de
fatura funcionam. Prometer na loja o que a app não faz é motivo de rejeição.

## Palavras-chave (só Apple, 100, separadas por vírgulas)

```
construtora,imóvel,obra,empreendimento,frações,faturas,cliente,imobiliário,Porto,Gaia
```

(84) A Google não tem este campo: indexa a descrição.

## Categoria

Google Play: **Negócios**. App Store: **Business**.

## Classificação de conteúdos

4+ na Apple, "Todos" na Google: sem conteúdo sensível, publicidade, compras
nem conteúdo gerado por utilizadores. O questionário responde-se na consola
de cada loja.

## Segurança dos dados (Google) e privacidade (Apple)

| Dado | Para quê | Obrigatório |
| --- | --- | --- |
| Nome | Identificar o cliente no painel | Sim |
| Email | Entrar na conta e recuperar a palavra-passe | Sim |
| Informação financeira (valores das faturas) | Mostrar o pago e o por pagar | Sim |
| Identificador do dispositivo (token de notificações) | Enviar as notificações push | Sim, se aceitar notificações |

Declarar: transmitidos cifrados (HTTPS); não partilhados com terceiros para
publicidade; não usados para seguir o utilizador; a conta pode ser eliminada
(`https://cleveroption.pt/privacidade`, secção "Como apagar a sua conta").
O token de sessão fica no Keystore do Android e no Keychain do iOS.

## Conta de demonstração (Apple, e útil para a Google)

A app é toda atrás de login. Em *App Review Information* vai um email e uma
palavra-passe de uma conta de produção **com dados**: pelo menos um
empreendimento, frações e faturas pagas e por pagar. Pedir ao Miguel.

## Imagens

- Ícones e gráfico de destaque (1024 × 500): já gerados em `loja/`
  (`loja\gerar.ps1`).
- Capturas de ecrã: 5, por esta ordem — o painel, o empreendimento com a
  galeria, as fases da obra, as frações, as faturas. Tirar com
  `flutter run --dart-define=USE_MOCK=true --dart-define=SKIP_LOGIN=true`
  (dados de exemplo, sem servidor). A Google quer pelo menos 1080 px no lado
  maior; a Apple pede um conjunto por tamanho de iPhone (confirmar na App
  Store Connect no dia).
