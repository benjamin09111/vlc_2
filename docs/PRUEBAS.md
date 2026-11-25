# Plan y registro de pruebas

Documento estructurado según ISO/IEC/IEEE 29119-3, en versión resumida. Las pruebas se ejecutan con `software/pruebas/ejecutar_pruebas.m`, que escribe `docs/registro_pruebas.csv`.

## 1. Casos de prueba

| ID | Objetivo | Criterio de aceptación | Estado |
|---|---|---|---|
| P-01 | No regresión: el código reestructurado reproduce la línea base v3 | Las 80 filas de resultados coinciden con v3 con la misma semilla (diferencia máxima < 10⁻⁹) | Aprobada (Fase 2) |
| P-02 | La potencia recibida en LOS decae como 1/d² | Pendiente del ajuste log–log igual a −2 (tolerancia 0.01) | Aprobada (Fase 2) |
| P-03 | Con concentración de polvo nula, la extinción es nula | α(C = 0) = 0 y transmisión igual a 1 | Aprobada (Fase 3) |
| P-04 | Sin maquinaria no hay bloqueo | Ningún paquete bloqueado con 0 máquinas activas | Aprobada (Fase 2) |
| P-05 | A mayor temperatura, menor potencia óptica y mayor ruido | Monotonía estricta en 20–60 °C, con ambos disipadores; factor térmico igual a 1 en la referencia; el disipador mejorado siempre entrega más potencia | Aprobada (Fase 4) |
| P-06 | Intersección segmento–caja en casos conocidos | Los 6 casos manuales coinciden | Aprobada (Fase 2) |
| P-07 | Sin reflectividad de pared no hay componente NLOS | Ganancia NLOS igual a 0 con ρ = 0 | Aprobada (Fase 3) |
| P-08 | El Goodput no supera la tasa nominal útil | Goodput ≤ R_b·L/(L+n_p) en todas las filas del perfil `mina` | Aprobada (Fase 4) |
| P-09 | Reciprocidad del canal reflejado | Ganancia total igual al intercambiar emisor y receptor (m = 1, campo de visión de 90°); diferencia relativa < 10⁻⁹ | Aprobada (Fase 3) |
| P-10 | Convergencia de la discretización de las paredes | Ganancia reflejada total con elementos de 0.10 m y de 0.02 m con diferencia relativa < 1 % | Aprobada (Fase 3) |
| P-11 | Bloqueo por obstáculo cilíndrico en casos conocidos | 7 casos manuales (incluye enlace vertical y ancho nulo) | Aprobada (Fase 3) |
| P-12 | El ruido térmico coincide con el cálculo manual | Diferencia relativa < 10⁻⁹ con el valor calculado a mano de las ecuaciones (39) de [PJ2020] a 10 Mb/s y 25 °C | Aprobada (Fase 4) |
| P-13 | Convergencia de la discretización en la galería | Ganancia reflejada con elementos de 0.5 m y de 0.1 m con diferencia relativa < 3 % | Aprobada (Fase 4) |
| P-15 | La tasa nominal es compatible con la dispersión temporal | R_b < 1/(10·D_RMS) en ambas luminarias | Aprobada (Fase 4) |
| V-01 | Reproducción del escenario de referencia de Palacios Játiva et al. (2020) | Relación entre el máximo reflejado y el directo con diferencia relativa < 15 % respecto de 11.47 % (valor del artículo); reflexiones posteriores al pulso directo; D_RMS en [9.01·10⁻¹², 8.28·10⁻⁹] s | Aprobada (Fase 3), con reservas (ver 3) |
| V-02 | BER por simulación de bits frente a la expresión analítica | Desviación < 4 desviaciones estándar binomiales en 5 amplitudes, 2·10⁶ bits cada una | Aprobada (Fase 3) |
| V-03 | Bloqueo por obstáculos de Poisson frente a la ponderación analítica | Diferencia < 4 errores estándar entre la fracción bloqueada simulada y 1 − exp(−ε·T_d·E[p]) | Aprobada (Fase 3) |
| V-04 | BER simulada frente a la BER teórica condicionada al canal del escenario | En las filas con BER teórica > 10⁻⁵, desviación < 4 errores estándar entre réplicas | Aprobada (Fase 4) |
| V-05 | Bloqueo simulado con adelgazamiento de Poisson frente a la ponderación analítica | Diferencia < 4 errores estándar con 2000 réplicas, ε = 10 por minuto | Aprobada (Fase 4) |

