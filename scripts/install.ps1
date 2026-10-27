[CmdletBinding(DefaultParameterSetName = "ByName")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
    [string[]]$Name,

    [Parameter(Mandatory = $true, ParameterSetName = "AllPublic")]
    [switch]$AllPublic,

    [string]$Destination,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$catalogPath = Join-Path $projectRoot "data\skills.csv"

if (-not (Test-Path -LiteralPath $catalogPath)) {
    throw "Catalog not found: $catalogPath"
}

if (-not $Destination) {
    $codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
    $Destination = Join-Path $codexRoot "skills"
}

$catalog = Import-Csv -LiteralPath $catalogPath
$selected = if ($AllPublic) {
    @($catalog | Where-Object { $_.kind -eq "public-catalog" })
} else {
    @($catalog | Where-Object { $Name -contains $_.name })
}

$missing = if ($AllPublic) { @() } else { @($Name | Where-Object { $_ -notin $selected.name }) }
if ($missing.Count -gt 0) {
    throw "Unknown skill name(s): $($missing -join ', ')"
}

$unsupported = @($selected | Where-Object { $_.kind -ne "public-catalog" })
if ($unsupported.Count -gt 0) {
    foreach ($entry in $unsupported) {
        Write-Warning "$($entry.name) is '$($entry.kind)'. Install it through its official source or Codex plugin '$($entry.plugin)'."
    }
    $selected = @($selected | Where-Object { $_.kind -eq "public-catalog" })
}

if ($selected.Count -eq 0) {
    Write-Host "No public-catalog skills selected."
    exit 0
}

$repoUrl = "https://github.com/composio-community/awesome-codex-skills.git"
$commit = "0930e1373789d2eda449039f7ac154b33031de89"
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("codex-skills-hub-" + [guid]::NewGuid().ToString("N"))

Write-Host "Selected: $($selected.Count) skill(s)"
Write-Host "Destination: $Destination"

if ($DryRun) {
    $selected | Select-Object name, kind, source | Format-Table -AutoSize
    Write-Host "Dry run complete; no files were changed."
    exit 0
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required but was not found on PATH."
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null

try {
    git clone --filter=blob:none --no-checkout $repoUrl $tempRoot
    if ($LASTEXITCODE -ne 0) { throw "Git clone failed." }

    git -C $tempRoot fetch --depth 1 origin $commit
    if ($LASTEXITCODE -ne 0) { throw "Unable to fetch pinned commit $commit." }

    git -C $tempRoot checkout --detach $commit
    if ($LASTEXITCODE -ne 0) { throw "Unable to check out pinned commit $commit." }

    $installed = 0
    $skipped = 0

    foreach ($entry in $selected) {
        $prefix = "$commit/"
        $relativePath = $entry.source.Substring($entry.source.IndexOf($prefix) + $prefix.Length)
        $sourceDirectory = Join-Path $tempRoot ($relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
        $targetDirectory = Join-Path $Destination $entry.name

        if (-not (Test-Path -LiteralPath (Join-Path $sourceDirectory "SKILL.md"))) {
            Write-Warning "Missing SKILL.md upstream: $($entry.name)"
            continue
        }

        if (Test-Path -LiteralPath $targetDirectory) {
            Write-Host "SKIP existing: $($entry.name)"
            $skipped++
            continue
        }

        Copy-Item -LiteralPath $sourceDirectory -Destination $targetDirectory -Recurse
        Write-Host "INSTALLED: $($entry.name)"
        $installed++
    }

    Write-Host "Installed: $installed"
    Write-Host "Skipped existing: $skipped"
    Write-Host "Restart Codex to reload skill metadata."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

