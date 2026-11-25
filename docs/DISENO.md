# Descripción de diseño del software

Documento estructurado según IEEE 1016, en versión resumida. Se completa a medida que se implementa cada módulo.

## 1. Propósito y alcance

Simulador en MATLAB de un enlace VLC en una galería de minería subterránea. Calcula BER y Goodput para distintas arquitecturas de transmisión, bajo condiciones hostiles configurables, y las compara con un enlace Wi-Fi.

Convenciones de código: nombres de funciones y variables en español, comentarios de encabezado con propósito, entradas, salidas (con unidades) y referencia del modelo. Los archivos `.m` usan solo caracteres ASCII (sin tildes) para evitar problemas de codificación entre versiones y sistemas de MATLAB.

## 2. Vista de módulos

| Módulo | Responsabilidad | Entradas | Salidas | Estado |
|---|---|---|---|---|
| `ejecutar_simulacion.m` | Punto de entrada: fija la semilla, genera las réplicas, ejecuta los escenarios y escribe los CSV | Opciones (`Guardar`, `Cfg`) | Estructura con tablas | Fase 2 |
| `config/parametros.m` | Parámetros del sistema con unidad y origen | — | Estructura `cfg` | Fase 2 (valores de v3) |
| `modelos/canal_los.m` | Ganancia lambertiana con línea de vista | `tx`, `rx`, `cfg` | `H`, `d` | Fase 2 |
| `modelos/extincion_polvo.m` | Extinción por polvo (Beer–Lambert) | `cfg` | `k`, `alpha` | Fase 2 |
| `modelos/maquinaria.m`, `caja_maquina.m` | Máquinas móviles como cajas oscilantes | `cfg`, `t`, fase | Cajas envolventes | Fase 2 |
| `modelos/interseccion_aabb.m`, `bloqueos_activos.m` | Bloqueo de la línea de vista | Segmento, caja | Estado de bloqueo | Fase 2 |
| `modelos/canal_nlos.m`, `paredes_caja.m` | Primera reflexión difusa en superficies planas discretizadas | Posición y eje de emisor y receptor, paredes, `cfg` | Ganancia y retardo por elemento | Fase 3 |
| `modelos/respuesta_impulso.m` | Respuesta al impulso discretizada, D_RMS y tasa máxima sin ISI | Ganancias y retardos | Respuesta, D_RMS, μ | Fase 3 |
| `modelos/obstaculos_poisson.m`, `bloquea_cilindro.m`, `bloqueo_serie.m`, `peso_sombra.m` | Obstáculos de Poisson, bloqueo exacto por cilindros y ponderación esperada | `cfg`, enlace, instantes | Estado de bloqueo; probabilidad de enlace libre | Fase 3 (aún no integrados en `ejecutar_escenarios`; Fase 4) |
| `simulacion/generar_replicas_mina.m` | Réplicas con obstrucciones de Poisson (adelgazamiento), bits, ruido e interferencia | `cfg` | Réplicas | Fase 4 |
| `simulacion/definir_escenarios.m` | Escenarios E0–E7 (una condición a la vez, combinado y temperatura con polvo denso) | `cfg` | Lista de escenarios | Fase 4 |
| `simulacion/ejecutar_escenarios_mina.m` | BER y Goodput de las cuatro arquitecturas VLC por escenario y réplica | `cfg`, canal, réplicas, escenarios | Tablas `resultados` y `escenarios` | Fase 4 |
| `estrategias/selector_practico_mina.m` | Selector con información imperfecta y ganancias con reflexión | Réplica, ganancias | Elección e interrupciones | Fase 4 |
| `simulacion/escenario_referencia.m` | Escenario de referencia de Palacios Játiva et al. (2020) para la validación V-01 | Resolución de la discretización | Respuesta al impulso y métricas | Fase 3 |
| `modelos/canal_galeria.m` | Canal estático de la galería: ganancias LOS, elementos reflejantes y su probabilidad de bloqueo, D_RMS | `cfg`, receptor | Estructura de canal | Fase 4 |
| `modelos/ganancias_escenario.m` | Aplica polvo, lente y sombra esperada de las reflexiones a las ganancias | Canal, escenario | Ganancias LOS y NLOS por luminaria | Fase 4 |
| `modelos/modelo_termico.m` | Temperatura de juntura y potencia óptica relativa | Ta, Rth, `cfg` | Factor térmico, Tj | Fase 4 |
| `modelos/ruido_receptor.m` | Ruido de disparo y térmico del receptor | Potencia, fondo, temperatura | σ₀, σ₁ | Fase 4 |
| `modelos/enlace_rf_v3.m` | Enlace RF ilustrativo heredado (solo perfil `v3`) | `cfg`, bloqueo, bits | Errores por paquete | Fase 2 (reemplazado en el perfil `mina` por `enlace_wifi`) |
| `estrategias/selector_practico.m` | Selección de luminaria con información de canal imperfecta | Réplica, ganancias | Elección, interrupciones | Fase 2 |
| `metricas/media_intervalo.m` | Media e intervalo de confianza del 95 % entre réplicas | Valores por réplica | `mu`, `lo`, `hi` | Fase 2 |
| `simulacion/generar_replicas.m` | Réplicas independientes (fases, bits, ruido, bloqueos) | `cfg`, máquinas | Arreglo de réplicas | Fase 2 |
| `simulacion/ejecutar_escenarios.m` | Evaluación de BER y Goodput por escenario y arquitectura | `cfg`, réplicas | Tablas de resultados y diagnósticos | Fase 2 |
| `graficos/estilo_figura.m` | Paleta, formato y exportación comunes (PDF vectorial y PNG; copia el PDF a `paper/figuras/`) | — | Funciones de estilo | Fase 3 |
| `graficos/figuras_validacion.m` | Figuras de validación del canal y de la BER | — | `fig_validacion_cir`, `fig_validacion_ber` | Fase 3 |
| `graficos/figuras_resultados.m` | Figuras de resultados (cobertura, polvo, temperatura, obstrucciones, comparación con Wi-Fi, mitigaciones) y perfil de cobertura | CSV de `resultados/datos/`, canal estático | Seis figuras PDF y PNG, `cobertura_perfil.csv` | Fase 6 |
| `modelos/enlace_wifi.m` | Enlace Wi-Fi 802.11n con adaptación de tasa | Bloqueo, sombreado, interferencia, `cfg` | BER, tasa, MCS, disponibilidad | Fase 5 |
| `simulacion/mitigaciones.m` | Experimentos de mitigación (selector, lentes, tasa, híbrido) | `cfg` | `mitigaciones.csv` | Fase 5 |
| `demo/demo_vlc.m` | Ventana interactiva (`uifigure`): controles de polvo, temperatura, lentes, obstrucciones, interferencias, disipador, arquitectura y velocidad; reproduce en tiempo real un ciclo de 24 s | Opciones (`Visible`, `Automatico`) | Ventana; funciones `paso()` y `cerrar()` | Fase 7 |
| `demo/simular_ciclo.m` | Un ciclo de 24 s paquete a paquete con las funciones de la simulación (una réplica de `ejecutar_escenarios_mina` con trazas) | `cfg`, canal, condiciones, semilla | Traza y salida de la simulación | Fase 7 |
| `demo/metricas_traza.m` | BER acumulada, Goodput en ventana de 5 s y Goodput acumulado de las seis arquitecturas | Traza | Series | Fase 7 |
| `demo/vista_demo.m`, `textos_demo.m` | Dibujo común (galería, curvas y barras) y textos en español, compartidos por la ventana y el video | Ejes, traza, paquete actual | Gráficos | Fase 7 |
| `demo/vista3d_demo.m`, `mapa_cobertura_demo.m`, `canal_malla.m`, `enlaces_demo.m` | Vista 3D, mapa de cobertura reactivo (canal de la malla con caché), y selección de enlaces activos compartida | Traza, condiciones, malla | Gráficos | Extras |
| `simulacion/densidad_luminarias.m`, `graficos/dibujar_densidad.m`, `modelos/margen_enlace.m` | Cobertura y Goodput estáticos según el número de luminarias; gráfico común al paper y a la demostración; margen de 2 LEDs fijos | `cfg` | `densidad.csv`, `fig_densidad` | Extras |
| `demo/demo_grabar.m` | Video MP4 de respaldo con cuatro escenarios y réplicas representativas | Opciones | `resultados/video/demo_vlc.mp4` | Fase 7 |
| `pruebas/ejecutar_pruebas.m` | Pruebas unitarias y de no regresión | — | Informe y `docs/registro_pruebas.csv` | Fase 2 (parcial) |

