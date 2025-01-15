## **Backup-HyperV-Script (Versión Avanzada)**

**Backup-HyperV-Script** es un script en **PowerShell** diseñado para **copiar y comprimir** automáticamente la carpeta que contiene máquinas virtuales (por defecto, `C:\Maquinas Virtuales`). A diferencia de la versión anterior, ahora **primero** copia el contenido a un **disco local de staging** (por ejemplo, `D:\TempBackup`) para agilizar la compresión, y **luego** mueve el `.zip` resultante al **disco de backup** (por defecto, `B:\Backup`). También **limpia** los respaldos de más de 8 días y **registra** todas las acciones en un archivo de log.

### **Autor: Valentin Torassa Colombero**

---

## **Opciones de Scripts**

1. **BackupProduccion7ZIPLogs.ps1**  
   - **Usa 7-Zip** para comprimir, sin staging local.  
   - Copia y comprime la carpeta directamente en la unidad de destino (por ejemplo `B:\Backup`).  
   - Mantiene un **log** de las operaciones y elimina respaldos con más de 8 días.  

2. **BackupProduccion7ZIPLogsStaging.ps1**  
   - **Usa 7-Zip** con **staging local** para aumentar la velocidad de compresión.  
   - Primero copia la carpeta de máquinas virtuales (ej. `C:\Maquinas Virtuales`) a una ubicación rápida (`D:\TempBackup` o similar).  
   - Luego comprime en el disco local y, por último, **mueve** el .zip al **destino** (`B:\Backup`).  
   - Incluye **logs** y la misma limpieza de respaldos viejos (8 días).

3. **BackupProduccionCompresionLogs.ps1**  
   - En lugar de 7-Zip, usa la **compresión nativa de Windows** (`Compress-Archive`).  
   - Puede o no tener staging local, según la versión, pero por defecto comprime directamente en la carpeta de destino.  
   - Mantiene logs y elimina respaldos antiguos.

---

## **Características Principales**

1. **Copia y staging local**  
   - **Robocopy** transfiere la carpeta de origen (`$SourceFolder`) a una **ubicación local** rápida (`$LocalStagingPath`).  
   - Esto reduce los tiempos de compresión si la unidad de staging es más veloz que la de backup.

2. **Compresión con 7-Zip**  
   - Usa **7-Zip** (`7z.exe`) para comprimir en formato `.zip`.  
   - Incluye la opción `-bsp1` para mostrar el **progreso** en la línea de comandos.  
   - Una vez finalizada la compresión, elimina la carpeta de staging para ahorrar espacio.

3. **Movimiento del ZIP al disco de respaldo**  
   - El `.zip` final se **mueve** al directorio de backup (p. ej. `B:\Backup`), manteniendo la operación de compresión en local.  
   - Se facilita así la recuperación en caso de contingencia.

4. **Retención automática (8 días)**  
   - Elimina los **respaldos antiguos** con más de 8 días de antigüedad en la carpeta de destino (`$BackupPath`).  
   - Garantiza que solo queden copias relativamente recientes, ahorrando espacio.

5. **Archivo de Log**  
   - Genera un **log** (`$LogFile`) para cada ejecución, registrando copias, compresiones y limpiezas.  
   - Reporta eventuales errores (fallo de Robocopy, compresión, etc.) y el **código de salida**.

---

## **Requisitos**

1. **Windows Server** (o Windows 10/11) con **PowerShell**.  
2. **7-Zip** instalado (ruta especificada en `$SevenZipExe`).  
3. **Permisos** de lectura sobre la carpeta de origen (`$SourceFolder`) y escritura en `$LocalStagingPath` y `$BackupPath`.  
4. **Robocopy** (incluido en Windows desde Windows Vista / Server 2008).

---

## **Uso**

1. **Descarga o copia** el archivo `Backup-Produccion.ps1` a una carpeta local (ej. `C:\Scripts\Backup-Produccion.ps1`).  
2. **Edita** el script y ajusta las siguientes variables según tu entorno:
   - `$SourceFolder`: Carpeta de VM a respaldar (ej. `C:\Maquinas Virtuales`).  
   - `$LocalStagingPath`: Carpeta local de staging (ej. `D:\TempBackup`).  
   - `$BackupPath`: Ubicación de destino para el ZIP final (ej. `B:\Backup`).  
   - `$LogFile`: Ruta para el archivo de log (ej. `B:\BackupLog.txt`).  
   - `(Get-Date).AddDays(-8)`: Periodo de retención (en días) para respaldos antiguos.

3. **Programa la ejecución** con **Task Scheduler** (Programador de Tareas) de Windows:
   - Crear una **nueva tarea** y configurar la acción → **Iniciar un programa** → `powershell.exe`.  
   - Parámetros típicos:  
     ```bash
     -ExecutionPolicy Bypass -File "C:\Scripts\Backup-Produccion.ps1"
     ```
   - Ajustar la **hora** y **frecuencia** (ej.: todos los días a las 19:00).  
   - Asegúrate de que la cuenta que ejecuta la tarea tenga permisos de lectura/escritura en las rutas involucradas.

4. **Verificar el proceso**:
   - Tras la ejecución, revisa el **log** (`BackupLog.txt`) para confirmar el éxito de cada paso.  
   - En caso de error, se registra un mensaje detallado y el script finaliza de inmediato.

---

## **Flujo de Operación**

1. **Robocopy**: Copia desde `C:\Maquinas Virtuales` → `D:\TempBackup\Backup-YYYYMMDD-HHMMSS`.  
2. **7-Zip**: Comprime esa subcarpeta en un ZIP local (ej. `D:\TempBackup\Backup-YYYYMMDD-HHMMSS.zip`).  
3. **Remueve** la carpeta temporal, moviendo luego el ZIP al destino (`B:\Backup`).  
4. **Limpieza** de respaldos antiguos (mayores a 8 días) en `B:\Backup`.  
5. **Log**: Registra cada paso (fecha/hora, éxito/error).

**Resultado**: Un archivo ZIP diario en `B:\Backup`, listo para su restauración en caso de contingencia, con una retención de copias de 8 días.