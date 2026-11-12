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

param(
  [string]$Api = 'https://api.cleveroption.pt/api',
  [switch]$Teste
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
flutter build appbundle --release "--dart-define=API_BASE_URL=$Api" "--dart-define=CARTO_KEY=$env:CARTO_KEY"
if ($LASTEXITCODE -ne 0) { Parar 'o flutter build falhou (ver acima).' }

$aab = Join-Path $raiz 'build\app\outputs\bundle\release\app-release.aab'
if (-not (Test-Path $aab)) { Parar "nao encontrei o pacote em $aab" }

# Quem assinou. O .aab usa a assinatura de JAR, que o keytool le.
$candidatos = @('C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe')
if ($env:JAVA_HOME) { $candidatos = @(Join-Path $env:JAVA_HOME 'bin\keytool.exe') + $candidatos }
$keytool = $candidatos | Where-Object { Test-Path $_ } | Select-Object -First 1
$linha = if ($keytool) { & $keytool -printcert -jarfile $aab 2>$null | Select-String 'CN=' | Select-Object -First 1 }

# Sem conseguir ler a assinatura, nao se diz que esta pronto. Uma versao
# anterior deste script nao encontrava o keytool e aprovava na mesma um
# pacote de debug: a verificacao que falha tem de travar, nao deixar passar.
if (-not $linha) {
  Parar "o pacote foi gerado em $aab, mas nao consegui ler quem o assinou (keytool: $(if ($keytool) { $keytool } else { 'nao encontrado' })). Nao o envie sem confirmar a assinatura."
}
$assinatura = $linha.Line.Trim()
$deDebug = $assinatura -match 'Android Debug'

$mb = [math]::Round((Get-Item $aab).Length / 1MB, 1)
Write-Host "`nPacote:     $aab ($mb MB)"
Write-Host "Versao:     $versao"
Write-Host "Assinatura: $assinatura"

if ($deDebug -and -not $Teste) { Parar 'o pacote saiu assinado com a chave de debug. A Play Console recusa-o.' }
if ($deDebug) {
  Write-Host "`nPACOTE DE TESTE: compila, mas esta assinado com a chave de debug e NAO serve para a loja." -ForegroundColor Yellow
} else {
  Write-Host "`nPronto para enviar na Play Console. No proximo envio, suba o numero depois do + em pubspec.yaml." -ForegroundColor Green
}
