$ErrorActionPreference = 'Stop'

$sourceUrl = 'https://site.fisiotherapy.com.br/guia-completo-de-cuidados-com-pessoa-acamada-seguranca-e-con'
$siteRoot = 'https://site.fisiotherapy.com.br'
$outputRoot = $PSScriptRoot
$assetRoot = Join-Path $outputRoot 'assets'
$imageRoot = Join-Path $assetRoot 'images'

New-Item -ItemType Directory -Path $assetRoot -Force | Out-Null
New-Item -ItemType Directory -Path $imageRoot -Force | Out-Null

$response = Invoke-WebRequest -Uri $sourceUrl -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
$html = $response.Content

# Remove remote executable code, analytics and hydration data. The rendered HTML is complete.
$html = [regex]::Replace($html, '<script\b[^>]*>[\s\S]*?</script>', '', 'IgnoreCase')

# Some static hosts serve directory indexes without redirecting /cuidados to
# /cuidados/. Normalize the URL before the browser resolves relative assets.
$pathNormalization = @'
<script>
if (!location.pathname.endsWith('/') && !/\.[^/]+$/.test(location.pathname)) {
  history.replaceState(null, '', location.pathname + '/' + location.search + location.hash);
}
</script>
'@
$html = $html.Replace('</title>', ("</title>`n" + $pathNormalization))

$styles = @{
  '/assets/index-JyLwpdcb.css' = 'index.css'
  '/assets/PaginaRenderer-B-1YoJeS.css' = 'pagina.css'
}

foreach ($entry in $styles.GetEnumerator()) {
  $remote = $siteRoot + $entry.Key
  $localPath = Join-Path $assetRoot $entry.Value
  Invoke-WebRequest -Uri $remote -OutFile $localPath -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
  $html = $html.Replace($entry.Key, ('assets/' + $entry.Value))
}

# Keep bundled typefaces local as well. CSS lives inside /assets, so root-relative
# font references are rewritten to sibling files.
$fontCssPath = Join-Path $assetRoot 'pagina.css'
$fontCss = [IO.File]::ReadAllText($fontCssPath)
$fontNames = [regex]::Matches($fontCss, 'url\(/assets/([^\)]+\.(?:woff2?|ttf|otf))\)', 'IgnoreCase') |
  ForEach-Object { $_.Groups[1].Value } |
  Sort-Object -Unique
foreach ($fontName in $fontNames) {
  $fontUrl = $siteRoot + '/assets/' + $fontName
  $fontDestination = Join-Path $assetRoot $fontName
  if (-not (Test-Path -LiteralPath $fontDestination)) {
    Invoke-WebRequest -Uri $fontUrl -OutFile $fontDestination -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
  }
}
$fontCss = $fontCss.Replace('url(/assets/', 'url(')
[IO.File]::WriteAllText($fontCssPath, $fontCss, [Text.UTF8Encoding]::new($false))

$assetPattern = '(https://origin\.mentoriaprocesso\.com/[^"''\s<>]+|/mvt/[^"''\s<>]+)'
$remoteAssets = [regex]::Matches($html, $assetPattern, 'IgnoreCase') |
  ForEach-Object { $_.Value } |
  Where-Object { $_ -notmatch '/footer-el_6bba17f9_89a21f-' } |
  Sort-Object -Unique

$usedNames = @{}
foreach ($remoteAsset in $remoteAssets) {
  $absoluteUrl = if ($remoteAsset.StartsWith('/')) { $siteRoot + $remoteAsset } else { $remoteAsset }
  $uri = [Uri]$absoluteUrl
  $fileName = [IO.Path]::GetFileName($uri.AbsolutePath)
  if ([string]::IsNullOrWhiteSpace($fileName)) { continue }

  if ($usedNames.ContainsKey($fileName) -and $usedNames[$fileName] -ne $absoluteUrl) {
    $hash = [BitConverter]::ToString(
      [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($absoluteUrl))
    ).Replace('-', '').Substring(0, 8).ToLowerInvariant()
    $fileName = ([IO.Path]::GetFileNameWithoutExtension($fileName) + '-' + $hash + [IO.Path]::GetExtension($fileName))
  }

  $usedNames[$fileName] = $absoluteUrl
  $destination = Join-Path $imageRoot $fileName
  if (-not (Test-Path -LiteralPath $destination)) {
    Invoke-WebRequest -Uri $absoluteUrl -OutFile $destination -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0'; 'Referer' = $sourceUrl }
  }
  $html = $html.Replace($remoteAsset, ('assets/images/' + $fileName))
}

