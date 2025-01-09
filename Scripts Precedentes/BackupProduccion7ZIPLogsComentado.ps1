################################################################################
# Script: Backup-Produccion.ps1
# Objetivo: Ejecutar un backup diario de una carpeta específica, 
#           comprimirla en un archivo .zip y 
#           eliminar respaldos con más de 8 días.
#           Generar un log con el resultado del proceso.
# Autor: Valentin Torassa Colombero
################################################################################

# Ruta de la carpeta que se desea respaldar
$SourceFolder = "C:\Users\valen\Documents"
# Ruta de destino donde se almacenarán los backups
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

# Genera un nombre único para el backup basado en la fecha y hora actuales
$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"

# Crea una subcarpeta para almacenar temporalmente los datos antes de comprimir
$DestinationFolder = Join-Path $BackupPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
# Join-Path combina rutas evitando errores de formato

# Copia los archivos desde el origen al destino
Write-Host "Iniciando respaldo de $SourceFolder --> $DestinationFolder ..."
robocopy $SourceFolder $DestinationFolder /E /R:3 /W:5 > $null
# /E: Copia todos los subdirectorios, incluidos los vacíos
# /R:3: Intenta copiar un archivo hasta 3 veces en caso de error
# /W:5: Espera 5 segundos entre intentos fallidos
# > $null: Suprime la salida en consola de robocopy para evitar ruido

if ($LASTEXITCODE -gt 1) {
    Add-Content $LogFile "$(Get-Date): ERROR - Falló la copia con Robocopy. Código: $LASTEXITCODE."
    Write-Host "ERROR: Falló la copia con Robocopy. Verifique el log."
    Exit 1
}
Add-Content $LogFile "$(Get-Date): Copia realizada exitosamente desde $SourceFolder a $DestinationFolder."

# Define la ruta y nombre del archivo ZIP que se generará
$ZipFileName = "$BackupName.zip"
$ZipFilePath = Join-Path $BackupPath $ZipFileName

# Comprimiendo la carpeta de destino usando Compress-Archive
Write-Host "Comprimiendo carpeta en: $ZipFilePath ..."
Compress-Archive -Path "$DestinationFolder\*" -DestinationPath $ZipFilePath -Force
# -Path: Especifica los archivos o carpetas a comprimir
# -DestinationPath: Define el nombre y la ubicación del archivo ZIP
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
    Add-Content $LogFile "$(Get-Date): ERROR - Falló la compresión con Compress-Archive."
    Write-Host "ERROR: Falló la compresión. Verifique el log."
    Exit 1
}

# Limpia los backups antiguos (mayores a 8 días) en la carpeta de destino
Write-Host "Eliminando respaldos .zip con más de 8 días..."
Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
# Get-ChildItem: Enumera archivos y carpetas en la ruta especificada
# -Filter '*.zip': Filtra para incluir solo archivos ZIP
# CreationTime: Fecha de creación del archivo
# AddDays(-8): Calcula la fecha límite (8 días antes de hoy)
# Remove-Item: Elimina los archivos seleccionados
# -ErrorAction SilentlyContinue: Suprime errores, útil si no hay archivos para eliminar

Add-Content $LogFile "$(Get-Date): Respaldos antiguos eliminados (más de 8 días)."

# Mensaje final indicando que el script ha finalizado correctamente
Add-Content $LogFile "$(Get-Date): Script completado exitosamente."
Write-Host "La tarea ha finalizado. Revise el log para más detalles."

# Pausa de 120 segundos para mantener la ventana abierta
Start-Sleep -Seconds 120
