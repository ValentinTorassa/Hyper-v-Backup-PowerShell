################################################################################
# Script: Backup-Produccion.ps1
# Objetivo: Ejecutar un backup diario de una carpeta espec�fica, 
#           comprimirla en un archivo .zip y 
#           eliminar respaldos con m�s de 8 d�as.
#           Generar un log con el resultado del proceso.
# Autor: Valentin Torassa Colombero
################################################################################

# Ruta de la carpeta que se desea respaldar
$SourceFolder = "C:\Maquinas Virtuales\srv-datos3"
# Ruta de destino donde se almacenar�n los backups
$BackupPath = "B:\Backupsrvdatos3"
# Ruta del ejecutable de 7-Zip
$SevenZipExe = "C:\Program Files\7-Zip\7z.exe"
# Ruta del archivo log
$LogFile = "B:\Backupsrvdatos3\BackupLog.txt"

# Registro inicial en el log
Add-Content $LogFile "--------------------------------------"
Add-Content $LogFile "$(Get-Date): Iniciando script de backup."
Add-Content $LogFile "--------------------------------------"

# Verifica si la carpeta de backups existe; si no, la crea
if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
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

# Copia los archivos desde el origen al destino
Write-Host "Iniciando respaldo de $SourceFolder --> $DestinationFolder ..."
robocopy $SourceFolder $DestinationFolder /E /R:3 /W:5 > $null

Add-Content $LogFile "$(Get-Date): Copia realizada exitosamente desde $SourceFolder a $DestinationFolder."

# Define la ruta y nombre del archivo ZIP que se generar�
$ZipFileName = "$BackupName.zip"
$ZipFilePath = Join-Path $BackupPath $ZipFileName

# Comprimiendo la carpeta de destino usando 7-Zip
Write-Host "Comprimiendo carpeta en: $ZipFilePath ..."
& "$SevenZipExe" 'a' '-tzip' "`"$ZipFilePath`"" "`"$DestinationFolder\*`"" -r -bsp1

if ($LASTEXITCODE -eq 0) {
    Add-Content $LogFile "$(Get-Date): Carpeta comprimida exitosamente en $ZipFilePath."
    Write-Host "Carpeta comprimida correctamente."
    # Elimina la carpeta sin comprimir para ahorrar espacio
    Remove-Item -Recurse -Force $DestinationFolder
    Add-Content $LogFile "$(Get-Date): Carpeta temporal eliminada ($DestinationFolder)."
} else {
    Add-Content $LogFile "$(Get-Date): ERROR - Fall� la compresi�n con 7-Zip. C�digo: $LASTEXITCODE."
    Write-Host "ERROR: Fall� la compresi�n. Verifique el log."
    Exit 1
}

# Limpia los backups antiguos (mayores a 8 d�as) en la carpeta de destino
Write-Host "Eliminando respaldos .zip con m�s de 8 d�as..."
Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Add-Content $LogFile "$(Get-Date): Respaldos antiguos eliminados (m�s de 8 d�as)."

# Mensaje final indicando que el script ha finalizado correctamente
Add-Content $LogFile "$(Get-Date): Script completado exitosamente."
Write-Host "La tarea ha finalizado. Revise el log para m�s detalles."

# Pausa de 120 segundos para mantener la ventana abierta
Start-Sleep -Seconds 120
