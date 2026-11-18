# Gera o pacote da app para a Google Play (o ficheiro .aab que se envia).
#
#   $env:CARTO_KEY = "a-chave-do-carto"
#   powershell -ExecutionPolicy Bypass -File loja\gerar_pacote.ps1
#
# Existe para nao se poder gerar um pacote errado. Os dois erros faceis:
#
#  - Esquecer o API_BASE_URL. Sem ele a app nao sabe que ha um servidor de
#    producao e aponta para o emulador (10.0.2.2): vai para a loja e nao
#    funciona em telemovel nenhum.
#  - Esquecer a CARTO_KEY. Os mapas caem no OpenStreetMap sem dar erro
#    nenhum, e ninguem repara ate um cliente abrir o mapa.
#
# A CARTO_KEY nao esta escrita aqui porque o repositorio e publico: entra
# pela variavel de ambiente.
#
# Sem o android/key.properties o pacote sai assinado com a chave de debug, e
# a Play Console recusa-o. Isso so se aceita com -Teste, para experimentar se
# o pacote compila antes de a chave existir.
#
# Com -Apk gera o ficheiro .apk para a pagina /app do site (download direto,
# enquanto a app nao esta na Play Store). Cuidado com a Play App Signing: na
# loja, quem assina a app que chega aos telemoveis e a Google, com a "chave de
# assinatura da app", e nao com a chave do key.properties. Para quem instalou
# pelo site conseguir depois atualizar pela Play Store, ao criar a app na Play
# Console tem de se escolher CARREGAR esta mesma chave como chave de
# assinatura da app (em vez de deixar a Google gerar uma). Depois de a app
# estar na loja, o APK do site deve ser o "APK universal assinado" que se
# descarrega na Play Console (Explorador de app bundles), e nao este.

param(
  [string]$Api = 'https://api.cleveroption.pt/api',
  [switch]$Teste,
  [switch]$Apk
)

$ErrorActionPreference = 'Continue'
$raiz = Split-Path $PSScriptRoot -Parent
Set-Location $raiz

function Parar($msg) { Write-Host "`nERRO: $msg`n" -ForegroundColor Red; exit 1 }

# Versao: o numero depois do + (versionCode) tem de subir a cada envio, mesmo
# que o anterior tenha sido recusado.
$versao = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
Write-Host "Versao: $versao"

if ([string]::IsNullOrWhiteSpace($env:CARTO_KEY)) {
  Parar 'falta a CARTO_KEY. Sem ela os mapas da app caem no OpenStreetMap. Corra antes: $env:CARTO_KEY = "a-chave"'
}

$temChave = Test-Path (Join-Path $raiz 'android\key.properties')
if (-not $temChave -and -not $Teste) {
  Parar 'nao ha android\key.properties, por isso o pacote saia com a chave de debug e a Play Console recusava-o. Ver android\key.properties.exemplo. (Para so experimentar se compila: -Teste)'
}

Write-Host "Servidor: $Api"
Write-Host "A gerar o pacote...`n"
$defines = @("--dart-define=API_BASE_URL=$Api", "--dart-define=CARTO_KEY=$env:CARTO_KEY")
if ($Apk) {
  # Um so APK para todos os telemoveis (sem --split-per-abi): e maior, mas
  # quem descarrega no site nao tem de saber que processador tem.
  flutter build apk --release @defines
} else {
  flutter build appbundle --release @defines
}
if ($LASTEXITCODE -ne 0) { Parar 'o flutter build falhou (ver acima).' }

$pacote = if ($Apk) { Join-Path $raiz 'build\app\outputs\flutter-apk\app-release.apk' } else { Join-Path $raiz 'build\app\outputs\bundle\release\app-release.aab' }
if (-not (Test-Path $pacote)) { Parar "nao encontrei o pacote em $pacote" }

# Quem assinou. O .aab usa a assinatura de JAR, que o keytool le. O .apk pode
# vir so com a assinatura v2/v3, que o keytool nao le: ai usa-se o apksigner.
if ($Apk) {
  $ferramenta = Get-ChildItem "$env:LOCALAPPDATA\Android\Sdk\build-tools\*\apksigner.bat" -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
  $linha = if ($ferramenta) { & $ferramenta verify --print-certs $pacote 2>$null | Select-String 'certificate DN:' | Select-Object -First 1 }
} else {
  $candidatos = @('C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe')
  if ($env:JAVA_HOME) { $candidatos = @(Join-Path $env:JAVA_HOME 'bin\keytool.exe') + $candidatos }
  $ferramenta = $candidatos | Where-Object { Test-Path $_ } | Select-Object -First 1
  $linha = if ($ferramenta) { & $ferramenta -printcert -jarfile $pacote 2>$null | Select-String 'CN=' | Select-Object -First 1 }
}

# Sem conseguir ler a assinatura, nao se diz que esta pronto. Uma versao
# anterior deste script nao encontrava o keytool e aprovava na mesma um
# pacote de debug: a verificacao que falha tem de travar, nao deixar passar.
if (-not $linha) {
  Parar "o pacote foi gerado em $pacote, mas nao consegui ler quem o assinou ($(if ($ferramenta) { $ferramenta } else { 'keytool/apksigner nao encontrado' })). Nao o publique sem confirmar a assinatura."
}
$assinatura = $linha.Line.Trim()
$deDebug = $assinatura -match 'Android Debug'

if ($Apk) {
  # Nome com a versao, para o site e para quem o descarrega saberem qual e.
  $semBuild = ($versao -split '\+')[0]
  $final = Join-Path (Split-Path $pacote) "cleveroption-$semBuild.apk"
  Copy-Item $pacote $final -Force
  $pacote = $final
}

$mb = [math]::Round((Get-Item $pacote).Length / 1MB, 1)
Write-Host "`nPacote:     $pacote ($mb MB)"
Write-Host "Versao:     $versao"
Write-Host "Assinatura: $assinatura"

$destino = if ($Apk) { 'o site' } else { 'a Play Console' }
if ($deDebug -and -not $Teste) { Parar "o pacote saiu assinado com a chave de debug. Nao serve para $destino." }
if ($deDebug) {
  Write-Host "`nPACOTE DE TESTE: compila, mas esta assinado com a chave de debug e NAO serve para $destino." -ForegroundColor Yellow
} elseif ($Apk) {
  Write-Host "`nPronto para o site. Ponha o ficheiro no servidor e defina no site:" -ForegroundColor Green
  Write-Host "  APP_ANDROID_APK_URL=/downloads/$(Split-Path $pacote -Leaf)   (ou o endereco onde o puser)"
  Write-Host "  APP_ANDROID_VERSAO=$semBuild"
  Write-Host "Na proxima versao, suba o numero em pubspec.yaml (os dois, antes e depois do +)."
} else {
  Write-Host "`nPronto para enviar na Play Console. No proximo envio, suba o numero depois do + em pubspec.yaml." -ForegroundColor Green
}
