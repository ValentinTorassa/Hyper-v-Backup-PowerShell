################################################################################
# Script: Backup-Produccion.ps1
# Objetivo: Ejecutar un backup diario de la carpeta "D:\Hyper-V", 
#           comprimirlo en un archivo .zip y 
#           eliminar respaldos con más de 8 días.
# Autor: Valentin Torassa Colombero
################################################################################

Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Script de backup de Hyper-V (ZIP) - VT"
Write-Host "                                      "
Write-Host "--------------------------------------"

# 1) Ruta de backup en el servidor de contingencia o en el USB
$BackupPath = "D:\Test"  
# Ejemplo alternativo (USB): E:\Backups_HyperV
# Ejemplo alternativo (Red): \\ServidorContingencia\Backups_HyperV

# Verificar que la carpeta de destino exista (crear si no)
if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
}

# 2) Generar un nombre de subcarpeta de respaldo con fecha/hora
$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"

# 3) Crear la carpeta que contendrá la copia de D:\Hyper-V
$DestinationFolder = Join-Path $BackupPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolder | Out-Null

Write-Host "Iniciando respaldo de Hyper-V --> $DestinationFolder ..."
robocopy "D:\Youtube" $DestinationFolder /E /R:3 /W:5
Write-Host "Copia finalizada. Se guardó en: $DestinationFolder"

# 4) Comprimir la carpeta resultante en un archivo .zip
$ZipFileName = "$BackupName.zip"
$ZipFilePath = Join-Path $BackupPath $ZipFileName

Write-Host "Comprimiendo carpeta en: $ZipFilePath ..."
Compress-Archive -Path $DestinationFolder -DestinationPath $ZipFilePath
Write-Host "Carpeta comprimida correctamente."

# 5) (Opcional) Eliminar la carpeta sin comprimir para ahorrar espacio
Write-Host "Eliminando carpeta sin comprimir: $DestinationFolder ..."
Remove-Item -Recurse -Force $DestinationFolder
Write-Host "Carpeta sin comprimir eliminada."

# 6) Limpieza de copias con más de 8 días (basado en los archivos .zip)
Write-Host "Eliminando respaldos .zip con más de 8 días..."

Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Copias antiguas (más de 8 días) eliminadas (si existían)."
