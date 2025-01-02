# Backup-HyperV-Script

**Backup-HyperV-Script** es un script en **PowerShell** que facilita la copia automática de la carpeta `D:\Hyper-V` hacia un directorio de destino, conservando las copias durante un número determinado de días (por defecto, 8). La idea es ofrecer un método sencillo para mantener respaldos recientes de máquinas virtuales y eliminar automáticamente los más antiguos.

## Características

- **Robocopy**: Se utiliza para transferir la carpeta `D:\Hyper-V` completa (incluyendo subdirectorios y archivos).  
- **Retención automática**: Elimina las copias que superen los 8 días de antigüedad.  
- **Carpeta con fecha/hora**: Cada backup se guarda en una subcarpeta nombrada con la marca de tiempo (`Backup-YYYYMMDD-HHMMSS`).  
- **Fácil de programar**: Se ejecuta con el **Task Scheduler** (Programador de Tareas) de Windows a la hora que elijas (por ejemplo, 19:00).  

## Requisitos

1. **Windows Server** o **Windows 10/11** con PowerShell.  
2. **Permisos** de lectura sobre `D:\Hyper-V` y escritura en la carpeta de destino.  
3. **Robocopy** (incluido en Windows desde Windows Vista / Server 2008 en adelante).  

## Uso

1. **Descarga** el archivo `Backup-Produccion.ps1` y colócalo en una carpeta local, por ejemplo, `C:\Scripts\Backup-Produccion.ps1`.  
2. **Edita** el script y ajusta las siguientes variables:  
   - `$BackupPath`: Ruta del directorio de destino (puede ser un USB (`E:\Backups_HyperV`) o una ruta de red (`\\ServidorContingencia\Backups_HyperV`)).  
   - Si deseas modificar el **período de retención** (por defecto 8 días), edita `(Get-Date).AddDays(-8)` en la sección de limpieza.  
3. **Programa la ejecución** con el Task Scheduler de Windows:  
   - Crear una **nueva tarea**.  
   - Acción → **Iniciar un programa** → `powershell.exe`.  
   - Argumentos →  
     ```
     -ExecutionPolicy Bypass -File "C:\Scripts\Backup-Produccion.ps1"
     ```  
   - **Configura la hora** (ejemplo, 19:00 todos los días).  
   - Asegúrate de que la **cuenta** que ejecute la tarea tenga permisos adecuados en la carpeta `D:\Hyper-V` y en `$BackupPath`.  
