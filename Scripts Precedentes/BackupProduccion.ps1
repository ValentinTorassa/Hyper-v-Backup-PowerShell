################################################################################
# Script: Backup-Produccion.ps1
# Objetivo: Ejecutar un backup diario de la carpeta "D:\Hyper-V" y 
#           eliminar respaldos con más de 8 días.
################################################################################

# 1) Ruta de backup en el servidor de contingencia o en el USB
$BackupPath = "D:\Test"  
# Ejemplo alternativo (USB): E:\Backups_HyperV
# Ejemplo alternativo (Red): \\ServidorContingencia\Backups_HyperV

# 2) Verificar que la carpeta de destino exista (crear si no)
if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
}

# 3) Generar un nombre de subcarpeta de respaldo con la fecha/hora actual
$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"

# Creamos la carpeta que contendrá la copia de D:\Hyper-V
$DestinationFolder = Join-Path $BackupPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolder | Out-Null

Write-Host "Iniciando respaldo de D:\Hyper-V --> $DestinationFolder ..."

# 4) Copia completa de la carpeta "D:\Hyper-V" usando robocopy
#    /E          => Copia subdirectorios incluyendo vacíos
#    /R:3 /W:5   => Reintentos en caso de error y tiempo de espera entre reintentos
#    /LOG+       => Opcional, para guardar un log de la copia
#    /NFL /NDL   => Opcionales, evitan listar ficheros y directorios en el log
#    Ajusta las opciones de robocopy a tu gusto.
robocopy "D:\Hyper-V" $DestinationFolder /E /R:3 /W:5

Write-Host "Copia finalizada. Se guardó en: $DestinationFolder"

# 5) Limpieza de copias con más de 8 días
#    Buscamos subcarpetas en $BackupPath cuyo CreationTime sea mayor a 8 días
#    y las eliminamos recursivamente.

Write-Host "Eliminando respaldos con más de 8 días..."

Get-ChildItem -Path $BackupPath -Directory | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Copias antiguas (más de 8 días) eliminadas (si existían)."
