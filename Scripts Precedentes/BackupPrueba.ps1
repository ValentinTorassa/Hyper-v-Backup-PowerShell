################################################################################
# Script: Backup-Prueba.ps1
# Objetivo: Crear un archivo de "respaldo" (dummy) cada minuto y
#           eliminar archivos con más de 8 minutos de antigüedad.
################################################################################

# 1) Define la ruta donde se guardarán los backups de prueba
$BackupPath = "C:\Test"

# 2) Crea la carpeta si no existe
if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
}

# 3) Genera un nombre de archivo con la hora actual (simulando el backup)
$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupFile = Join-Path $BackupPath "Backup-$Now.txt"

# 4) Crea un archivo dummy para simular el backup
"Simulated backup created at $($Now)" | Out-File $BackupFile
Write-Host "Backup de prueba creado: $BackupFile"

# 5) Limpia respaldos de más de 8 minutos (para esta prueba)
Get-ChildItem -Path $BackupPath -File | Where-Object {
    $_.CreationTime -lt (Get-Date).AddMinutes(-8)
} | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "Copias antiguas eliminadas (más de 8 minutos)."
