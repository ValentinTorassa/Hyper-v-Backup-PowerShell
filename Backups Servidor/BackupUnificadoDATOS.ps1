################################################################################
# Script: BackupDATOS-Unificado.ps1
# Objetivo: Ejecutar un backup diario de la carpeta "D:\Maquinas Virtuales", 
#           comprimirlo primero en un disco local (staging), 
#           luego enviar el .zip a DOS destinos (USB y carpeta de contingencia),
#           y eliminar respaldos con más de 8 días en ambos destinos.
#           Generar un log con el resultado del proceso.
# Autor: Valentin Torassa Colombero
################################################################################

# --- Variables de configuración ---

# Carpeta de origen
$SourceFolder = "D:\Maquinas Virtuales"

# Staging local
$LocalStagingPath = "D:\USBTempBackupDATOS"

# Destino 1 
$BackupPathUSB = "E:\BackupUSBDATOS"

# Destino 2 
$BackupPathNetwork = "\\Srvg10pus\solo copia de backups\BackupDATOS"

# Log principal
$LogFile = "D:\USBTempBackupDATOS\BackupLogDATOS.txt"

# Ruta ejecutable 7-Zip
$SevenZipExe = "C:\Program Files\7-Zip\7z.exe"

Add-Content $LogFile "--------------------------------------"
Add-Content $LogFile "$(Get-Date): Iniciando script de backup DATOS unificado."
Add-Content $LogFile "--------------------------------------"

# --- Verificación de carpetas ---

# 1) Staging local
if (!(Test-Path $LocalStagingPath)) {
    try {
        New-Item -Path $LocalStagingPath -ItemType Directory -ErrorAction Stop | Out-Null
    } catch {
        Add-Content $LogFile "$(Get-Date): ERROR - No se pudo crear la carpeta staging $LocalStagingPath. $_"
        Write-Host "ERROR: No se pudo crear $LocalStagingPath. Revise permisos o la ruta."
        Exit 1
    }
}

# 2) Destino USB
if (!(Test-Path $BackupPathUSB)) {
    try {
        New-Item -Path $BackupPathUSB -ItemType Directory -ErrorAction Stop | Out-Null
    } catch {
        Add-Content $LogFile "$(Get-Date): ERROR - No se pudo crear la carpeta USB $BackupPathUSB. $_"
        Write-Host "ERROR: No se pudo crear $BackupPathUSB. Revise permisos o la ruta."
        Exit 1
    }
}

# 3) Destino Red
if (!(Test-Path $BackupPathNetwork)) {
    try {
        New-Item -Path $BackupPathNetwork -ItemType Directory -ErrorAction Stop | Out-Null
    } catch {
        Add-Content $LogFile "$(Get-Date): ERROR - No se pudo crear la carpeta de red $BackupPathNetwork. $_"
        Write-Host "ERROR: No se pudo crear $BackupPathNetwork. Revise permisos o la ruta."
        Exit 1
    }
}

# 4) Carpeta de origen
if (!(Test-Path $SourceFolder)) {
    Add-Content $LogFile "$(Get-Date): ERROR - La carpeta de origen $SourceFolder no existe."
    Write-Host "ERROR: La carpeta de origen no existe. Verifique la ruta."
    Exit 1
}

# --- Preparación del nombre y carpeta temporal ---
$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"

$DestinationFolderLocal = Join-Path $LocalStagingPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolderLocal | Out-Null

Write-Host "Iniciando respaldo de $SourceFolder --> $DestinationFolderLocal ..."
robocopy $SourceFolder $DestinationFolderLocal /E /R:3 /W:5

# Verifica resultado robocopy
if ($LASTEXITCODE -gt 1) {
    Add-Content $LogFile "$(Get-Date): ERROR - Falló la copia con Robocopy. Código: $LASTEXITCODE."
    Write-Host "ERROR: Falló la copia de $SourceFolder. Verifique el log."
    Exit 1
} else {
    Add-Content $LogFile "$(Get-Date): Copia realizada exitosamente desde $SourceFolder a $DestinationFolderLocal."
}

