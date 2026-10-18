# 安装 long-loop。目录由调用者指定，脚本不默认写入任何代理的 skills 目录。
# 目标目录里缺少的必需技能会装进同一目录。页面才用到的技能不在这里装。
#
#   powershell -File install.ps1
#   powershell -File install.ps1 -Target C:\你的\skills目录
#   powershell -File install.ps1 -Target C:\你的\skills目录 -Link
#   powershell -File install.ps1 -Target C:\你的\skills目录 -SkipDeps
#   powershell -File install.ps1 -Target C:\你的\skills目录 -Uninstall

[CmdletBinding()]
param(
    [string]$Target = "",
    [switch]$Link,
    [switch]$SkipDeps,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Name = "long-loop"
$MattRepo = "https://github.com/mattpocock/skills.git"
$PonytailRepo = "https://github.com/DietrichGebert/ponytail.git"

$Required = @(
    @{ Name = "grill-with-docs"; Source = "matt"; Rel = "skills/engineering/grill-with-docs" },
    @{ Name = "grilling"; Source = "matt"; Rel = "skills/productivity/grilling" },
    @{ Name = "domain-modeling"; Source = "matt"; Rel = "skills/engineering/domain-modeling" },
    @{ Name = "to-spec"; Source = "matt"; Rel = "skills/engineering/to-spec" },
    @{ Name = "to-tickets"; Source = "matt"; Rel = "skills/engineering/to-tickets" },
    @{ Name = "implement"; Source = "matt"; Rel = "skills/engineering/implement" },
    @{ Name = "implement-spec"; Source = "matt"; Rel = "skills/engineering/implement-spec" },
    @{ Name = "tdd"; Source = "matt"; Rel = "skills/engineering/tdd" },
    @{ Name = "code-review"; Source = "matt"; Rel = "skills/engineering/code-review" },
    @{ Name = "pr"; Source = "matt"; Rel = "skills/engineering/pr" },
    @{ Name = "ponytail"; Source = "ponytail"; Rel = "skills/ponytail" }
)

function Search-Roots {
    $homeDir = $env:USERPROFILE
    if (-not $homeDir) { $homeDir = $env:HOME }
    return @(
        (Join-Path $homeDir ".claude/skills"),
        (Join-Path $homeDir ".agents/skills"),
        (Join-Path $homeDir ".cursor/skills"),
        (Join-Path $homeDir ".qoder/skills"),
        (Join-Path $homeDir ".pi/agent/skills"),
        (Join-Path $homeDir ".lingma/skills"),
        (Join-Path $homeDir ".trae/skills")
    )
}

function Choose-Target {
    if ($Target) { return $Target }
    if (-not [Environment]::UserInteractive) {
        throw "非交互运行需要 -Target 目录"
    }
    $roots = Search-Roots
    Write-Host "把 long-loop 安装到哪个目录？脚本没有默认目录。"
    for ($i = 0; $i -lt $roots.Count; $i++) {
        Write-Host ("  {0}) {1}" -f ($i + 1), $roots[$i])
    }
    Write-Host ("  {0}) 输入其他路径" -f ($roots.Count + 1))
    while ($true) {
        $choice = Read-Host ">"
        $n = 0
        if (-not [int]::TryParse($choice, [ref]$n)) { continue }
        if ($n -ge 1 -and $n -le $roots.Count) { return $roots[$n - 1] }
        if ($n -eq $roots.Count + 1) {
            $path = Read-Host "路径"
            if ($path) { return $path }
        }
    }
}

function Install-Tree {
    param([string]$Source, [string]$Dest, [switch]$ForceCopy)
    $Source = (Resolve-Path $Source).Path
    $parent = Split-Path -Parent $Dest
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    if (Test-Path $Dest) {
        Get-ChildItem -LiteralPath $Dest -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $_.Attributes = [System.IO.FileAttributes]::Normal
        }
        Remove-Item -LiteralPath $Dest -Recurse -Force
    }
    if ($Link -and -not $ForceCopy) {
        New-Item -ItemType SymbolicLink -Path $Dest -Target $Source | Out-Null
        Write-Host "✓ 链接 $Dest → $Source"
        return
    }
    Copy-Item -Recurse -Force $Source $Dest
    Write-Host "✓ 复制到 $Dest"
}

function Find-Local {
    param([string]$SkillName)
    $targetFull = (Resolve-Path $Target).Path
    foreach ($root in (Search-Roots)) {
        $candidate = Join-Path $root "$SkillName/SKILL.md"
        if (-not (Test-Path $candidate)) { continue }
        if ((Resolve-Path $root).Path -eq $targetFull) { continue }
        return (Join-Path $root $SkillName)
    }
    return $null
}

$Target = Choose-Target
if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target | Out-Null }
$Target = (Resolve-Path $Target).Path
$dest = Join-Path $Target $Name

if ($Uninstall) {
    if (Test-Path $dest) {
        Get-ChildItem -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $_.Attributes = [System.IO.FileAttributes]::Normal
        }
        Remove-Item -LiteralPath $dest -Recurse -Force
        Write-Host "✓ 已移除 $dest"
    } else {
        Write-Host "! $dest 不存在"
    }
    exit 0
}

$rootFull = (Resolve-Path $Root).Path
if ($rootFull -eq $dest) {
    Write-Host "✓ long-loop 的源目录就是 $dest，跳过自身安装"
} else {
    Install-Tree -Source $Root -Dest $dest
}

if (-not $SkipDeps) {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("long-loop-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    $mattDir = $null
    $ponytailDir = $null
    try {
        foreach ($spec in $Required) {
            $skillDest = Join-Path $Target $spec.Name
            $marker = Join-Path $skillDest "SKILL.md"
            if (Test-Path $marker) {
                Write-Host "✓ 已有 $($spec.Name)"
                continue
            }
            $local = Find-Local $spec.Name
            if ($local) {
                Install-Tree -Source $local -Dest $skillDest
                continue
            }
            if ($spec.Source -eq "matt") {
                if (-not $mattDir) {
                    $mattDir = Join-Path $tmp "matt"
                    Write-Host "✓ 下载 $MattRepo"
                    git clone --depth 1 $MattRepo $mattDir
                    if ($LASTEXITCODE -ne 0) { throw "git clone 失败：$MattRepo" }
                }
                $src = Join-Path $mattDir $spec.Rel
            } else {
                if (-not $ponytailDir) {
                    $ponytailDir = Join-Path $tmp "ponytail"
                    Write-Host "✓ 下载 $PonytailRepo"
                    git clone --depth 1 $PonytailRepo $ponytailDir
                    if ($LASTEXITCODE -ne 0) { throw "git clone 失败：$PonytailRepo" }
                }
                $src = Join-Path $ponytailDir $spec.Rel
            }
            if (-not (Test-Path (Join-Path $src "SKILL.md"))) { throw "仓库里没有 $($spec.Rel)" }
            Install-Tree -Source $src -Dest $skillDest -ForceCopy
        }
    } finally {
        if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    }
} else {
    Write-Host "✓ 已跳过必需技能"
}

Write-Host ""
Write-Host "安装完成：$dest"
Write-Host "页面用到的技能不在这次安装里。运行到那一步、目标目录里没有时再装。"
