#Requires -Version 5.1
<#
.SYNOPSIS
  화면 설계서 HTML 조각을 합쳐 PDF로 렌더한다.

.DESCRIPTION
  src\p*.html 을 순서대로 이어 붙여 spec.html 을 만들고,
  Edge 또는 Chrome 을 헤드리스로 돌려 PDF 를 뽑는다.

  src\p1.html   CSS + 표지 + 시스템 개요   (닫는 태그 없음 — 여기서 문서가 시작된다)
  src\p2a.html  S-01 ~ S-03
  src\p2b.html  S-04 ~ S-06
  src\p2c.html  S-07 ~ S-13
  src\p3.html   경기 화면 + 오버레이 + 부록  (</body></html> 로 닫는다)

  조각을 나눈 이유는 편집 단위를 작게 두기 위해서다.
  화면 하나를 고치려면 해당 조각만 열면 된다.

.EXAMPLE
  .\build.ps1
  .\build.ps1 -KeepHtml     # 합쳐진 spec.html 을 남긴다
#>
param(
  [switch]$KeepHtml
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }

$srcDir = Join-Path $root "src"
$html   = Join-Path $root "spec.html"
$pdf    = Join-Path $root "ProjectC_화면설계서.pdf"
$order  = @("p1.html", "p2a.html", "p2b.html", "p2c.html", "p3.html")

# ── 1. 조각 잇기 ──────────────────────────────────────────────
$sb = New-Object System.Text.StringBuilder
foreach ($name in $order) {
  $part = Join-Path $srcDir $name
  if (-not (Test-Path $part)) { throw "missing part: $part" }
  [void]$sb.Append((Get-Content $part -Raw -Encoding UTF8))
  [void]$sb.Append("`r`n")
}
# BOM 을 붙여 둔다. 브라우저가 로컬 파일을 열 때 인코딩을 잘못 잡는 것을 막는다.
[System.IO.File]::WriteAllText($html, $sb.ToString(), (New-Object System.Text.UTF8Encoding $true))
Write-Host ("merged {0}  ({1:N0} bytes)" -f (Split-Path $html -Leaf), (Get-Item $html).Length)

# ── 2. 브라우저 찾기 ──────────────────────────────────────────
$candidates = @(
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files\Google\Chrome\Application\chrome.exe",
  "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
)
$browser = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw "Edge or Chrome not found." }
Write-Host ("browser {0}" -f (Split-Path $browser -Leaf))

# ── 3. 렌더 ──────────────────────────────────────────────────
# 프로필 디렉터리를 따로 주지 않으면 이미 떠 있는 브라우저에 붙어서 아무것도 안 한다.
$profile = Join-Path $env:TEMP ("projc-pdf-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$errLog  = Join-Path $env:TEMP "projc-pdf-err.txt"
$uri     = "file:///" + ($html -replace '\\', '/')

# Edge/Chrome 은 --print-to-pdf 경로에 한글이 들어가면 실패한다 (오류 0x7B).
# ASCII 경로로 뽑은 뒤 옮긴다.
$tmpPdf = Join-Path $env:TEMP ("projc-spec-" + [guid]::NewGuid().ToString("N").Substring(0, 8) + ".pdf")

$args = @(
  "--headless=new"
  "--disable-gpu"
  "--user-data-dir=`"$profile`""
  "--no-pdf-header-footer"
  "--print-to-pdf=`"$tmpPdf`""
  "--virtual-time-budget=20000"   # 폰트·레이아웃이 자리 잡을 시간
  "`"$uri`""
)

$proc = Start-Process -FilePath $browser -ArgumentList $args -NoNewWindow -Wait -PassThru -RedirectStandardError $errLog

if (-not (Test-Path $tmpPdf)) {
  Write-Host "render failed. stderr:" -ForegroundColor Red
  if (Test-Path $errLog) { Get-Content $errLog -Tail 20 }
  throw "PDF not produced (exit $($proc.ExitCode))."
}

if (Test-Path $pdf) { Remove-Item $pdf -Force }
Move-Item $tmpPdf $pdf -Force

# ── 4. 검증 ──────────────────────────────────────────────────
$bytes = [System.IO.File]::ReadAllBytes($pdf)
$text  = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
$pages = ([regex]::Matches($text, '/Type\s*/Page[^s]')).Count
if (-not $text.StartsWith("%PDF")) { throw "no PDF header." }
if ($pages -lt 1)                  { throw "could not count pages." }

Write-Host ("done   {0}  {1} pages  {2:N0} bytes" -f (Split-Path $pdf -Leaf), $pages, $bytes.Length) -ForegroundColor Green

# ── 5. 뒷정리 ────────────────────────────────────────────────
try { Remove-Item $profile -Recurse -Force -ErrorAction Stop } catch {}
if (-not $KeepHtml) { Remove-Item $html -Force }
