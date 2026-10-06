# API Contract - Portal Investidor

Este documento define o contrato real da API do backend do Portal Investidor
(Express + Drizzle/Postgres), com base na implementação atual em `src/`.

## Base URL

Definido em `lib/config/api_config.dart`. Pode ser fixado na compilação:

```
flutter run --dart-define=API_BASE_URL=http://<IP_DA_MAQUINA>:3000/api
```

Sem esse valor, cada plataforma usa o seu caminho para o localhost da máquina
de desenvolvimento:

- **Emulador Android**: `http://10.0.2.2:3000/api`
- **iOS, Windows, macOS, Linux e web**: `http://localhost:3000/api`
- **Dispositivo físico**: tem de ser o IP da máquina, via `--dart-define`.

## Headers

### Requests públicos (`/auth/*`)
```
Content-Type: application/json
Accept: application/json
```

### Requests autenticados (`/user/*`, `/project/*`)
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer <token>
```

O token é devolvido por `POST /auth/login` e deve ser guardado pelo cliente
(ex: `shared_preferences`) e enviado em todos os pedidos protegidos.
Pedidos sem o header `Authorization` ou com token inválido/expirado recebem
`401 Unauthorized`.

## Formato de Resposta Padrão

Todas as respostas (sucesso e erro) seguem o mesmo envelope:

```json
{
  "status": 200,
  "message": "Mensagem descritiva",
  "code": "CODIGO_DA_RESPOSTA",
  "data": { /* ou array, ou null/omitido em erros */ }
}
```

Em erros, `data` é normalmente omitido (`undefined`) e, em ambiente de
desenvolvimento (`NODE_ENV=development`), pode incluir um campo extra
`details` com informação adicional (ex: erros de validação do Zod).

## Endpoints

### 1. POST /auth/register

Cria uma nova conta de utilizador.

**Request:**
```json
{
  "primeiroNome": "Guilherme",
  "ultimoNome": "Gonçalves",
  "email": "guilherme@cleveroption.pt",
  "password": "Teste123##"
}
```

**Regras de validação da password** (`schemaRegisto`):
- mínimo 8 caracteres
- pelo menos 1 letra minúscula
- pelo menos 1 letra maiúscula
- pelo menos 1 número
- pelo menos 1 caractere especial entre `@$!%*?&#`

**Response (201 Created):**
```json
{
  "status": 201,
  "message": "Conta criada com sucesso",
  "code": "USER_REGISTERED_SUCCESSFULLY",
  "data": null
}
```

**Response (400 Bad Request) — dados inválidos:**
```json
{
  "status": 400,
  "message": "Dados inválidos",
  "code": "BAD_REQUEST",
  "details": [
    { "field": "password", "message": "Password tem de ter pelo menos 8 caracteres!" }
  ]
}
```

**Response (409 Conflict) — email já registado:**
```json
{
  "status": 409,
  "message": "O endereço: guilherme@cleveroption.pt já está registado!",
  "code": "EMAIL_ALREADY_REGISTERED"
}
```

---

### 2. POST /auth/login

Autenticação de utilizador. Devolve um token JWT que deve ser usado em todos
os pedidos autenticados subsequentes.

**Request:**
```json
{
  "email": "guilherme@cleveroption.pt",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "status": 200,
  "message": "Login bem sucedido",
  "code": "AUTH_LOGIN_SUCCESSFUL",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "email": "guilherme@cleveroption.pt",
      "firstName": "Guilherme",
      "lastName": "Gonçalves"
    }
  }
}
```

O payload decodificado do `token` inclui: `id` (id numérico do utilizador,
usado nos restantes endpoints), `partnerId`, `commercialPartnerId`, `email`,
`role` (`"user"` ou `"admin"`).

**Response (401 Unauthorized) — credenciais inválidas:**
```json
{
  "status": 401,
  "message": "Credenciais inválidas",
  "code": "AUTH_INVALID_CREDENTIALS"
}
```

**Response (400 Bad Request) — dados em falta:**
```json
{
  "status": 400,
  "message": "Dados inválidos",
  "code": "BAD_REQUEST",
  "details": [
    { "field": "email", "message": "Campo Email não pode estar vazio!" }
  ]
}
```

---

### 3. GET /user/{id}

Obtém os dados do investidor autenticado e um resumo dos projetos em que
está associado. Requer `Authorization: Bearer <token>`.

