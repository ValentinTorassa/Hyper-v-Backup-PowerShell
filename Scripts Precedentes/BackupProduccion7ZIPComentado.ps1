################################################################################
# Script: Backup-Produccion.ps1
# Objetivo: Ejecutar un backup diario de la carpeta "D:\Hyper-V", 
#           comprimirlo en un archivo .zip y 
#           eliminar respaldos con más de 8 días.
# Autor: Valentin Torassa Colombero
################################################################################

# Mensaje de inicio del script
Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Script de backup de Hyper-V (ZIP) - VT"
Write-Host "                                      "
Write-Host "--------------------------------------"

# Ruta de destino donde se guardarán los backups
$BackupPath = "B:\Backupsrvdatos3"  
# Ejemplo alternativo: E:\Backups_HyperV (USB) o \\ServidorContingencia\Backups_HyperV (Red)

# Ruta del ejecutable de 7-Zip
$SevenZipExe = "C:\Program Files\7-Zip\7z.exe"

# Verifica si la carpeta de backups existe; si no, la crea
if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
}

# Genera un nombre único para el backup basado en la fecha y hora actuales
$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"

# Crea una subcarpeta para almacenar temporalmente los datos antes de comprimir
$DestinationFolder = Join-Path $BackupPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolder | Out-Null

# Copia los archivos desde el origen (D:\Hyper-V) al destino ($DestinationFolder)
Write-Host "                                      "
Write-Host "Iniciando respaldo de Hyper-V --> $DestinationFolder ..."
robocopy "C:\Maquinas Virtuales\srv-datos3" $DestinationFolder /E /R:3 /W:5

# Mensaje de confirmación de la copia
Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Copia finalizada. Se guardó en: $DestinationFolder"
Write-Host "                                      "
Write-Host "--------------------------------------"

# Define la ruta y nombre del archivo ZIP que se generará
$ZipFileName = "$BackupName.zip"
$ZipFilePath = Join-Path $BackupPath $ZipFileName

# Comprimiendo la carpeta de destino usando 7-Zip
Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Comprimiendo carpeta en: $ZipFilePath ..."
Write-Host "                                      "
Write-Host "--------------------------------------"

& "$SevenZipExe" 'a' '-tzip' "`"$ZipFilePath`"" "`"$DestinationFolder\*`"" -r -bsp1
# Nota: -bsp1 muestra el progreso de la compresión en pantalla

# Verifica si la compresión fue exitosa
if ($LASTEXITCODE -eq 0) {
    # Mensaje de éxito de compresión
    Write-Host "--------------------------------------"
    Write-Host "                                      "
    Write-Host "Carpeta comprimida correctamente."
    Write-Host "                                      "
    Write-Host "--------------------------------------"

    # Elimina la carpeta sin comprimir para ahorrar espacio
    Write-Host "--------------------------------------"
    Write-Host "                                      "
    Write-Host "Eliminando carpeta sin comprimir: $DestinationFolder ..."
    Write-Host "                                      "
    Write-Host "--------------------------------------"
    Remove-Item -Recurse -Force $DestinationFolder

    # Mensaje confirmando que la carpeta sin comprimir fue eliminada
    Write-Host "--------------------------------------"
    Write-Host "                                      "
    Write-Host "Carpeta sin comprimir eliminada."
    Write-Host "                                      "
    Write-Host "--------------------------------------"
} else {
    # Mensaje de error en caso de que la compresión falle
    WriteHost "Error: $LASTEXITCODE"
}

# Limpia los backups antiguos (mayores a 8 días) en la carpeta de destino
Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Eliminando respaldos .zip con más de 8 días..."
Write-Host "                                      "
Write-Host "--------------------------------------"

Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Mensaje confirmando la limpieza de backups antiguos
Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "Copias antiguas (más de 8 días) eliminadas (si existían)."
Write-Host "                                      "
Write-Host "--------------------------------------"

# Mensaje final indicando que el script ha finalizado
Write-Host "--------------------------------------"
Write-Host "                                      "
Write-Host "La tarea ha finalizado."
Write-Host "                                      "
Write-Host "--------------------------------------"

# Pausa de 120 segundos para mantener la ventana abierta
Start-Sleep -Seconds 120
