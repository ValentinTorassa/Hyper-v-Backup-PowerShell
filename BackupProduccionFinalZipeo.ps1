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

Write-Host "                                      "
Write-Host "Iniciando respaldo de Hyper-V --> $DestinationFolder ..."
robocopy "D:\Youtube" $DestinationFolder /E /R:3 /W:5

Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Copia finalizada. Se guardó en: $DestinationFolder"
Write-Host "                                      "
Write-Host "--------------------------------------"

$ZipFileName = "$BackupName.zip"
$ZipFilePath = Join-Path $BackupPath $ZipFileName

Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Comprimiendo carpeta en: $ZipFilePath ..."
Write-Host "                                      "
Write-Host "--------------------------------------"


Compress-Archive -Path $DestinationFolder -DestinationPath $ZipFilePath

Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Carpeta comprimida correctamente."
Write-Host "                                      "
Write-Host "--------------------------------------"

Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Eliminando carpeta sin comprimir: $DestinationFolder ..."
Write-Host "                                      "
Write-Host "--------------------------------------"


Remove-Item -Recurse -Force $DestinationFolder

Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Carpeta sin comprimir eliminada."
Write-Host "                                      "
Write-Host "--------------------------------------"

Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Eliminando respaldos .zip con mas de 8 dias..."
Write-Host "                                      "
Write-Host "--------------------------------------"

Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Copias antiguas (mas de 8 dias) eliminadas (si existian)."
Write-Host "                                      "
Write-Host "--------------------------------------"


Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "La tarea ha finalizado."
Write-Host "                                      "
Write-Host "--------------------------------------"
Start-Sleep -Seconds 120