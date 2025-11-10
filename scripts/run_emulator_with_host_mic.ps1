param(
    [string]$DeviceId = "emulator-5554",
    [string[]]$FlutterArgs = @()
)

function Get-AdbPath {
    $commandPath = (Get-Command adb -ErrorAction SilentlyContinue)?.Source
    if ($commandPath) {
        return $commandPath
    }

    $sdkRoots = @(
        $env:ANDROID_HOME,
        $env:ANDROID_SDK_ROOT,
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $sdkRoots) {
        $candidate = Join-Path $root 'platform-tools\adb.exe'
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "adb not found. Install Android platform-tools or set ANDROID_HOME / ANDROID_SDK_ROOT."
}

function Invoke-Adb {
    param(
        [string[]]$Arguments
    )

    $adbPath = Get-AdbPath
    & $adbPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "adb command failed: `"$adbPath $($Arguments -join ' ')`""
    }
}

Write-Host "Enabling host microphone input for $DeviceId..." -ForegroundColor Cyan
Invoke-Adb -Arguments @('-s', $DeviceId, 'emu', 'avd', 'hostmicon')

Write-Host "Launching Flutter on $DeviceId..." -ForegroundColor Cyan
$flutterCommand = (Get-Command flutter -ErrorAction SilentlyContinue)?.Source
if (-not $flutterCommand) {
    $flutterRoots = @(
        $env:FLUTTER_HOME,
        (Join-Path $env:USERPROFILE 'flutter')
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $flutterRoots) {
        $candidate = Join-Path $root 'bin\flutter.bat'
        if (Test-Path $candidate) {
            $flutterCommand = $candidate
            break
        }
    }
}

if (-not $flutterCommand) {
    throw "flutter executable not found. Install Flutter or add it to PATH."
}

& $flutterCommand run -d $DeviceId @FlutterArgs

