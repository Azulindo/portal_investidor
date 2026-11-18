# Gera o icone da app e as imagens das fichas das lojas, a partir do logotipo
# em vetor (logo-branco.svg, o mesmo do site).
#
#   powershell -ExecutionPolicy Bypass -File loja\gerar.ps1
#
# Desenha com o Edge, que ja vem no Windows: assim nao e preciso instalar nada.
# Sai sempre nitido em qualquer tamanho, porque parte do vetor e nao de uma
# imagem. Depois de correr, falta gerar os tamanhos da app:
#
#   dart run flutter_launcher_icons

$ErrorActionPreference = 'Continue'
$raiz = Split-Path $PSScriptRoot -Parent
$tmp = Join-Path $env:TEMP 'co-icone'
New-Item -ItemType Directory -Force $tmp | Out-Null
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edge)) { $edge = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$svg = Get-Content (Join-Path $PSScriptRoot 'logo-branco.svg') -Raw
$todos = [regex]::Matches($svg, '<path [^>]*?d="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
# Os quatro primeiros caminhos sao o simbolo do C; o resto e o nome escrito.
$simbolo = $todos[0..3]
# O nome sem a linha "Investimentos Imobiliarios", que no desenho comeca
# abaixo de y=127.
$nome = $todos[4..($todos.Count - 1)] | Where-Object {
  [double]([regex]::Match($_, '^M[\d.]+,([\d.]+)').Groups[1].Value) -lt 127
}

# Desenha [caminhos] a branco, centrados, a ocupar [fracao] do lado menor.
function Desenhar($destino, $caminhos, $largura, $altura, $fracao, $fundo) {
  $p = ($caminhos | ForEach-Object { "<path d=`"$_`"/>" }) -join ''
  $html = @"
<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;padding:0;overflow:hidden;background:$fundo;width:${largura}px;height:${altura}px}
svg{display:block}
</style></head><body>
<svg id="s" xmlns="http://www.w3.org/2000/svg" width="$largura" height="$altura"><g id="g" fill="#ffffff">$p</g></svg>
<script>
const g=document.getElementById('g'), s=document.getElementById('s');
const b=g.getBBox(), W=$largura, H=$altura, f=$fracao;
const k=Math.min(W*f/b.width, H*f/b.height), vw=W/k, vh=H/k;
s.setAttribute('viewBox', (b.x+b.width/2-vw/2)+' '+(b.y+b.height/2-vh/2)+' '+vw+' '+vh);
</script></body></html>
"@
  $pagina = Join-Path $tmp 'pagina.html'
  Set-Content -Path $pagina -Value $html -Encoding UTF8
  if (Test-Path $destino) { Remove-Item $destino }
  & $edge --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 `
    --default-background-color=00000000 --window-size="$largura,$altura" `
    --screenshot="$destino" "file:///$($pagina.Replace('\','/'))" 2>$null | Out-Null
  Write-Output "  $destino"
}

$icon = Join-Path $raiz 'assets\icon'
$loja = $PSScriptRoot

# O icone, sobre o navy: iOS (que recusa transparencia) e o icone antigo do
# Android. O simbolo ocupa 58% do lado.
Desenhar (Join-Path $icon 'icone.png') $simbolo 1024 1024 0.58 '#002847'
# A frente do icone adaptativo do Android: so o simbolo, transparente, a 50%.
# O sistema recorta o icone em circulo, gota ou quadrado, e so o miolo esta
# garantido; com mais do que isto o C perdia as pontas nalguns telemoveis.
Desenhar (Join-Path $icon 'icone_frente.png') $simbolo 1024 1024 0.50 'transparent'

# O simbolo dentro dos pinos do mapa: branco, transparente, quase a ocupar o
# quadrado. Era um .avif, que o Flutter nao desenha em todo o lado (no browser
# os pinos ficavam vazios); PNG desenha em todos.
Desenhar (Join-Path $raiz 'assets\images\simbolo_mapa.png') $simbolo 128 128 0.92 'transparent'

# O icone pequeno das notificacoes push, na barra do Android: branco sobre
# transparente (o sistema so usa a transparencia). Um por densidade de ecra,
# 24dp com 2dp de margem de cada lado.
$res = Join-Path $raiz 'android\app\src\main\res'
foreach ($d in @(@('mdpi', 24), @('hdpi', 36), @('xhdpi', 48), @('xxhdpi', 72), @('xxxhdpi', 96))) {
  $pasta = Join-Path $res "drawable-$($d[0])"
  New-Item -ItemType Directory -Force $pasta | Out-Null
  Desenhar (Join-Path $pasta 'ic_notificacao.png') $simbolo $d[1] $d[1] 0.83 'transparent'
}

# Fichas das lojas.
Desenhar (Join-Path $loja 'icone_app_store_1024.png') $simbolo 1024 1024 0.58 '#002847'
Desenhar (Join-Path $loja 'icone_play_512.png') $simbolo 512 512 0.58 '#002847'
Desenhar (Join-Path $loja 'grafico_destaque_1024x500.png') $todos 1024 500 0.62 '#002847'
Desenhar (Join-Path $loja 'grafico_destaque_1024x500_sem_investimentos.png') (@($simbolo) + @($nome)) 1024 500 0.62 '#002847'
