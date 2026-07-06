param(
	[string] $TestsDir = "",
	[int] $TimeoutSeconds = 45,
	[double] $QuitAfterSeconds = 3,
	[string[]] $Include = @(),
	[string[]] $Exclude = @("HeadlessSceneRunner.tscn"),
	[switch] $Recursive
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($TestsDir)) {
	$TestsDir = Join-Path $ProjectRoot "scenes\tests"
}
$ResolvedTestsDir = Resolve-Path $TestsDir
$HeadlessScript = Join-Path $PSScriptRoot "godot_headless.ps1"

$SearchMode = if ($Recursive) { "AllDirectories" } else { "TopDirectoryOnly" }
$Tests = Get-ChildItem -LiteralPath $ResolvedTestsDir -Filter "*.tscn" -File -Recurse:([bool] $Recursive) | Sort-Object FullName
if (-not $Recursive) {
	$Tests = Get-ChildItem -LiteralPath $ResolvedTestsDir -Filter "*.tscn" -File | Sort-Object Name
}

$Failed = @()
$Ran = 0
foreach ($Test in $Tests) {
	if ($Include.Count -gt 0 -and -not ($Include -contains $Test.Name)) {
		continue
	}
	if ($Exclude -contains $Test.Name) {
		continue
	}

	$Relative = $Test.FullName.Substring($ResolvedTestsDir.Path.Length).TrimStart([char[]] @("\", "/"))
	$ScenePath = "res://scenes/tests/" + $Relative.Replace("\", "/")
	Write-Host ("RUN " + $ScenePath)
	& powershell -NoProfile -ExecutionPolicy Bypass -File $HeadlessScript --scene $ScenePath --quit-after $QuitAfterSeconds --timeout-seconds $TimeoutSeconds
	$Exit = $LASTEXITCODE
	if ($Exit -ne 0) {
		$Failed += $ScenePath
	}
	$Ran += 1
}

if ($Ran -eq 0) {
	Write-Error "No scene tests matched the requested filters."
	exit 2
}

if ($Failed.Count -gt 0) {
	Write-Host "FAILED:"
	foreach ($Scene in $Failed) {
		Write-Host $Scene
	}
	exit 1
}

Write-Host ("ALL SCENE TESTS PASSED ({0})" -f $Ran)
exit 0
