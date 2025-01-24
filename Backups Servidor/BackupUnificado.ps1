################################################################################
# Script: Backup-Unificado.ps1
# Objetivo: Ejecutar un backup diario de la carpeta "C:\Maquinas Virtuales",
#           comprimirlo primero en un disco local (staging),
#           mover el .zip resultante a DOS destinos (USB y red),
#           y eliminar respaldos con más de 8 días en ambos destinos.
#           Generar un log con el resultado del proceso.
# Autor: Valentin Torassa Colombero
################################################################################

# --- Variables de configuración ---

# Carpeta que se desea respaldar
$SourceFolder      = "C:\Maquinas Virtuales"

# Ruta local de staging (disco rápido donde se realizará la copia y compresión)
$LocalStagingPath  = "D:\TempBackup"

# Destinos finales:
$BackupPathUSB     = "E:\BackupUSB"              # Ej: USB
$BackupPathNetwork = "\\Srvg10pus\solo copia de backups\Backup"  # Ej: ruta de contingencia

# Ruta del archivo log principal (puede estar en staging o en otra ubicación)
$LogFile           = "D:\TempBackup\BackupLog_Unificado.txt"

# Ruta del ejecutable de 7-Zip
$SevenZipExe       = "C:\Program Files\7-Zip\7z.exe"

# --- Inicio de registro en el log ---
Add-Content $LogFile "--------------------------------------"
Add-Content $LogFile "$(Get-Date): Iniciando script de backup unificado."
Add-Content $LogFile "--------------------------------------"

# --- Verificación de carpetas ---

# 1) Staging
if (!(Test-Path $LocalStagingPath)) {
    try {
        New-Item -Path $LocalStagingPath -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch {
        Add-Content $LogFile "$(Get-Date): ERROR - No se pudo crear la carpeta local de staging $LocalStagingPath. $_"
        Write-Host "ERROR: No se pudo crear $LocalStagingPath. Revise permisos o la ruta."
        Exit 1
    }
}

# 2) Destino USB
if (!(Test-Path $BackupPathUSB)) {
    try {
        New-Item -Path $BackupPathUSB -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch {
        Add-Content $LogFile "$(Get-Date): ERROR - No se pudo crear la carpeta de USB $BackupPathUSB. $_"
        Write-Host "ERROR: No se pudo crear $BackupPathUSB. Revise permisos o la ruta."
        Exit 1
    }
}

# 3) Destino Red
if (!(Test-Path $BackupPathNetwork)) {
    try {
        New-Item -Path $BackupPathNetwork -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch {
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

# --- Preparación del nombre de backup y carpeta temporal ---

$Now          = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName   = "Backup-$Now"
$DestinationFolderLocal = Join-Path $LocalStagingPath $BackupName

# Crear carpeta temporal donde copiar los archivos
New-Item -ItemType Directory -Path $DestinationFolderLocal | Out-Null

Write-Host "Iniciando respaldo de $SourceFolder --> $DestinationFolderLocal ..."
robocopy $SourceFolder $DestinationFolderLocal /E /R:3 /W:5

# Verifica resultado robocopy (códigos > 1 = error)
if ($LASTEXITCODE -gt 1) {
    Add-Content $LogFile "$(Get-Date): ERROR - Falló la copia con Robocopy. Código: $LASTEXITCODE."
    Write-Host "ERROR: Falló la copia de $SourceFolder. Verifique el log."
    Exit 1
} else {
    Add-Content $LogFile "$(Get-Date): Copia realizada exitosamente desde $SourceFolder a $DestinationFolderLocal."
}

# --- Compresión con 7-Zip en la carpeta local ---
$ZipFileName      = "$BackupName.zip"
$ZipFilePathLocal = Join-Path $LocalStagingPath $ZipFileName

Write-Host "Comprimiendo carpeta localmente en: $ZipFilePathLocal ..."
# Añade -mx1 para compresión rápida o -m0=Copy para sin compresión
& "$SevenZipExe" 'a' '-tzip' "`"$ZipFilePathLocal`"" "`"$DestinationFolderLocal\*`"" -r -bsp1 -mx1

if ($LASTEXITCODE -eq 0) {
    Add-Content $LogFile "$(Get-Date): Carpeta comprimida exitosamente en $ZipFilePathLocal."
    Write-Host "Carpeta comprimida correctamente."

    # Elimina la carpeta temporal sin comprimir
    Remove-Item -Recurse -Force $DestinationFolderLocal
    Add-Content $LogFile "$(Get-Date): Carpeta temporal eliminada ($DestinationFolderLocal)."
} else {
    Add-Content $LogFile "$(Get-Date): ERROR - Falló la compresión con 7-Zip. Código: $LASTEXITCODE."
    Write-Host "ERROR: Falló la compresión. Verifique el log."
    Exit 1
}

# --- Copiar (o mover) el .zip resultante a DOS destinos (USB y Red) ---

# 1) Copia a USB
$FinalZipPathUSB = Join-Path $BackupPathUSB $ZipFileName
Write-Host "Copiando el .zip al destino USB: $FinalZipPathUSB ..."
try {
    Copy-Item -Path $ZipFilePathLocal -Destination $FinalZipPathUSB -Force
    Add-Content $LogFile "$(Get-Date): Archivo ZIP copiado a (USB) $FinalZipPathUSB."
}
catch {
    Add-Content $LogFile "$(Get-Date): ERROR - No se pudo copiar el archivo .zip a (USB) $FinalZipPathUSB. $_"
    Write-Host "ERROR: No se pudo copiar el archivo .zip al USB. Revise permisos o la ruta."
}

# 2) Copia a Red
$FinalZipPathNetwork = Join-Path $BackupPathNetwork $ZipFileName
Write-Host "Copiando el .zip al destino de red: $FinalZipPathNetwork ..."
try {
    Copy-Item -Path $ZipFilePathLocal -Destination $FinalZipPathNetwork -Force
    Add-Content $LogFile "$(Get-Date): Archivo ZIP copiado a (Red) $FinalZipPathNetwork."
}
catch {
    Add-Content $LogFile "$(Get-Date): ERROR - No se pudo copiar el archivo .zip a (Red) $FinalZipPathNetwork. $_"
    Write-Host "ERROR: No se pudo copiar el archivo .zip a la red. Verifique permisos o la ruta."
}

# (Opcional) Elimina el .zip local de staging para no acumular
try {
    Remove-Item $ZipFilePathLocal -Force
    Add-Content $LogFile "$(Get-Date): Archivo ZIP local ($ZipFilePathLocal) eliminado."
}
catch {
    Add-Content $LogFile "$(Get-Date): ADVERTENCIA - No se pudo eliminar el archivo ZIP local $ZipFilePathLocal. $_"
    Write-Host "WARNING: No se pudo eliminar el ZIP local. Puede quedar espacio ocupado en staging."
}

# --- Limpieza de respaldos antiguos en AMBOS destinos (USB y Red) ---

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