## 3. Flujo de datos

`parametros` → `maquinaria` y `extincion_polvo` → `generar_replicas` (fases de las máquinas, bits, ruido, bloqueos observados y retrasados) → `ejecutar_escenarios` (para cada polvo × máquinas × arquitectura × réplica: potencia recibida, umbral de decisión, errores, disponibilidad) → BER y Goodput por réplica → `media_intervalo` → tablas CSV.

El orden de las llamadas al generador aleatorio en `generar_replicas` determina la reproducibilidad; no debe alterarse sin repetir la prueba P-01.

## 4. Modelos implementados

Se detallan aquí, con su ecuación y referencia, a medida que se incorporan (ver también las Secciones II y III de `paper/main.tex`).

| Modelo | Ecuación | Referencia |
|---|---|---|
| Orden lambertiano | m = −ln 2 / ln(cos Φ½) | Palacios Játiva et al. (2020), ec. (2) |
| Ganancia LOS | H = (m+1)·A_p / (2π d²) · cos^m(φ) · cos(ψ) · g(ψ) | ídem, ec. (5) |
| Extinción por polvo | α = 3 Q_ext C / (4 ρ r); transmisión exp(−α d) | Li et al. (2024), modelo monodisperso |
| Reflexión difusa (una sola) | H = Σ (m+1) A_p ρ ΔA / (2π² d₁² d₂²) · cos^m φ · cos α · cos β · cos ψ · g | Kahn y Barry (1997); Komine y Nakagawa (2004); Palacios Játiva et al. (2020), ec. (14) con el factor 1/π de la reemisión |
| Retardo RMS | D_RMS y μ por muestras de 0.25 ns | Palacios Játiva et al. (2020), ecs. (35)–(36) |
| Obstáculos de Poisson | Llegadas con intensidad ε, permanencia exponencial T_d (supuesto), cilindros de ancho y alto uniformes; P = exp(−ε T_d E[p]) | Palacios Játiva et al. (2020), ec. (15) |
| Ruido del receptor | σ² = 2qRP_r B + 2q(I_bg+I_d)I₂B + 8πκT_K/G·C_pd A_p I₂B² + 16π²κT_KΓ/g_m·(C_pd A_p)² I₃B³ | Palacios Játiva et al. (2020), ecs. (38)–(39); Komine y Nakagawa (2004) |
| Temperatura del LED | η(T_j) = η₀[1 − k_T(T_j − 25)]; T_j = T_a + R_th·(P_elec − η P_elec); potencia relativa a la de referencia | Hipótesis de hoja de datos de LED de potencia |
| Corriente oscura | I_d = I_d0·2^((T − 25)/10) | Hipótesis |
| Polvo en reflexiones | Cada trayecto se atenúa exp(−α L) con su longitud total | Extensión de la ecuación de extinción de v3 |
| Enlace Wi-Fi 802.11n | PL = PL₀ + 10 n log₁₀ d + S + L_obst; MCS más alto con P_r ≥ sensibilidad + EMI; tasa = mín(R_b, η_MAC·tasa PHY); BER de la modulación sin codificación | IEEE 802.11n (tabla MCS y sensibilidades); n y σ de S: hipótesis en el rango de Tanghe et al. (2008) a 868 MHz |
| Esquema híbrido | Wi-Fi si I_señal estimada < Q·σ₁ y Wi-Fi disponible; si no, VLC con selector práctico; un paquete perdido por cambio | Propio |
| Bloqueo por maquinaria (v3) | Intersección segmento–caja (método de las losas) | v3 |
| Selector práctico | Estimación retrasada y ruidosa, histéresis, corte al conmutar | v3 |
| Demostración | Reproducción de una réplica de la simulación (no un modelo aparte): el movimiento y el bloqueo son los de la réplica; al cambiar un control se simula un ciclo nuevo | Propio |

