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

$BackupPath = "D:\Test"  
# Ejemplo alternativo (USB): E:\Backups_HyperV
# Ejemplo alternativo (Red): \\ServidorContingencia\Backups_HyperV

if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
}

$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"

$DestinationFolder = Join-Path $BackupPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolder | Out-Null

Write-Host "Iniciando respaldo de Hyper-V --> $DestinationFolder ..."
robocopy "D:\Youtube" $DestinationFolder /E /R:3 /W:5
Write-Host "Copia finalizada. Se guardó en: $DestinationFolder"


$ZipFileName = "$BackupName.zip"
$ZipFilePath = Join-Path $BackupPath $ZipFileName

Write-Host "Comprimiendo carpeta en: $ZipFilePath ..."
Compress-Archive -Path $DestinationFolder -DestinationPath $ZipFilePath
Write-Host "Carpeta comprimida correctamente."

Write-Host "Eliminando carpeta sin comprimir: $DestinationFolder ..."
Remove-Item -Recurse -Force $DestinationFolder
Write-Host "Carpeta sin comprimir eliminada."

Write-Host "Eliminando respaldos .zip con mas de 8 dias..."

Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Copias antiguas (mas de 8 dias) eliminadas (si existian)."


Write-Host "La tarea ha finalizado."
Start-Sleep -Seconds 120