**Request:**
```
GET /user/999
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "status": 200,
  "message": "Dados do utilizador encontrados",
  "code": "USER_DATA_FOUND",
  "data": {
    "userData": [
      {
        "firstName": "Guilherme",
        "lastName": "Gonçalves",
        "email": "guilherme@cleveroption.pt",
        "role": "user"
      }
    ],
    "projects": [
      {
        "id": 101,
        "name": "Empreendimento Central",
        "city": "São João da Madeira",
        "endDate": "2027-12-31",
        "currentStepId": 2,
        "mainImageUrl": "https://images.unsplash.com/photo-1541881430816-17b8f95c37eb?w=800",
        "steps": [
          { "id": 1, "stepOrder": 1, "name": "Projeto", "description": "Aprovado" },
          { "id": 2, "stepOrder": 2, "name": "Fundações", "description": "Executadas" },
          { "id": 3, "stepOrder": 3, "name": "Estrutura", "description": "Em curso" }
        ]
      }
    ]
  }
}
```

**Notas:**
- `userData` é um **array** com, no máximo, um elemento (`SELECT` sem `LIMIT 1`); o cliente deve usar `userData[0]`.
- `projects` é sempre um array (`[]` se o utilizador não tiver projetos associados).
- Cada projeto em `projects.steps` usa a chave `id` (não `stepId`) para o id do passo.
- `mainImageUrl` pode ser `null` se o projeto não tiver imagem principal marcada.
- Este endpoint **não** devolve `totalInvested`, `roiEsperado`, `faturas` nem `createdAt` — esses campos não existem atualmente na base de dados e devem ser tratados como `0.0` / `[]` / ausentes no cliente.

**Response (401 Unauthorized) — token ausente/inválido:**
```json
{
  "status": 401,
  "message": "Acesso negado. Token não fornecido ou formato inválido.",
  "code": "AUTH_MISSING_TOKEN"
}
```
ou, se o token expirou:
```json
{
  "status": 401,
  "message": "Token expirado.",
  "code": "AUTH_TOKEN_EXPIRED"
}
```

**Response (403 Forbidden) — role sem permissão:**
```json
{
  "status": 403,
  "message": "Acesso negado. Privilégios insuficientes.",
  "code": "AUTH_FORBIDDEN"
}
```

---

### 4. GET /project/portfolio

Obtém a lista resumida de todos os projetos da empresa, para o ecrã
"Portfólio". Requer `Authorization: Bearer <token>`.

**Request:**
```
GET /project/portfolio
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "status": 200,
  "message": "Portfólio carregado com sucesso",
  "code": "PORTFOLIO_DATA_FOUND",
  "data": {
    "projects": [
      {
        "id": 1,
        "name": "The Luxor - The Stone Edition",
        "city": "Vila Nova de Gaia",
        "endDate": "2027-12-31",
        "currentStepId": 2,
        "mainImageUrl": "https://framerusercontent.com/images/KN2dkpL3HkRWu6d8vX5TSAnKxs.jpg?width=800",
        "steps": [
          { "id": 1, "stepOrder": 1, "name": "Início de Obra", "description": "Início de Obra" },
          { "id": 2, "stepOrder": 2, "name": "Estrutura em Betão", "description": "Estrutura em Betão" },
          { "id": 3, "stepOrder": 3, "name": "Caixilharia e Fachadas", "description": "Caixilharia e Fachadas" }
        ]
      }
    ]
  }
}
```

**Notas:**
- `projects` é sempre um array (`[]` se não houver projetos).
- `mainImageUrl` pode ser `null` se nenhuma imagem do projeto estiver marcada como `main_image = true`.
- Cada item de `steps` usa a chave `id` (não `stepId`).
- O `id` de cada projeto deve ser usado em `GET /project/details?projectId=<id>` para obter os detalhes completos.

---

### 5. GET /project/details

Detalhes completos de um projeto: informação, etapas, galeria, frações e
acabamentos.

**Rota pública, com autenticação opcional** (`optionalAuth`). Sem token
responde na mesma, mas o **preço das frações vem `null`** — é assim que o site
mostra "Registe-se para ver". Com token válido, os preços vêm preenchidos.

**Request:**
```
GET /project/details?projectId=101
Authorization: Bearer <token>        (opcional)
```

