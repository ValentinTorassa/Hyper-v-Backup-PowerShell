################################################################################
# Script: Backup-Produccion.ps1
# Objetivo: Ejecutar un backup diario de la carpeta "C:\Maquinas Virtuales", 
#           comprimirlo primero en un disco local, 
#           mover el .zip resultante a B:\Backup, 
#           y eliminar respaldos con más de 8 días.
#           Generar un log con el resultado del proceso.
# Autor: Valentin Torassa Colombero
################################################################################

# Ruta de la carpeta que se desea respaldar
$SourceFolder = "C:\Maquinas Virtuales"
# Ruta local de staging donde se realizará la copia y compresión
$LocalStagingPath = "C:\TempBackup"  
# Ruta de destino final para almacenar los backups
$BackupPath = "B:\Backup"
# Ruta del ejecutable de 7-Zip
$SevenZipExe = "C:\Program Files\7-Zip\7z.exe"
# Ruta del archivo log
$LogFile = "B:\BackupLog.txt"

# Log: Registro inicial de la ejecución
Add-Content $LogFile "--------------------------------------"
Add-Content $LogFile "$(Get-Date): Iniciando script de backup."
Add-Content $LogFile "--------------------------------------"

# 1. Verifica si existen las carpetas de staging y de backup; si no, se crean
if (!(Test-Path $LocalStagingPath)) {
    New-Item -Path $LocalStagingPath -ItemType Directory | Out-Null
}
if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
}

# 2. Verifica si la carpeta de origen existe
if (!(Test-Path $SourceFolder)) {
    Add-Content $LogFile "$(Get-Date): ERROR - La carpeta de origen $SourceFolder no existe."
    Write-Host "ERROR: La carpeta de origen no existe. Verifique la ruta."
    Exit 1
}

# 3. Genera un nombre único para el backup
$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"

# 4. Crea una subcarpeta local de staging (temporal) para almacenar los archivos
$DestinationFolderLocal = Join-Path $LocalStagingPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolderLocal | Out-Null

# 5. Copia los archivos desde el origen al staging local
Write-Host "Iniciando respaldo de $SourceFolder --> $DestinationFolderLocal ..."
robocopy $SourceFolder $DestinationFolderLocal /E /R:3 /W:5

Add-Content $LogFile "$(Get-Date): Copia realizada exitosamente desde $SourceFolder a $DestinationFolderLocal."

# 6. Definir la ruta local del archivo ZIP
$ZipFileName = "$BackupName.zip"
$ZipFilePathLocal = Join-Path $LocalStagingPath $ZipFileName

# 7. Comprimir usando 7-Zip en el disco local
Write-Host "Comprimiendo carpeta localmente en: $ZipFilePathLocal ..."
# Añade -mx1 si quieres compresión rápida: '-mx1'
# o -m0=Copy si no quieres comprimir, solo empaquetar
& "$SevenZipExe" 'a' '-tzip' "`"$ZipFilePathLocal`"" "`"$DestinationFolderLocal\*`"" -r -bsp1

if ($LASTEXITCODE -eq 0) {
    Add-Content $LogFile "$(Get-Date): Carpeta comprimida exitosamente en $ZipFilePathLocal."
    Write-Host "Carpeta comprimida correctamente."
    
    # 8. Elimina la carpeta local sin comprimir para ahorrar espacio
    Remove-Item -Recurse -Force $DestinationFolderLocal
    Add-Content $LogFile "$(Get-Date): Carpeta temporal eliminada ($DestinationFolderLocal)."

    # 9. Mover el .zip final desde staging local (C:\TempBackup) a B:\Backup
    $FinalZipPath = Join-Path $BackupPath $ZipFileName
    Move-Item -Path $ZipFilePathLocal -Destination $FinalZipPath -Force

    Add-Content $LogFile "$(Get-Date): Archivo ZIP movido a $FinalZipPath."
} else {
    Add-Content $LogFile "$(Get-Date): ERROR - Falló la compresión con 7-Zip. Código: $LASTEXITCODE."
    Write-Host "ERROR: Falló la compresión. Verifique el log."
    Exit 1
}

# 10. Limpia los backups antiguos (mayores a 8 días) en B:\Backup
Write-Host "Eliminando respaldos .zip con más de 8 días en B:\Backup..."
Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Add-Content $LogFile "$(Get-Date): Respaldos antiguos eliminados (más de 8 días) en B:\Backup."

# 11. Mensaje final indicando que el script ha finalizado correctamente
Add-Content $LogFile "$(Get-Date): Script completado exitosamente."
Write-Host "La tarea ha finalizado. Revise el log para más detalles."

# Pausa de 120 segundos para mantener la ventana abierta
Start-Sleep -Seconds 120
