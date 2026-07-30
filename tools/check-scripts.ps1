<#
.SYNOPSIS
    프로젝트 내 모든 GDScript 를 파싱 검사한다.

.DESCRIPTION
    Godot 의 `--import` 는 GDScript 파싱 에러를 보고하지 않는다(검증됨).
    프로젝트 전체를 문법 검사하는 CLI 명령도 없으므로, .gd 파일마다
    `--check-only --script` 를 돌린다. Godot 은 파싱 에러 시 종료 코드 1 을
    반환하고 `res://경로:줄번호` 형태로 에러를 출력한다.

    출력은 그대로 통과시켜서 VSCode tasks.json 의 problemMatcher 가
    파싱할 수 있게 한다.

.EXAMPLE
    ./tools/check-scripts.ps1
#>
[CmdletBinding()]
param(
    [string]$Godot = "C:\Users\user\Tools\Godot\godot_console.exe",
    [string]$ProjectPath
)

# $PSScriptRoot 은 param 기본값 위치에서 비어 있을 수 있어 본문에서 해석한다.
if (-not $ProjectPath) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectPath = (Resolve-Path (Join-Path $scriptDir "..")).Path
}

if (-not (Test-Path $Godot)) {
    Write-Error "Godot 실행 파일을 찾을 수 없습니다: $Godot"
    exit 2
}

$scripts = Get-ChildItem -Path $ProjectPath -Filter *.gd -Recurse -File |
    Where-Object { $_.FullName -notmatch '[\\/]\.godot[\\/]' } |
    Where-Object { $_.FullName -notmatch '[\\/]addons[\\/]' } |
    Sort-Object FullName

if ($scripts.Count -eq 0) {
    Write-Host "검사할 .gd 파일이 없습니다."
    exit 0
}

$failed = New-Object System.Collections.Generic.List[string]

foreach ($s in $scripts) {
    $rel = $s.FullName.Substring($ProjectPath.Length).TrimStart('\', '/').Replace('\', '/')

    # stderr 는 이미 캡처되므로 리다이렉트하지 않는다.
    $out = & $Godot --headless --path $ProjectPath --check-only --script $rel | Out-String
    $code = $LASTEXITCODE

    if ($code -ne 0) {
        $failed.Add($rel)
        # 배너 줄은 노이즈라 제외하고 에러 본문만 넘긴다.
        $out -split "`r?`n" |
            Where-Object { $_ -notmatch '^Godot Engine v' -and $_.Trim() -ne '' } |
            ForEach-Object { Write-Host $_ }
    }
}

Write-Host ""
if ($failed.Count -gt 0) {
    Write-Host ("FAILED: {0}/{1} 파일에 파싱 에러가 있습니다." -f $failed.Count, $scripts.Count)
    $failed | ForEach-Object { Write-Host ("  - {0}" -f $_) }
    exit 1
}

Write-Host ("OK: {0}개 스크립트 모두 파싱 통과." -f $scripts.Count)
exit 0
