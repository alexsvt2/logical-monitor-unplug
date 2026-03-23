# 🖥️ mac-monitor-toggle

Script y lanzador de macOS para alternar (toggle) rápidamente un monitor externo específico mediante `displayplacer` y `CoreGraphics`.

## 📌 ¿Para qué sirve?

Este script soluciona el problema de los monitores externos en macOS que a veces no se detectan o necesitan ser "refrescados". Permite:
1.  **Desactivar** un monitor específico por su ID.
2.  **Reactivar** todos los monitores forzando una configuración de `CoreGraphics` (usando un script de Python).

## 🛠️ Requisitos

*   **macOS** (probado en Apple Silicon/Intel).
*   **[displayplacer](https://github.com/jakehilborn/displayplacer)**: Instalable vía Homebrew:
    ```bash
    brew tap jakehilborn/jakehilborn
    brew install displayplacer
    ```
*   **Python 3**: Para el script de reseteo de CoreGraphics.

## 🚀 Instalación y Uso

1.  Clona este repositorio o descarga los archivos.
2.  Haz que los scripts sean ejecutables:
    ```bash
    chmod +x bin/toggle_monitor.sh
    chmod +x bin/reenable-displays.py
    ```
3.  Busca tu ID de monitor:
    ```bash
    displayplacer list
    ```
4.  Actualiza el `DEFAULT_MONITOR_ID` en `bin/toggle_monitor.sh` con tu ID.

### 🍎 Crear el Lanzador (App)

Para tenerlo en tu Dock o Launchpad sin ver la terminal:
1.  Abre **Automator**.
2.  Crea una **Nueva Aplicación**.
3.  Añade la acción **Ejecutar script de shell** (Run Shell Script).
4.  Pega la ruta absoluta a tu script:
    ```bash
    /Users/TU_USUARIO/ruta/al/repo/bin/toggle_monitor.sh
    ```
5.  Guarda como `ToggleMonitor.app` y ponle un icono personalizado.

## 📂 Estructura del Proyecto

*   `bin/toggle_monitor.sh`: Lógica principal del toggle (detección y cambio).
*   `bin/reenable-displays.py`: Script avanzado en Python que usa la librería `CoreGraphics` para resetear configuraciones de pantalla.

---
*Basado en la configuración personalizada de Alexis Lopez.*
