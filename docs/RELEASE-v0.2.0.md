# Logical Unplug v0.2.0

Comparte un monitor entre tu Mac y otra computadora sin desconectar cables. Esta versión convierte el script original en una app nativa con controles gráficos.

## Novedades

- Selección del monitor desde una lista, sin nombres ni identificadores fijos.
- Desactivación y reactivación desde la ventana o la barra de menús.
- Estado de macOS actualizado cada dos segundos y elección guardada.
- Botón Recuperar pantallas para salidas que ya no aparecen.
- Protección de la pantalla principal e integrada y mensajes de error visibles.
- Icono propio y comandos de terminal opcionales.
- No requiere Python, Homebrew ni displayplacer.

## Instalación

Descarga **LogicalUnplug-v0.2.0-macOS-arm64.zip**, descomprímelo y arrastra **LogicalUnplug.app** a Aplicaciones.

**Plataforma:** Apple Silicon (M1 o posterior), compilación con mínimo macOS 13. Verificada localmente la compilación, el arranque, la detección de pantallas y 11 casos de lógica en un Mac M4/macOS 26. El ciclo físico de cambio de entrada con esta versión requiere validación en tu monitor; no se garantiza compatibilidad con todos los equipos.

**Firma:** ad hoc; todavía sin Developer ID ni notarización. macOS puede requerir autorizar la primera apertura en Ajustes del Sistema → Privacidad y seguridad. [Guía de Apple](https://support.apple.com/en-ca/guide/mac-help/mh40616/mac).

## Cómo funciona

La app desactiva la salida de video del Mac. Si el monitor tiene búsqueda automática de señal, puede cambiar al cable de la otra computadora. Al reactivarlo, puede hacer falta seleccionar la entrada del Mac. La app no controla la selección física de entrada ni el teclado o ratón.

Recuperar pantallas intenta reactivar todas las salidas ocultas compatibles y solo se ejecuta cuando lo solicitas. El control usa una API privada de macOS que puede cambiar en futuras versiones.

## Créditos

Alexis Lopez; @alex-konkov por el mecanismo de recuperación original; Jake Hilborn/displayplacer como herramienta de la versión inicial y referencia técnica, sin ser dependencia de esta release. Icono generado con OpenAI ImageGen y captura aportada por Alexis Lopez.