| W-01 | Balance de potencia del enlace Wi-Fi frente al cálculo manual | Pr igual al cálculo manual (diferencia < 10⁻⁹ dB), MCS 8 y tasa igual a la carga ofrecida de 10 Mb/s sin bloqueo ni interferencia | Aprobada (Fase 5) |
| W-02 | El MCS no crece con la interferencia electromagnética y es menor con bloqueo | Monotonía de 0 a 70 dB en pasos de 5 dB; MCS bloqueado ≤ MCS libre; enlace caído a 70 dB | Aprobada (Fase 5) |
| W-03 | Casos límite del híbrido | En la referencia (VLC sano) el híbrido coincide con el selector práctico; con 2000 mg/m³ (VLC caído) coincide con el Wi-Fi (diferencia < 10⁻⁹) | Aprobada (Fase 5) |
| D-01 | La traza de la demostración reproduce los resultados de la simulación | BER y Goodput acumulados al final del ciclo coinciden con la tabla de `ejecutar_escenarios_mina` para las seis arquitecturas (diferencia < 10⁻¹²) | Aprobada (Fase 7) |
| D-02 | La ventana interactiva se construye, avanza y recorre sus cuatro pestañas | Creación sin mostrar, 30 pasos y selección de las pestañas 3D, cobertura y densidad sin error | Aprobada (Fase 7, ampliada) |
| D-03 | El margen de la demostración coincide con el de la simulación | `margen_enlace` con 2 LEDs fijos en la referencia igual a 20 log₁₀ del margen de la simulación (diferencia < 10⁻⁶ dB) | Aprobada |

## 2. Registro de resultados

Entorno: Windows 10, MATLAB R2026a (26.1), sin toolboxes adicionales. Fecha: 2026-11-24.

| ID | Resultado obtenido | Aprobada |
|---|---|---|
| P-01 | 80 filas; diferencia máxima 5·10⁻¹⁶ respecto de la referencia de v3 | Sí |
| P-02 | Pendiente log–log = −2.000000 | Sí |
| P-03 | α(C = 0) = 0; transmisión = 1 | Sí |
| P-04 | 0 paquetes bloqueados con 0 máquinas | Sí |
| P-06 | 6 de 6 casos correctos | Sí |
| P-07 | Suma de ganancias reflejadas = 0 | Sí |
| P-09 | Ganancias 4.55592·10⁻⁷ en ambos sentidos; diferencia relativa 0 | Sí |
| P-10 | Diferencia relativa de la ganancia total 4.9·10⁻⁴ | Sí |
| P-11 | 7 de 7 casos correctos | Sí |
| P-05 | Factor térmico de 1.025 (20 °C) a 0.825 (60 °C) con disipador estándar; 1.000 a 25 °C; ruido creciente | Sí |
| P-08 | Goodput máximo 9.4118 Mb/s = tope 9.4118 Mb/s | Sí |
| P-12 | Modelo 1.002·10⁻⁸ A; manual 1.002·10⁻⁸ A | Sí |
| P-13 | Diferencia relativa 0.025 | Sí |
| P-15 | D_RMS 0.0752 ns; 1/(10 D_RMS) = 1330 Mb/s; R_b = 10 Mb/s | Sí |
| V-01 | Relación reflejado/directo 10.11 % (artículo 11.47 %; diferencia 11.8 %); con el factor 1/π, 3.22 %; D_RMS 0.296 ns; reflexiones posteriores al pulso directo | Sí |
| V-02 | Peor desviación 1.76 desviaciones estándar en 5 puntos | Sí |
| V-03 | Simulado 0.0237 ± 0.0022; analítico 0.0212 (E[p] = 0.0021) | Sí |
| V-04 | 78 filas (ahora incluye Wi-Fi e híbrido); peor desviación 1.82 errores estándar | Sí |
| V-05 | Simulado 0.1133 ± 0.0063; analítico 0.1088 (E[p] = 0.0230) | Sí |
| W-01 | d = 5.39 m; Pr = −36.14 dBm (modelo y manual); MCS 8; 10.00 Mb/s | Sí |
| W-02 | MCS de 8 a 0 sin bloqueo y de 8 a 0 con bloqueo, monótono | Sí |
| W-03 | Diferencia en la referencia 1.2·10⁻¹⁴; con polvo de 2000 mg/m³, 0 | Sí |
| D-01 | Diferencia máxima de BER 5.2·10⁻¹⁸ y de Goodput 2.4·10⁻¹⁴ Mb/s | Sí |
| D-02 | Ventana creada, 30 pasos y cuatro pestañas | Sí |
| D-03 | Demostración 46.1611 dB; simulación 46.1611 dB | Sí |