**Response (200 OK):**
```json
{
  "status": 200,
  "message": "Detalhes Projeto",
  "code": "PROJECT_DETAILS_SUCCESS",
  "data": {
    "projectInfo": [
      {
        "name": "The Luxor - The Stone Edition",
        "nFractions": 184,
        "address": "Rua Barão do Corvo",
        "city": "Vila Nova de Gaia",
        "status": "Em Construção",
        "currentStep": 2,
        "description": "Edifício com apartamentos T2 e T1 Smart...",
        "startDate": "2023-03-01",
        "endDate": "2027-12-31",
        "mainImageUrl": "https://.../capa.jpg",
        "descriptionImageUrl": "https://.../conceito.jpg",
        "forSale": true,
        "latitude": 41.1234,
        "longitude": -8.6123,
        "videoUrl": "https://www.youtube.com/watch?v=...",
        "zoneTitle": "Uma vila da Feira, entre o verde e a cidade",
        "zoneDescription": "Canedo é uma vila de Santa Maria da Feira...",
        "zoneNearbyInfrastructures": ["Escolas", "Centro de saúde"],
        "zoneNearbyLocations": [
          { "name": "Porto (centro)", "time": "25–30 min" }
        ]
      }
    ],
    "projectSteps": [
      {
        "id": 1,
        "stepOrder": 1,
        "name": "Início de Obra",
        "description": "Escavação e fundações.",
        "imageUrl": "https://.../obra-inicio.jpg"
      }
    ],
    "projectImages": [
      {
        "imageId": 1,
        "imageUrl": "https://.../fachada.jpg",
        "imageDescription": "Fachada principal",
        "category": "exterior",
        "active": true,
        "sortOrder": 0
      }
    ],
    "projectFractions": [
      {
        "fractionId": 1,
        "projectId": 101,
        "fractionNumber": "G",
        "type": "T1",
        "totalArea": 45.11,
        "garageArea": 12,
        "balconyArea": 1.73,
        "price": null,
        "status": "Disponível",
        "block": 1,
        "floor": "1",
        "orientation": "norte",
        "floorPlanUrl": "https://.../planta-g.pdf"
      }
    ],
    "projectFinishes": [
      {
        "finishId": 1,
        "categoryId": 3,
        "categoryName": "Instalações sanitárias",
        "imageUrl": "https://.../wc.jpg",
        "details": ["Pavimento: ...", "Paredes: ..."]
      }
    ]
  }
}
```

**Notas:**
- `projectInfo` é um **array** (sem `LIMIT 1`); usar `projectInfo[0]`. Se o projeto não existir, vem vazio.
- `currentStep` é um **`stepOrder`**, não o `id` de um passo. Compara-se com `steps[].stepOrder`.
- `projectSteps` usa `id` (igual a `/project/portfolio` e `/user/{id}`).
- **`projectImages[].category`** separa as três galerias: `"exterior"`, `"interior"` e `"obra"`. A de obra é o acompanhamento da construção — antes vinha das fotos dos passos da timeline, agora tem categoria própria. Respeitar `active` (não mostrar as inativas) e `sortOrder` (ordem definida no backoffice).
- **`projectFractions[].price` vem `null` num pedido sem token.** Não é um erro nem zero: é o preço escondido. Mostrar "Registe-se para ver".
- `projectFractions[].floor` é **texto**, não número — há pisos como `"Vale"` ou `"R/C"`.
- `projectFractions[].block` é `null` quando o empreendimento só tem um edifício.
- `projectFinishes` já vem agrupado por categoria, com os itens em `details`.
- `latitude`/`longitude` podem vir a `0` quando o projeto não tem morada marcada — tratar como "sem coordenadas" e não desenhar no mapa.
- `mainImageUrl` pode ser `null`; nesse caso usar a primeira entrada de `projectImages`, ou a imagem que já se tinha do portfólio.

**Response (400 Bad Request) — `projectId` ausente ou inválido:**
```json
{
  "status": 400,
  "message": "ID inválido ou em falta",
  "code": "BAD_REQUEST"
}
```

**Response (200 OK) — projeto inexistente:**

Atualmente, se `projectId` for válido mas não corresponder a nenhum projeto,
o backend devolve `200 OK` com `projectInfo: []`, `projectSteps: []` e
`projectImages: []`. O cliente deve tratar `projectInfo` vazio como
"projeto não encontrado".

