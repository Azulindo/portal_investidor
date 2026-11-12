# O ícone da app

O ícone é o símbolo do C da Cleveroption, a branco sobre o navy `#002847`.

| Ficheiro | Para quê |
| --- | --- |
| `icone.png` | iOS e Android antigo. 1024 × 1024, com o navy de fundo, porque a Apple não aceita transparência |
| `icone_frente.png` | A frente do ícone adaptativo do Android 8 em diante. 1024 × 1024, transparente, só o símbolo |

Na frente transparente, o símbolo ocupa só metade do lado, de propósito. O
Android recorta o ícone numa forma diferente em cada telemóvel (círculo,
gota, quadrado de cantos redondos), e só o miolo fica garantido. Com mais do
que isto, o C perdia as pontas nalguns telemóveis.

## De onde vêm

Não são desenhadas à mão nem recortadas de uma imagem: saem do logótipo em
vetor (`loja/logo-branco.svg`, o mesmo do site), por isso ficam nítidas em
qualquer tamanho. Para as gerar outra vez, por exemplo se o logótipo mudar:

```powershell
cd portal_investidor-main
powershell -ExecutionPolicy Bypass -File loja\gerar.ps1
dart run flutter_launcher_icons
```

O primeiro comando desenha estes dois ficheiros e as imagens das lojas; o
segundo gera, a partir deles, todos os tamanhos que o Android e o iOS pedem.

## As imagens das lojas

Estão em `loja/`, fora de `assets`, para não irem dentro da app:

- `icone_play_512.png` — o ícone da ficha da Google Play
- `icone_app_store_1024.png` — o ícone da ficha da App Store
- `grafico_destaque_1024x500.png` — o gráfico de destaque da Google Play, com
  o logótipo completo
- `grafico_destaque_1024x500_sem_investimentos.png` — o mesmo, sem a linha
  "Investimentos Imobiliários". A Cleveroption é uma construtora, e a palavra
  "investimentos" na ficha da loja pode levar a Google a tratar a app como
  financeira, que tem regras bastante mais exigentes. Qual usar é decisão da
  empresa.