Comprobaciones internas permanentes en `ejecutar_escenarios.m` y `ejecutar_escenarios_mina.m` (fallan con error si no se cumplen): BER finita y en [0, 1]; Goodput en [0, tasa nominal]; el selector ideal nunca tiene más errores ni menos Goodput que el LED único bajo la misma realización de ruido.

## 3. Reservas sobre la validación V-01

1. **Magnitud absoluta no reproducida.** Con los parámetros de la Tabla 3 del artículo, el pulso directo del escenario de referencia resulta 1.04·10⁻⁵, frente a 3.489·10⁻⁵ informado. No se identificó la causa (factor 3.36). La validación se limita a la relación entre componentes, que no depende de las ganancias comunes (área del detector, concentrador).
2. **Factor 1/π.** La relación del artículo (11.47 %) solo se aproxima con la expresión de la ganancia reflejada tal como está impresa, que omite el factor 1/π de la reemisión lambertiana de la pared respecto de la formulación clásica de Kahn y Barry y de Komine y Nakagawa. El simulador usa el factor completo, que da 3.22 %. No es posible saber si la omisión es tipográfica o forma parte de la implementación del artículo.
3. **Tolerancia fijada tras explorar.** La tolerancia de 15 % de V-01 se fijó después de haber visto que el resultado ronda 10–11 % según la resolución de los elementos; el artículo no informa el tamaño de elemento utilizado. La diferencia de 11.8 % está dentro de esa tolerancia, pero el criterio no era independiente del resultado.
4. **Segunda contribución reflejada.** El artículo muestra una segunda contribución reflejada alrededor de 28 ns; el modelo la sitúa en torno a 17.8 ns (pared lejana). No se identificó el origen de la diferencia.
5. **Alcance.** El escenario de referencia no incluye paredes irregulares ni dispersión por polvo; la relación entre el pulso directo y el reflejado de esos efectos no se validó.

## 4. Observaciones de la prueba V-05

Con 400 réplicas, V-05 dio una diferencia de 2.8 errores estándar (aprobada con tolerancia de 4). Para descartar un sesgo se repitió con 4000 réplicas y tres intensidades de llegada (5, 10 y 40 por minuto): las diferencias fueron de 0.2, 0.8 y 1.6 errores estándar, y el número medio de obstrucciones presentes coincidió con ε·T_d (2.52 frente a 2.50, 5.02 frente a 5.00 y 19.94 frente a 20.00). La prueba se fijó en 2000 réplicas.

## 5. Límites de las pruebas del Wi-Fi

W-01 a W-03 comprueban que el modelo implementa lo que se declara (balance de potencia, monotonía y coherencia del híbrido). **No validan** el canal de RF contra mediciones: el exponente de pérdida y el sombreado son hipótesis (no se pudieron verificar los valores de Tanghe et al. (2008) a 2.4 GHz), y la tabla MCS y las sensibilidades provienen de la norma IEEE 802.11n tal como se recuerdan, sin haberlas verificado en una fuente leída en esta sesión. V-04 compara la BER simulada del Wi-Fi con su valor teórico, pero ambos salen del mismo modelo.