---

## Erros Genéricos

### 404 Not Found — rota inexistente
```json
{
  "status": 404,
  "message": "Rota não encontrada",
  "code": "ROUTE_NOT_FOUND"
}
```

### 500 Internal Server Error
```json
{
  "status": 500,
  "message": "Internal server error",
  "code": "INTERNAL_SERVER_ERROR"
}
```
Em desenvolvimento (`NODE_ENV=development`), pode incluir `details` com a
mensagem do erro original.

---

## 6. Documentos

Ambos exigem `Authorization: Bearer <token>`.

### GET /document/list

Faturas do cliente autenticado, com os anexos de cada uma. É o que alimenta o
ecrã "Documentos".

Cada entrada: `id`, `name`, `date`, `paymentState`, `amountTotal` e
`attachments[]` (`id`, `resId`, `name`, `mimetype`, `storeFName`).

`paymentState` vem do Odoo: `paid`, `not_paid`, `partial`, `in_payment`,
`reversed`.

### GET /document/sale-orders

As encomendas do cliente, cada uma com as suas faturas. Traz a ligação ao
empreendimento (`projectName`) e as frações compradas, que a `/document/list`
não tem. É o que o site usa no painel do investidor.

Cada entrada: `id`, `name`, `projectName`, `fractions[]`, `amountTotal`,
`date`, `invoices[]` — e cada fatura com `amountTotal`, `amountResidual`,
`paymentState` e `attachments[]`.

> `amountResidual` só é de confiança em faturas `paid` e `partial`. Nas
> `not_paid` umas trazem o total e outras zero, por isso contam como 0 pago.

---

## Endpoints Desativados

Existem no código da API mas com as rotas **comentadas**
(`src/routes/document.ts`: "desativado temporariamente — TODO: desenvolver
esta parte mais tarde"). Chamá-los dá 404:

- `GET /document/attachment/:id/token` — gerar URL de download temporário
- `GET /document/attachment/:id` — descarregar o anexo

Do lado da app, o código está escrito e trancado atrás de
`ApiConfig.downloadDeAnexosDisponivel`. Quando as rotas voltarem, basta pôr
essa constante a `true`.

---

## Endpoints Planeados (ainda não implementados)

- `POST /tickets` — criar ticket de suporte
- `GET /tickets` — listar tickets do utilizador autenticado
- `GET /notification` — notificações da empresa para o utilizador (ver
  `docs/notificacoes-api.md` no repositório do site)

Quando forem implementados, devem seguir o mesmo envelope `status` /
`message` / `code` / `data` descrito acima, com `data` sempre um array
(`[]` se vazio).

---

## Regras Gerais

1. **Envelope consistente**: toda a resposta (sucesso ou erro) inclui `status`, `message` e `code`; o corpo útil vem em `data`.
2. **Arrays nunca null**: campos de array (`projects`, `projectSteps`, `projectImages`, `userData`, etc.) devem ser `[]` em vez de `null` quando vazios.
3. **Autenticação**: `/user/*` e `/document/*` exigem `Authorization: Bearer <token>`, obtido em `/auth/login`. Tokens expiram (atualmente `1d`). **`/project/*` é público**: `/portfolio` não pede nada e `/details` tem autenticação opcional — o token só serve para revelar o preço das frações.
4. **IDs consistentes entre endpoints**: o `id` devolvido em `/project/portfolio` é o mesmo a usar em `/project/details?projectId=<id>` e corresponde ao `id` de cada projeto em `/user/{id}` (`data.projects[].id`).
5. **Chaves de "step" já uniformes**: `/project/portfolio`, `/user/{id}` e `/project/details` usam todos `id`. (O `stepId` de `/project/details` foi corrigido.)
6. **Números com default**: campos numéricos como `totalInvested`, `roiEsperado`, `valor` (quando existirem) devem ter valor `0.0` se `null`.
7. **Strings com default**: campos de texto devem ter valores padrão descritivos (ex: `"Título não informado"`) quando ausentes.
8. **Datas**: usar formato ISO 8601 ou `YYYY-MM-DD` (campos `date` do Postgres, ex: `startDate`, `endDate`).
9. **Timeout**: o cliente configura um timeout de 10 segundos para todos os requests (`ApiConfig.connectionTimeout`).