# --- Compresión con 7-Zip ---
$ZipFileName = "$BackupName.zip"
$ZipFilePathLocal = Join-Path $LocalStagingPath $ZipFileName

Write-Host "Comprimiendo carpeta localmente en: $ZipFilePathLocal ..."

& "$SevenZipExe" 'a' '-tzip' "`"$ZipFilePathLocal`"" "`"$DestinationFolderLocal\*`"" -r -bsp1 -mx1

if ($LASTEXITCODE -eq 0) {
    Add-Content $LogFile "$(Get-Date): Carpeta comprimida exitosamente en $ZipFilePathLocal."
    Write-Host "Carpeta comprimida correctamente."

    # Elimina la carpeta local sin comprimir
    Remove-Item -Recurse -Force $DestinationFolderLocal
    Add-Content $LogFile "$(Get-Date): Carpeta temporal eliminada ($DestinationFolderLocal)."
} else {
    Add-Content $LogFile "$(Get-Date): ERROR - Falló la compresión con 7-Zip. Código: $LASTEXITCODE."
    Write-Host "ERROR: Falló la compresión. Verifique el log."
    Exit 1
}

# --- Copiar el .zip resultante a ambos destinos ---

# 1) Destino USB
$FinalZipPathUSB = Join-Path $BackupPathUSB $ZipFileName
Write-Host "Copiando el .zip al destino USB: $FinalZipPathUSB ..."
try {
    Copy-Item -Path $ZipFilePathLocal -Destination $FinalZipPathUSB -Force
    Add-Content $LogFile "$(Get-Date): Archivo ZIP copiado a (USB) $FinalZipPathUSB."
} catch {
    Add-Content $LogFile "$(Get-Date): ERROR - No se pudo copiar el archivo .zip a (USB) $FinalZipPathUSB. $_"
    Write-Host "ERROR: No se pudo copiar el archivo .zip al USB. Revise permisos o la ruta."
}

# 2) Destino Red
$FinalZipPathNetwork = Join-Path $BackupPathNetwork $ZipFileName
Write-Host "Copiando el .zip al destino de red: $FinalZipPathNetwork ..."
try {
    Copy-Item -Path $ZipFilePathLocal -Destination $FinalZipPathNetwork -Force
    Add-Content $LogFile "$(Get-Date): Archivo ZIP copiado a (Red) $FinalZipPathNetwork."
} catch {
    Add-Content $LogFile "$(Get-Date): ERROR - No se pudo copiar el archivo .zip a (Red) $FinalZipPathNetwork. $_"
    Write-Host "ERROR: No se pudo copiar el archivo .zip a la red. Verifique permisos o la ruta."
}

# (Opcional) Elimina el .zip local para no dejarlo en staging
try {
    Remove-Item $ZipFilePathLocal -Force
    Add-Content $LogFile "$(Get-Date): Archivo ZIP local ($ZipFilePathLocal) eliminado."
} catch {
    Add-Content $LogFile "$(Get-Date): ADVERTENCIA - No se pudo eliminar el ZIP local $ZipFilePathLocal. $_"
    Write-Host "WARNING: No se pudo eliminar el ZIP local. Puede quedar espacio ocupado en staging."
}

# --- Limpieza de respaldos antiguos en ambos destinos (8 días) ---

Write-Host "Eliminando respaldos .zip con más de 8 días en USB: $BackupPathUSB ..."
Get-ChildItem -Path $BackupPathUSB -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Add-Content $LogFile "$(Get-Date): Respaldos antiguos eliminados (más de 8 días) en $BackupPathUSB."

Write-Host "Eliminando respaldos .zip con más de 8 días en Red: $BackupPathNetwork ..."
Get-ChildItem -Path $BackupPathNetwork -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Add-Content $LogFile "$(Get-Date): Respaldos antiguos eliminados (más de 8 días) en $BackupPathNetwork."

Add-Content $LogFile "$(Get-Date): Script completado exitosamente."
Write-Host "La tarea ha finalizado. Revise el log para más detalles."

Start-Sleep -Seconds 120
