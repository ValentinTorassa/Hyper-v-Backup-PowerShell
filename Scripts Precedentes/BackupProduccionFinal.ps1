################################################################################
# Script: Backup-Produccion.ps1
# Objetivo: Ejecutar un backup diario de la carpeta "D:\Hyper-V" y 
#           eliminar respaldos con más de 8 días.
# Autor: Valentin Torassa Colombero
################################################################################

Write-Host "Script de backup de Hyper-V VT"

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

Write-Host "Iniciando respaldo de D:\Hyper-V --> $DestinationFolder ..."

robocopy "D:\Hyper-V" $DestinationFolder /E /R:3 /W:5

Write-Host "Copia finalizada. Se guardó en: $DestinationFolder"

Write-Host "Eliminando respaldos con más de 8 días..."

Get-ChildItem -Path $BackupPath -Directory | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Copias antiguas (más de 8 días) eliminadas (si existían)."