## 5. Supuestos y limitaciones

Los valores sin respaldo medido están marcados como `HIPOTESIS` en `config/parametros.m` y como supuesto en la Tabla II del paper. Resumen:

| Tema | Supuesto o limitación |
|---|---|
| Térmico | Eficiencia óptica a 25 °C, coeficiente de temperatura, resistencias térmicas de los dos disipadores y corriente oscura son hipótesis de hoja de datos |
| Polvo | Medio homogéneo que atenúa (Beer–Lambert) sin luz dispersada hacia el receptor; Q_ext y radio de [Li2024] sin verificación independiente; densidad de 1500 kg/m³ supuesta |
| Obstrucciones | Dimensiones, permanencia media de 30 s y posición uniforme supuestas; las reflexiones usan la sombra esperada, no su realización temporal |
| Canal óptico | Primera reflexión sobre superficies planas con reflectividad 0.6; un solo punto receptor en la simulación temporal; validación del escenario de referencia parcial (`PRUEBAS.md`, sección 3) |
| Interferencia | Corriente de fondo de 50 µA de los focos y barrido de 10 a 50 dB de interferencia electromagnética sin medición |
| Wi-Fi | Exponente 2.2, sombreado 5 dB, pérdida de 15 dB por maquinaria, eficiencia MAC 0.65, adaptación de tasa ideal, BER sin codificación, una sola distancia; tabla MCS y sensibilidades de IEEE 802.11n sin verificar en la norma |
| Híbrido | Umbral Q = 12 fijado a priori; el nivel recibido del Wi-Fi se mide sin retardo |
| Validación | No hay validación experimental (tampoco en [PJ2020]) |

La discusión completa está en la sección V del paper.
