$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LocalConfig = Join-Path $PSScriptRoot 'camera.local.ps1'
$ExampleConfig = Join-Path $PSScriptRoot 'camera.local.example.ps1'

if (-not (Test-Path -LiteralPath $LocalConfig)) {
    Copy-Item -LiteralPath $ExampleConfig -Destination $LocalConfig
    throw "Edite $LocalConfig com a senha da camera e rode o script novamente."
}

. $LocalConfig

if (-not $CameraIp -or -not $CameraUser -or -not $CameraPass) {
    throw 'CameraIp, CameraUser e CameraPass precisam estar definidos em scripts\camera.local.ps1.'
}

$Go2rtcDir = Join-Path $ProjectRoot 'tools\go2rtc'
$Go2rtcExe = Join-Path $Go2rtcDir 'go2rtc.exe'

if (-not (Test-Path -LiteralPath $Go2rtcExe)) {
    $KnownGo2rtc = 'C:\Users\evald\OneDrive\Área de Trabalho\teste-camera\tools\go2rtc\go2rtc.exe'
    if (Test-Path -LiteralPath $KnownGo2rtc) {
        New-Item -ItemType Directory -Force -Path $Go2rtcDir | Out-Null
        Copy-Item -LiteralPath $KnownGo2rtc -Destination $Go2rtcExe -Force
    } else {
        throw "go2rtc.exe nao encontrado. Coloque o executavel em $Go2rtcExe."
    }
}

$FfmpegCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.2-full_build\bin\ffmpeg.exe'),
    'C:\Program Files\VMS\ffmpeg.exe',
    'C:\Program Files\DownloadHelper CoApp\ffmpeg.exe',
    'ffmpeg'
)

$FfmpegBin = ($FfmpegCandidates | Where-Object {
    $_ -eq 'ffmpeg' -or (Test-Path -LiteralPath $_)
} | Select-Object -First 1)

if (-not $FfmpegBin) {
    throw 'FFmpeg nao encontrado. Instale com: winget install --id Gyan.FFmpeg -e --source winget'
}

$StreamMain = 'camera_xmeye'
$StreamLow = 'camera_xmeye_baixa'
$StreamPublic = 'camera_xmeye_h264'
$PassEncoded = [uri]::EscapeDataString($CameraPass)
$ConfigPath = Join-Path $env:TEMP 'go2rtc-bembarato-camera.yaml'
$OutLog = Join-Path $ProjectRoot 'go2rtc.out.log'
$ErrLog = Join-Path $ProjectRoot 'go2rtc.err.log'

$Config = @"
api:
  listen: "0.0.0.0:$HttpPort"
ffmpeg:
  bin: '$FfmpegBin'
webrtc:
  listen: ":$WebrtcPort"
rtsp:
  listen: "127.0.0.1:$RtspPort"
preload:
  ${StreamMain}: "video"
streams:
  ${StreamMain}:
    - dvrip://${CameraUser}:${PassEncoded}@${CameraIp}:34567?channel=0&subtype=0
  ${StreamLow}:
    - dvrip://${CameraUser}:${PassEncoded}@${CameraIp}:34567?channel=0&subtype=1
  ${StreamPublic}:
    - ffmpeg:${StreamMain}#video=h264#audio=pcma
"@

Set-Content -LiteralPath $ConfigPath -Value $Config -Encoding UTF8

$Running = Get-Process -Name go2rtc -ErrorAction SilentlyContinue

foreach ($Process in $Running) {
    Stop-Process -Id $Process.Id -Force
}

Start-Process -FilePath $Go2rtcExe `
    -ArgumentList @('-config', $ConfigPath) `
    -RedirectStandardOutput $OutLog `
    -RedirectStandardError $ErrLog `
    -WindowStyle Hidden

Start-Sleep -Seconds 3

Write-Host "go2rtc rodando em http://127.0.0.1:$HttpPort/"
Write-Host "Stream publico local: http://127.0.0.1:$HttpPort/stream.html?src=$StreamPublic"
Write-Host "Snapshot local:       http://127.0.0.1:$HttpPort/api/frame.jpeg?src=$StreamPublic"
Write-Host "Logs: $OutLog"
