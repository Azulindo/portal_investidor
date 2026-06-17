# API Contract - Portal Investidor

Este documento define o contrato real da API do backend do Portal Investidor
(Express + Drizzle/Postgres), com base na implementação atual em `src/`.

## Base URL

- **Desenvolvimento (emulador Android)**: `http://10.0.2.2:3000/api`
- **Desenvolvimento (dispositivo físico / rede local)**: `http://<IP_DA_MÁQUINA>:3000/api`
- **Produção**: a definir (`ApiConfig.baseUrlProd`)

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

Obtém os detalhes completos de um projeto específico (info, etapas e
galeria de imagens), para o ecrã de detalhe do projeto. Requer
`Authorization: Bearer <token>`.

**Request:**
```
GET /project/details?projectId=101
Authorization: Bearer <token>
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
        "currentStepId": 2,
        "description": "Edifício com apartamentos T2 e T1 Smart...",
        "startDate": "2023-03-01",
        "endDate": "2027-12-31",
        "mainImageUrl": "https://framerusercontent.com/images/KN2dkpL3HkRWu6d8vX5TSAnKxs.jpg?width=800"
      }
    ],
    "projectSteps": [
      {
        "stepId": 1,
        "stepOrder": 1,
        "name": "Início de Obra",
        "description": "Início de Obra",
        "imageUrl": "https://cleveroption.pt/images/theluxor/obra-inicio.jpg"
      },
      {
        "stepId": 2,
        "stepOrder": 2,
        "name": "Estrutura em Betão",
        "description": "Estrutura em Betão",
        "imageUrl": "https://cleveroption.pt/images/theluxor/obra-estrutura.jpg"
      }
    ],
    "projectImages": [
      {
        "imageId": 1,
        "imageUrl": "https://framerusercontent.com/images/KN2dkpL3HkRWu6d8vX5TSAnKxs.jpg?width=800",
        "imageDescription": "Destaque - Fachada principal do The Luxor"
      },
      {
        "imageId": 2,
        "imageUrl": "https://framerusercontent.com/images/dXdoQc1BRGX8UzfrUaoBivYjjZA.jpg?width=800",
        "imageDescription": "Fachada"
      }
    ]
  }
}
```

**Notas:**
- `projectInfo` é um **array** (sem `LIMIT 1`); o cliente deve usar `projectInfo[0]`. Se o projeto não existir, este array vem vazio.
- `projectSteps` usa a chave **`stepId`** (diferente de `/project/portfolio`, que usa `id`). A imagem associada a cada etapa vem em `imageUrl` e pode ser `null`.
- `projectImages` é a galeria completa de imagens do projeto (capa + restantes), cada entrada com `imageId`, `imageUrl` e `imageDescription` (pode ser `null`).
- `mainImageUrl` em `projectInfo[0]` pode ser `null`; nesse caso o cliente deve fazer fallback para a primeira entrada de `projectImages`, ou para a imagem que já tinha em cache (ex: vinda do portfólio).

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

## Endpoints Planeados (ainda não implementados)

Os seguintes endpoints fazem parte do produto mas **não existem no backend
atual** — não devem ser chamados pelo cliente até serem implementados:

- `POST /tickets` — criar ticket de suporte
- `GET /tickets` — listar tickets do utilizador autenticado

Quando forem implementados, devem seguir o mesmo envelope `status` /
`message` / `code` / `data` descrito acima, com `data` sempre um array
(`[]` se vazio).

---

## Regras Gerais

1. **Envelope consistente**: toda a resposta (sucesso ou erro) inclui `status`, `message` e `code`; o corpo útil vem em `data`.
2. **Arrays nunca null**: campos de array (`projects`, `projectSteps`, `projectImages`, `userData`, etc.) devem ser `[]` em vez de `null` quando vazios.
3. **Autenticação**: todos os endpoints `/user/*` e `/project/*` exigem `Authorization: Bearer <token>`, obtido em `/auth/login`. Tokens expiram (atualmente `1d`).
4. **IDs consistentes entre endpoints**: o `id` devolvido em `/project/portfolio` é o mesmo a usar em `/project/details?projectId=<id>` e corresponde ao `id` de cada projeto em `/user/{id}` (`data.projects[].id`).
5. **Chaves de "step" inconsistentes** (a corrigir no futuro): `/project/portfolio` e `/user/{id}` usam `steps[].id`, enquanto `/project/details` usa `projectSteps[].stepId` para o mesmo conceito (id do passo).
6. **Números com default**: campos numéricos como `totalInvested`, `roiEsperado`, `valor` (quando existirem) devem ter valor `0.0` se `null`.
7. **Strings com default**: campos de texto devem ter valores padrão descritivos (ex: `"Título não informado"`) quando ausentes.
8. **Datas**: usar formato ISO 8601 ou `YYYY-MM-DD` (campos `date` do Postgres, ex: `startDate`, `endDate`).
9. **Timeout**: o cliente configura um timeout de 10 segundos para todos os requests (`ApiConfig.connectionTimeout`).
