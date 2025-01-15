################################################################################
# Script: BackupUSB.ps1
# Objetivo: Ejecutar un backup diario de la carpeta "C:\Maquinas Virtuales", 
#           comprimirlo primero en un disco local, 
#           mover el .zip resultante a B:\Backup, 
#           y eliminar respaldos con más de 8 días.
#           Generar un log con el resultado del proceso.
# Autor: Valentin Torassa Colombero
################################################################################

# Carpeta que se desea respaldar
$SourceFolder = "C:\Maquinas Virtuales"
# Ruta local de staging
$LocalStagingPath = "D:\USBTempBackup"  
# Ruta para almacenar los backups
$BackupPath = "E:\BackupUSB"
# Ruta del archivo log
$LogFile = "D:\USBTempBackup\BackupLogUSB.txt"

$SevenZipExe = "C:\Program Files\7-Zip\7z.exe"


Add-Content $LogFile "--------------------------------------"
Add-Content $LogFile "$(Get-Date): Iniciando script de backup."
Add-Content $LogFile "--------------------------------------"


if (!(Test-Path $LocalStagingPath)) {
    New-Item -Path $LocalStagingPath -ItemType Directory | Out-Null
}
if (!(Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
}

if (!(Test-Path $SourceFolder)) {
    Add-Content $LogFile "$(Get-Date): ERROR - La carpeta de origen $SourceFolder no existe."
    Write-Host "ERROR: La carpeta de origen no existe. Verifique la ruta."
    Exit 1
}

$Now = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupName = "Backup-$Now"


$DestinationFolderLocal = Join-Path $LocalStagingPath $BackupName
New-Item -ItemType Directory -Path $DestinationFolderLocal | Out-Null

Write-Host "Iniciando respaldo de $SourceFolder --> $DestinationFolderLocal ..."
robocopy $SourceFolder $DestinationFolderLocal /E /R:3 /W:5

Add-Content $LogFile "$(Get-Date): Copia realizada exitosamente desde $SourceFolder a $DestinationFolderLocal."

$ZipFileName = "$BackupName.zip"
$ZipFilePathLocal = Join-Path $LocalStagingPath $ZipFileName


Write-Host "Comprimiendo carpeta localmente en: $ZipFilePathLocal ..."

& "$SevenZipExe" 'a' '-tzip' "`"$ZipFilePathLocal`"" "`"$DestinationFolderLocal\*`"" -r -bsp1

if ($LASTEXITCODE -eq 0) {
    Add-Content $LogFile "$(Get-Date): Carpeta comprimida exitosamente en $ZipFilePathLocal."
    Write-Host "Carpeta comprimida correctamente."
    
  
    Remove-Item -Recurse -Force $DestinationFolderLocal
    Add-Content $LogFile "$(Get-Date): Carpeta temporal eliminada ($DestinationFolderLocal)."

    $FinalZipPath = Join-Path $BackupPath $ZipFileName
    Move-Item -Path $ZipFilePathLocal -Destination $FinalZipPath -Force

    Add-Content $LogFile "$(Get-Date): Archivo ZIP movido a $FinalZipPath."
} else {
    Add-Content $LogFile "$(Get-Date): ERROR - Falló la compresión con 7-Zip. Código: $LASTEXITCODE."
    Write-Host "ERROR: Falló la compresión. Verifique el log."
    Exit 1
}

Write-Host "Eliminando respaldos .zip con más de 8 días en B:\Backup..."
Get-ChildItem -Path $BackupPath -Filter '*.zip' | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-8)
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Add-Content $LogFile "$(Get-Date): Respaldos antiguos eliminados (más de 8 días) en B:\Backup."

Add-Content $LogFile "$(Get-Date): Script completado exitosamente."
Write-Host "La tarea ha finalizado. Revise el log para más detalles."

Start-Sleep -Seconds 120
