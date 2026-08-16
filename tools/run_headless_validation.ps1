<##
Runs the committed Godot validation suite against a local Godot 4.7 console
binary.  The default path matches this repository's local development setup;
pass -GodotExecutable when using another installation.

Example:
    .\tools\run_headless_validation.ps1 -GodotExecutable 'C:\Godot\Godot_v4.7-stable_win64_console.exe'
##>
param(
	[string]$GodotExecutable
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($GodotExecutable)) {
	$GodotExecutable = Join-Path $projectRoot 'work\godot\engine\Godot_v4.7-stable_win64_console.exe'
}

if (-not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) {
	throw "Godot console executable was not found: $GodotExecutable. Supply -GodotExecutable with a Godot 4.7 console binary."
}

# Keep Godot's editor/runtime cache local to the checkout, which makes the
# validation run reproducible on Windows machines with locked-down profiles.
$validationAppData = Join-Path $projectRoot 'work\godot\appdata\roaming'
$validationLocalAppData = Join-Path $projectRoot 'work\godot\appdata\local'
New-Item -ItemType Directory -Force -Path $validationAppData, $validationLocalAppData | Out-Null
$env:APPDATA = $validationAppData
$env:LOCALAPPDATA = $validationLocalAppData

$validations = @(
	@{ Name = 'F0 foundation contracts'; Mode = '--script'; Target = 'res://tests/f0_headless_validation.gd' },
	@{ Name = 'P1 Sterling basic combat'; Mode = '--script'; Target = 'res://tests/p1_headless_validation.gd' },
	@{ Name = 'P2 Sterling kit'; Mode = '--script'; Target = 'res://tests/p2_headless_validation.gd' },
	@{ Name = 'E1 enemy spawn loop'; Mode = '--scene'; Target = 'res://tests/e1_headless_validation.tscn' },
	@{ Name = 'E2 enemy roster'; Mode = '--scene'; Target = 'res://tests/e2_headless_validation.tscn' },
	@{ Name = 'X1 progression'; Mode = '--scene'; Target = 'res://tests/x1_headless_validation.tscn' },
	@{ Name = 'W0 prototype weapons'; Mode = '--scene'; Target = 'res://tests/w0_headless_validation.tscn' },
	@{ Name = 'W1 weapon batch one'; Mode = '--scene'; Target = 'res://tests/w1_headless_validation.tscn' },
	@{ Name = 'W2 weapon batch two'; Mode = '--scene'; Target = 'res://tests/w2_headless_validation.tscn' },
	@{ Name = 'Prototype art'; Mode = '--scene'; Target = 'res://tests/prototype_art_validation.tscn' },
	@{ Name = 'Sterling animation preview'; Mode = '--scene'; Target = 'res://tests/sterling_animation_preview_validation.tscn' },
	@{ Name = 'Prototype combat sandbox'; Mode = '--scene'; Target = 'res://tests/prototype_combat_sandbox_headless_validation.tscn' },
	@{ Name = 'Prototype integration'; Mode = '--scene'; Target = 'res://tests/prototype_playtest_headless_validation.tscn' },
	@{ Name = 'R1 run director'; Mode = '--scene'; Target = 'res://tests/r1_headless_validation.tscn' },
	@{ Name = 'M1 arena and healing'; Mode = '--scene'; Target = 'res://tests/m1_headless_validation.tscn' },
	@{ Name = 'B1 boss'; Mode = '--scene'; Target = 'res://tests/b1_headless_validation.tscn' },
	@{ Name = 'U1 HUD and run flow'; Mode = '--scene'; Target = 'res://tests/u1_headless_validation.tscn' },
	@{ Name = 'META-1 unlock progression'; Mode = '--scene'; Target = 'res://tests/meta_headless_validation.tscn' },
	@{ Name = 'C-RYAN Bruiser kit'; Mode = '--scene'; Target = 'res://tests/c_ryan_headless_validation.tscn' },
	@{ Name = 'C-COOPER Glass Cannon kit'; Mode = '--scene'; Target = 'res://tests/c_cooper_headless_validation.tscn' },
	@{ Name = 'Character roster convergence'; Mode = '--scene'; Target = 'res://tests/character_roster_headless_validation.tscn' },
	@{ Name = 'Late-run performance snapshot'; Mode = '--scene'; Target = 'res://tests/late_run_performance_snapshot.tscn' }
)

foreach ($validation in $validations) {
	Write-Host "`n==> $($validation.Name)"
	& $GodotExecutable --headless --path $projectRoot $validation.Mode $validation.Target
	if ($LASTEXITCODE -ne 0) {
		throw "Validation failed: $($validation.Name)"
	}
}

Write-Host "`nAll Survivor headless validations passed."
