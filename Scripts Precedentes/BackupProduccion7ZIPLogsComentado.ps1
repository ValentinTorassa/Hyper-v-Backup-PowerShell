################################################################################
# Script: Backup-Produccion.ps1
# Objetivo: Ejecutar un backup diario de una carpeta espec�fica, 
#           comprimirla en un archivo .zip y 
#           eliminar respaldos con m�s de 8 d�as.
#           Generar un log con el resultado del proceso.
# Autor: Valentin Torassa Colombero
################################################################################

# Ruta de la carpeta que se desea respaldar
$SourceFolder = "C:\Users\valen\Documents"
# Ruta de destino donde se almacenar�n los backups
$BackupPath = "C:\Test"

# Ruta del archivo log para registrar el proceso
$LogFile = "C:\Test\BackupLog.txt"

# Registro inicial en el log
Add-Content $LogFile "--------------------------------------"
Add-Content $LogFile "$(Get-Date): Iniciando script de backup."
Add-Content $LogFile "--------------------------------------"

# Verifica si la carpeta de backups existe; si no, la crea
if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
    # Test-Path verifica si existe una ruta, y New-Item la crea si no existe
}

# Verifica si la carpeta de origen existe
if (!(Test-Path $SourceFolder)) {
    Add-Content $LogFile "$(Get-Date): ERROR - La carpeta de origen $SourceFolder no existe."
    Write-Host "ERROR: La carpeta de origen no existe. Verifique la ruta."
    Exit 1
}

# Genera un nombre �nico para el backup basado en la fecha y hora actuales
$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"

# Crea una subcarpeta para almacenar temporalmente los datos antes de comprimir
$DestinationFolder = Join-Path $BackupPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
# Join-Path combina rutas evitando errores de formato

# Copia los archivos desde el origen al destino
Write-Host "Iniciando respaldo de $SourceFolder --> $DestinationFolder ..."
robocopy $SourceFolder $DestinationFolder /E /R:3 /W:5 > $null
# /E: Copia todos los subdirectorios, incluidos los vac�os
# /R:3: Intenta copiar un archivo hasta 3 veces en caso de error
# /W:5: Espera 5 segundos entre intentos fallidos
# > $null: Suprime la salida en consola de robocopy para evitar ruido

if ($LASTEXITCODE -gt 1) {
    Add-Content $LogFile "$(Get-Date): ERROR - Fall� la copia con Robocopy. C�digo: $LASTEXITCODE."
    Write-Host "ERROR: Fall� la copia con Robocopy. Verifique el log."
    Exit 1
}
Add-Content $LogFile "$(Get-Date): Copia realizada exitosamente desde $SourceFolder a $DestinationFolder."

# Define la ruta y nombre del archivo ZIP que se generar�
$ZipFileName = "$BackupName.zip"
$ZipFilePath = Join-Path $BackupPath $ZipFileName

# Comprimiendo la carpeta de destino usando Compress-Archive
Write-Host "Comprimiendo carpeta en: $ZipFilePath ..."
Compress-Archive -Path "$DestinationFolder\*" -DestinationPath $ZipFilePath -Force
# -Path: Especifica los archivos o carpetas a comprimir
# -DestinationPath: Define el nombre y la ubicaci�n del archivo ZIP
# -Force: Sobrescribe un archivo existente con el mismo nombre

if ($?) {
    Add-Content $LogFile "$(Get-Date): Carpeta comprimida exitosamente en $ZipFilePath."
    Write-Host "Carpeta comprimida correctamente."
    # Elimina la carpeta sin comprimir para ahorrar espacio
    Remove-Item -Recurse -Force $DestinationFolder
    # -Recurse: Elimina contenido de subcarpetas
    # -Force: Ignora confirmaciones
    Add-Content $LogFile "$(Get-Date): Carpeta temporal eliminada ($DestinationFolder)."
} else {
    Add-Content $LogFile "$(Get-Date): ERROR - Fall� la compresi�n con Compress-Archive."
    Write-Host "ERROR: Fall� la compresi�n. Verifique el log."
    Exit 1
}

# Limpia los backups antiguos (mayores a 8 d�as) en la carpeta de destino
Write-Host "Eliminando respaldos .zip con m�s de 8 d�as..."
Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
# Get-ChildItem: Enumera archivos y carpetas en la ruta especificada
# -Filter '*.zip': Filtra para incluir solo archivos ZIP
# CreationTime: Fecha de creaci�n del archivo
# AddDays(-8): Calcula la fecha l�mite (8 d�as antes de hoy)
# Remove-Item: Elimina los archivos seleccionados
# -ErrorAction SilentlyContinue: Suprime errores, �til si no hay archivos para eliminar

Add-Content $LogFile "$(Get-Date): Respaldos antiguos eliminados (m�s de 8 d�as)."

# Mensaje final indicando que el script ha finalizado correctamente
Add-Content $LogFile "$(Get-Date): Script completado exitosamente."
Write-Host "La tarea ha finalizado. Revise el log para m�s detalles."

# Pausa de 120 segundos para mantener la ventana abierta
Start-Sleep -Seconds 120