# Replace the source brand with the original project identity.
$html = [regex]::Replace(
  $html,
  '<img\b[^>]*footer-el_6bba17f9_89a21f[^>]*>',
  '<img src="assets/cuidado-sereno.svg" alt="Cuidado Sereno" class="mx-auto w-auto object-contain pv-imgh-n7g7jr" loading="lazy" decoding="async">',
  'IgnoreCase'
)

# Checkout links are intentionally inert in the local mirror; in-page CTA links still scroll to plans.
$html = [regex]::Replace(
  $html,
  '<a href="https://pay\.hotmart\.com/[^"]+"',
  '<a href="#planos" data-checkout-disabled="true"',
  'IgnoreCase'
)
$html = [regex]::Replace(
  $html,
  '<a href="/cdn-cgi/l/email-protection"[^>]*>[^<]*</a>',
  '<a href="mailto:suporte@fisiotherapy.com.br">suporte@fisiotherapy.com.br</a>',
  'IgnoreCase'
)

$localEnhancements = @'
<style id="local-clone-enhancements">
  html { scroll-behavior: smooth; }
  body { margin: 0; }
  summary::-webkit-details-marker { display: none; }
  [data-checkout-disabled="true"] { cursor: pointer; }
  .local-checkout-note {
    position: fixed; left: 50%; bottom: 22px; z-index: 9999;
    transform: translate(-50%, 24px); opacity: 0; pointer-events: none;
    background: #13243f; color: #fff; border-radius: 999px;
    padding: 11px 18px; font: 600 13px/1.2 Inter, sans-serif;
    box-shadow: 0 12px 30px rgba(0,0,0,.25); transition: .25s ease;
  }
  .local-checkout-note.is-visible { opacity: 1; transform: translate(-50%, 0); }
</style>
<div class="local-checkout-note" role="status" aria-live="polite">Checkout externo desativado nesta cópia local.</div>
<script>
(() => {
  const today = new Intl.DateTimeFormat('pt-BR', {
    timeZone: 'America/Sao_Paulo', day: '2-digit', month: '2-digit', year: 'numeric'
  }).format(new Date());
  document.querySelectorAll('[data-pv-hoje]').forEach((el) => { el.textContent = today; });

  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener('click', (event) => {
      const target = document.querySelector(link.getAttribute('href'));
      if (target) {
        event.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  const note = document.querySelector('.local-checkout-note');
  let noteTimer;
  document.querySelectorAll('[data-checkout-disabled="true"]').forEach((link) => {
    link.addEventListener('click', () => {
      note.classList.add('is-visible');
      clearTimeout(noteTimer);
      noteTimer = setTimeout(() => note.classList.remove('is-visible'), 2600);
    });
  });

  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!reduceMotion && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.animate(
          [{ opacity: .01, transform: 'translateY(18px)' }, { opacity: 1, transform: 'translateY(0)' }],
          { duration: 520, easing: 'cubic-bezier(.2,.7,.2,1)', fill: 'both' }
        );
        observer.unobserve(entry.target);
      });
    }, { threshold: .07 });
    document.querySelectorAll('[id^="secao-"] > section').forEach((section) => observer.observe(section));
  }
})();
</script>
'@

$metaPixelHead = @'
<!-- Meta Pixel Code -->
<script>
!function(f,b,e,v,n,t,s)
{if(f.fbq)return;n=f.fbq=function(){n.callMethod?
n.callMethod.apply(n,arguments):n.queue.push(arguments)};
if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
n.queue=[];t=b.createElement(e);t.async=!0;
t.src=v;s=b.getElementsByTagName(e)[0];
s.parentNode.insertBefore(t,s)}(window, document,'script',
'https://connect.facebook.net/en_US/fbevents.js');
fbq('init', '1087164850898312');
fbq('track', 'PageView');
</script>
<!-- End Meta Pixel Code -->
'@

$metaPixelNoScript = @'
<!-- Meta Pixel Code (noscript) -->
<noscript><img height="1" width="1" style="display:none"
src="https://www.facebook.com/tr?id=1087164850898312&amp;ev=PageView&amp;noscript=1"
/></noscript>
'@

$html = $html.Replace('</head>', ($metaPixelHead + "`n</head>"))
$html = $html.Replace('<body>', ("<body>`n" + $metaPixelNoScript))
$html = $html.Replace('</body>', ($localEnhancements + "`n</body>"))
$html = $html.Replace('noindex, nofollow, noarchive, noimageindex, nosnippet', 'noindex, nofollow')
$html = [regex]::Replace($html, '<link\s+rel="preconnect"[^>]+>', '', 'IgnoreCase')

$outputFile = Join-Path $outputRoot 'index.html'
[IO.File]::WriteAllText($outputFile, $html, [Text.UTF8Encoding]::new($false))

Write-Host "Clone generated at $outputFile"
Write-Host "Downloaded $($usedNames.Count) local image assets."
