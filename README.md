# 🔌 logical-monitor-unplug

Script y lanzador de macOS para realizar una **desconexión lógica** (soft-unplug) de un monitor externo específico.

## 📌 ¿Para qué sirve?

Soluciona el problema de los monitores que macOS no reconoce correctamente o que necesitan ser "reconectados" sin tener que desenchufar físicamente el cable. 

Este script hace lo siguiente:
1.  **Logical Unplug:** Desactiva un monitor específico por su ID vía software.
2.  **Logic Refresh:** Reactiva todos los monitores forzando una configuración de `CoreGraphics` (usando un script de Python).

## 🛠️ Requisitos

*   **macOS** (Apple Silicon/Intel).
*   **[displayplacer](https://github.com/jakehilborn/displayplacer)**: 
    ```bash
    brew tap jakehilborn/jakehilborn
    brew install displayplacer
    ```
*   **Python 3**: Para el script de reseteo.

## 🚀 Instalación y Uso

1.  Clona este repositorio o descarga los archivos.
2.  Permisos:
    ```bash
    chmod +x bin/toggle_monitor.sh
    chmod +x bin/reenable-displays.py
    ```
3.  Busca tu ID de monitor: `displayplacer list`.
4.  Configura el `DEFAULT_MONITOR_ID` en `bin/toggle_monitor.sh`.

### 🍎 App Launcher (Recomendado)

Para usarlo desde el Dock sin terminal:
1.  Abre **Automator** > **Nueva Aplicación**.
2.  Añade **Ejecutar script de shell**.
3.  Pega la ruta absoluta a: `/Users/alexislopez/Documents/dev-projects/logical-monitor-unplug/bin/toggle_monitor.sh`.
4.  Guarda como `LogicalUnplug.app`.

## 📂 Estructura

*   `bin/toggle_monitor.sh`: Control del toggle (lógica principal).
*   `bin/reenable-displays.py`: Script avanzado de bajo nivel (CoreGraphics).

## 📝 Notas Técnicas

El componente `reenable-displays.py` es una pieza clave que utiliza la librería `CoreGraphics` de macOS a través de `ctypes`. Utiliza funciones como `CGSConfigureDisplayEnabled` (parte de las APIs privadas de Apple) para forzar la reactivación de monitores. Esta es una técnica avanzada para "despertar" pantallas que han quedado en un estado lógico de desconexión sin necesidad de manipular cables físicos.

---
*Alexis Lopez - 2026*
