# Simulación de un sistema VLC en un entorno industrial hostil

Proyecto 2 del curso *Comunicaciones por luz visible para industrias inteligentes*. El trabajo simula un enlace de comunicaciones por luz visible (VLC) en una galería de minería subterránea y evalúa su confiabilidad (tasa de error de bit, BER) y su eficiencia (Goodput) frente a polvo, temperatura elevada, maquinaria móvil e interferencia luminosa. Se compara con un enlace Wi-Fi 2.4 GHz y con un esquema híbrido.

**Estado:** simulación, demostración, paper y presentación completos (Fases 0 a 9). Pendiente: autores y afiliaciones, compilación del paper en Overleaf y la fecha real de entrega (ver `docs/LISTA_COMPROBACION.md`). Detalle por fase en `docs/REGISTRO_EJECUCION.md`.

## 1. Requisitos

- MATLAB R2021a o posterior. Desarrollado y probado en R2026a.
- No se requieren toolboxes adicionales.

## 2. Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `software/` | Simulador, modelos, estrategias, métricas, gráficos, demostración y pruebas |
| `resultados/datos/` | Archivos CSV con los resultados de las simulaciones |
| `resultados/figuras/` | Figuras generadas por el simulador |
| `paper/` | Documento del trabajo (`main.tex`) y sus figuras (`paper/figuras/`) |
| `docs/` | Diseño del software, plan de pruebas, registro de ejecución y enunciado |
| `presentacion/` | Diapositivas (`presentacion_vlc.pptx`, con notas del orador, generada por `generar_presentacion.js`) y preguntas probables |
| `resultados/video/` | Video de respaldo de la demostración (`demo_vlc.mp4`) |
| `legacy/` | Versión v3 desarrollada previamente por el equipo, conservada sin modificaciones |

## 3. Uso

Abrir MATLAB en la carpeta `software/` y ejecutar:

```matlab
addpath(genpath(pwd));        % registra las subcarpetas
resultados = ejecutar_simulacion();   % simulación de la galería; escribe resultados.csv y escenarios.csv en ../resultados/datos/
ejecutar_pruebas();           % pruebas; escribe ../docs/registro_pruebas.csv
```

`ejecutar_simulacion('Guardar', false)` calcula sin escribir archivos y `ejecutar_simulacion('Perfil', 'v3')` ejecuta el modelo heredado de v3 (solo para la prueba de regresión). La simulación completa tarda unos segundos. Las figuras de validación se generan con `figuras_validacion()` (escribe en `resultados/figuras/` y copia los PDF a `paper/figuras/`). Las figuras de resultados se generan con `figuras_resultados()` (usa los CSV de `resultados/datos/`; el mapa de cobertura tarda un minuto) y los experimentos de mitigación con `mitigaciones()`. Las pruebas son 25. La densidad de luminarias se calcula con `densidad_luminarias()` (unos 4 minutos). La demostración interactiva se abre con `demo_vlc()` (desde `software/`; el primer arranque tarda unos 40 s en calcular el canal de la malla, que luego queda en caché; tiene pestañas de simulación, vista 3D, cobertura y densidad) y el video de respaldo se regenera con `demo_grabar()` (unos 4 minutos; escribe `resultados/video/demo_vlc.mp4`).

Todos los parámetros están en `software/config/parametros.m`, con su unidad y su origen.

## 4. Documentación

| Documento | Contenido | Norma de referencia |
|---|---|---|
| `docs/DISENO.md` | Descripción de diseño del software | IEEE 1016 |
| `docs/PRUEBAS.md` | Casos de prueba y resultados | ISO/IEC/IEEE 29119-3 |
| `docs/REGISTRO_EJECUCION.md` | Bitácora de ejecución por fase | — |
| `docs/CAMBIOS.md` | Historial de versiones | — |
| `docs/LISTA_COMPROBACION.md` | Contraste del trabajo con los objetivos y entregables del enunciado | — |
| Este archivo | Manual de usuario | ISO/IEC/IEEE 26514 |

## 5. Modelo de referencia

El canal óptico sigue el modelo de P. Palacios Játiva et al., "A VLC Channel Model for Underground Mining Environments With Scattering and Shadowing", *IEEE Access*, vol. 8, pp. 185445–185464, 2020. Los parámetros y sus fuentes se documentan en `software/config/` y en el paper.

## 6. Autores

- **Benjamín Morales** (`benjamin.morales3@mail.udp.cl`) — Escuela de Informática y Telecomunicaciones, Universidad Diego Portales, Santiago, Chile.
- **Philip Magna** (`philip.magna@mail.udp.cl`) — Escuela de Informática y Telecomunicaciones, Universidad Diego Portales, Santiago, Chile.

## 7. Licencia

Sin licencia definida. Los PDF de terceros usados como referencia no se incluyen en el repositorio (se citan en el paper).
