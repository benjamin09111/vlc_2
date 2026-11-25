# Simulación de un enlace VLC en una galería de minería subterránea

Proyecto 2 del curso *Comunicaciones por luz visible para industrias inteligentes* (Universidad Diego Portales). Este repositorio contiene el simulador en MATLAB, los scripts de generación de figuras, la demostración interactiva, los datos de salida, el manuscrito en LaTeX y la presentación del proyecto.

El trabajo modela un enlace de comunicaciones por luz visible (VLC) en una galería subterránea ($26 \times 5 \times 4\text{ m}$) sometida a polvo en suspensión, temperatura elevada, obstrucciones móviles (proceso de Poisson) e interferencia luminosa, y lo compara con Wi-Fi IEEE 802.11n (2.4 GHz) y un esquema híbrido VLC/Wi-Fi en términos de confiabilidad (BER) y eficiencia (Goodput).

---

## 1. Requisitos

- **MATLAB R2021a o posterior** (desarrollado y verificado en **MATLAB R2026a**).
- **No se requieren *toolboxes* adicionales.**

---

## 2. Tutorial rápido: cómo ejecutar el simulador y reproducir los resultados

### Paso 1: Clonar o descargar el repositorio
```bash
git clone https://github.com/benjamin09111/vlc_2.git
```
*(O descargar el ZIP desde GitHub y descomprimirlo).*

### Paso 2: Abrir MATLAB y ubicarse en la carpeta `software/`
Al abrir MATLAB, pegue el siguiente comando en la ventana de comandos (*Command Window*) ajustando la ruta si es necesario, o navegue hasta la carpeta `software/` dentro del repositorio:

```matlab
cd('software'); addpath(genpath(pwd));
```

> **Tip:** Si prefiere un comando directo desde cualquier ubicación en Windows, reemplace la ruta por la de su equipo, por ejemplo:
> ```matlab
> cd('C:\ruta\a\vlc_2\software'); addpath(genpath(pwd));
> ```

### Paso 3: Ejecutar la simulación principal (tablas de resultados)
Copie y pegue en MATLAB:
```matlab
resultados = ejecutar_simulacion();
```
- **Tiempo estimado:** ~6–7 segundos.
- **Qué hace:** Ejecuta los 43 escenarios (40 réplicas Monte Carlo de 24 s cada una) y guarda las tablas completas en:
  - `resultados/datos/resultados.csv` (BER, Goodput e intervalos de confianza del 95 %)
  - `resultados/datos/escenarios.csv` (ganancias de canal, bloqueos, disponibilidad Wi-Fi y métricas del selector)

### Paso 4: Ejecutar la demostración interactiva en tiempo real (opcional)
Para abrir la interfaz visual interactiva de la galería en 3D y variar en vivo el polvo, temperatura, suciedad de lentes, obstrucciones e interferencia:
```matlab
demo_vlc();
```
- La primera ejecución tarda ~40 s en calcular la malla del canal (luego queda en caché). También existe un video de respaldo en `resultados/video/demo_vlc.mp4`.

### Paso 5: Regenerar todas las figuras y experimentos adicionales (opcional)
```matlab
mitigaciones();         % Experimentos de mitigación -> resultados/datos/mitigaciones.csv
figura_escenario();     % Esquema de la galería -> resultados/figuras/ y paper/figuras/
figuras_validacion();   % Respuesta al impulso y validación BER
figuras_resultados();   % Todas las figuras de resultados (~40 s por mapa de cobertura)
```
*(Opcional: `densidad_luminarias()` recalcula el análisis estático de densidad de luminarias en ~4 minutos).*

### Paso 6: Ejecutar las pruebas automáticas de verificación
Para comprobar que todos los modelos físicos, balances de potencia, validaciones analíticas y la demostración pasan sin errores:
```matlab
ejecutar_pruebas('Rapido', true);
```
- El resultado de cada prueba se imprime en consola y se guarda en `docs/registro_pruebas.csv`.

---

## 3. Estructura del repositorio

| Carpeta / Archivo | Contenido |
|---|---|
| `software/` | Simulador (`ejecutar_simulacion.m`), parámetros (`config/parametros.m`), modelos físicos (`modelos/`), estrategias (`estrategias/`), gráficos (`graficos/`), demo (`demo/`) y pruebas (`pruebas/`) |
| `resultados/datos/` | Archivos CSV con los resultados de las simulaciones (`resultados.csv`, `escenarios.csv`, `mitigaciones.csv`, `cobertura_perfil.csv`, `densidad.csv`) |
| `resultados/figuras/` | Figuras en PDF y PNG generadas por el simulador |
| `resultados/video/` | Video de respaldo de la demostración interactiva (`demo_vlc.mp4`) |
| `paper/` | Manuscrito en LaTeX (`main.tex`) y figuras vectoriales (`paper/figuras/`) listas para compilar en Overleaf |
| `presentacion/` | Diapositivas de la presentación (`presentacion_vlc.pptx`) |
| `docs/` | Diseño del software (`DISENO.md`), especificación de pruebas (`PRUEBAS.md`) y registro de pruebas (`registro_pruebas.csv`) |

Todos los parámetros físicos y supuestos del simulador están centralizados en `software/config/parametros.m` con su unidad y fuente.

---

## 4. Modelo de referencia

El canal óptico sigue el modelo de P. Palacios Játiva *et al.*, "A VLC Channel Model for Underground Mining Environments With Scattering and Shadowing", *IEEE Access*, vol. 8, pp. 185445–185464, 2020.

## 5. Autores

- **Benjamín Morales** (`benjamin.morales3@mail.udp.cl`) — Escuela de Informática y Telecomunicaciones, Universidad Diego Portales, Santiago, Chile.
- **Philip Magna** (`philip.magna_d@mail.udp.cl`) — Escuela de Informática y Telecomunicaciones, Universidad Diego Portales, Santiago, Chile.
