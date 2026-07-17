param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]] $GodotArgs
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$GodotExe = $env:GODOT_EXE
if ([string]::IsNullOrWhiteSpace($GodotExe) -or -not (Test-Path -LiteralPath $GodotExe)) {
	$GodotExe = @(
		"H:\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe",
		"E:\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe"
	) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($GodotExe)) {
	$GodotExe = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue |
		Where-Object { -not [string]::IsNullOrWhiteSpace($_.Path) } |
		Select-Object -First 1 -ExpandProperty Path
}
if ([string]::IsNullOrWhiteSpace($GodotExe) -or -not (Test-Path -LiteralPath $GodotExe)) {
	Write-Error "Godot executable not found. Set GODOT_EXE or update tools/godot_headless.ps1."
	exit 127
}
$LogDir = Join-Path $ProjectRoot ".godot\headless_logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
$LogFile = Join-Path $LogDir "godot_$Stamp.log"

$AllowLoggedErrors = $false
$TimeoutSeconds = 30
$CleanGodotArgs = @()
$SceneArgIndex = -1
$ScenePath = $null
$QuitAfterArgIndex = -1
$QuitAfterSeconds = $null
$VerboseRequested = $false
for ($i = 0; $i -lt $GodotArgs.Count; $i++) {
	$Arg = $GodotArgs[$i]
	if ($Arg -eq "--allow-logged-errors") {
		$AllowLoggedErrors = $true
	} elseif ($Arg -eq "--verbose") {
		$VerboseRequested = $true
	} elseif ($Arg -eq "--timeout-seconds" -and $i + 1 -lt $GodotArgs.Count) {
		$TimeoutSeconds = [int] $GodotArgs[$i + 1]
		$i++
	} elseif ($Arg -eq "--scene" -and $i + 1 -lt $GodotArgs.Count) {
		$SceneArgIndex = $CleanGodotArgs.Count
		$ScenePath = $GodotArgs[$i + 1]
		$CleanGodotArgs += $Arg
		$CleanGodotArgs += $ScenePath
		$i++
	} elseif ($Arg -eq "--quit-after" -and $i + 1 -lt $GodotArgs.Count) {
		$QuitAfterArgIndex = $CleanGodotArgs.Count
		$QuitAfterSeconds = [double] $GodotArgs[$i + 1]
		$CleanGodotArgs += $Arg
		$CleanGodotArgs += $GodotArgs[$i + 1]
		$i++
	} else {
		$CleanGodotArgs += $Arg
	}
}

if ($SceneArgIndex -ge 0 -and $QuitAfterArgIndex -ge 0 -and $ScenePath -ne "res://scenes/tests/HeadlessSceneRunner.tscn") {
	$CleanGodotArgs = @()
	$CleanGodotArgs += "--scene"
	$CleanGodotArgs += "res://scenes/tests/HeadlessSceneRunner.tscn"
	$CleanGodotArgs += "--"
	$CleanGodotArgs += "--headless-runner-scene"
	$CleanGodotArgs += $ScenePath
	$CleanGodotArgs += "--headless-runner-quit-after"
	$CleanGodotArgs += ([string] $QuitAfterSeconds)
}

$ProcessArgs = @("--disable-crash-handler", "--headless")
if ($VerboseRequested) {
	$ProcessArgs += "--verbose"
}
$ProcessArgs += @("--log-file", $LogFile, "--path", $ProjectRoot)
$ProcessArgs += $CleanGodotArgs
$EscapedArgs = @()
foreach ($Arg in $ProcessArgs) {
	$EscapedArgs += '"' + ([string] $Arg).Replace('\', '\\').Replace('"', '\"') + '"'
}

$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
$ProcessInfo.FileName = $GodotExe
$ProcessInfo.UseShellExecute = $false
$ProcessInfo.Arguments = $EscapedArgs -join " "
$Process = [System.Diagnostics.Process]::Start($ProcessInfo)
$Exited = $Process.WaitForExit($TimeoutSeconds * 1000)
if (-not $Exited) {
	$Process.Kill()
	$Process.WaitForExit()
	Write-Error "Godot headless timed out after $TimeoutSeconds seconds." -ErrorAction Continue
	exit 124
}
$ExitCode = [int] $Process.ExitCode

if ($ExitCode -eq 0 -and -not $AllowLoggedErrors -and (Test-Path -LiteralPath $LogFile)) {
	$LogText = Get-Content -LiteralPath $LogFile -Raw
	if ($LogText -match "(?m)^(SCRIPT ERROR|ERROR):") {
		$ExitCode = 1
	}
	if ($LogText -match "ObjectDB instances leaked") {
		$ExitCode = 1
	}
}

exit $ExitCode
