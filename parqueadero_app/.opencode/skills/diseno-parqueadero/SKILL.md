---
name: diseno-parqueadero
description: Sistema de diseño visual de la app del parqueadero. Úsala siempre que se cree o modifique una pantalla, un widget, un color, un espaciado o una animación en parqueadero_app. Frases que la activan: "crea la pantalla de", "rediseña", "ajusta el estilo", "agrega un widget", "cambia el color", "haz que se vea mejor", "nueva vista de".
---

# Sistema de diseño — App de Parqueadero

## Concepto

La identidad visual sale del objeto real: **asfalto oscuro con demarcación
amarilla pintada**. Un parqueadero no es verde ni rojo; es concreto, asfalto y
líneas amarillas. Toda decisión estética se deriva de ahí.

La audacia se concentra en **un solo lugar: la cuadrícula de celdas**. Todo lo
demás —formularios, listados, diálogos— es deliberadamente tranquilo. Si una
pantalla que no es la cuadrícula empieza a llamar la atención, está mal.

Contexto de uso: operador de pie, una mano, luz solar directa, misma tarea
decenas de veces por turno, cliente esperando. Nada puede cansar ni distraer.

## Paleta

Definida en `core/theme/app_colors.dart`. Ninguna pantalla declara un color.

| Token         | Hex       | Uso                                              |
| ------------- | --------- | ------------------------------------------------ |
| `asfalto`     | `#101A14` | barras, celdas ocupadas, fondos de énfasis       |
| `verdeSenal`  | `#1B6B45` | acciones primarias, confirmaciones               |
| `demarcacion` | `#F2C230` | líneas, bordes de bahía, acentos                 |
| `concreto`    | `#F8F7F2` | superficie base                                  |
| `linea`       | `#E3E0D6` | divisores, bordes suaves                         |
| `tinta`       | `#12150F` | texto                                            |

### Reglas de color innegociables

1. **`demarcacion` NUNCA es texto sobre fondo claro.** Da 1.7:1 de contraste,
   ilegible. Solo vive sobre `asfalto`, o como línea, borde y relleno.
2. Todo texto pasa **WCAG AA (4.5:1)** sobre la superficie donde se usa. Existe
   un test de regresión que calcula el contraste real; si lo rompes, se arregla
   el color, no el test.
3. El estado de una celda **no se comunica con matiz de color**. Ver la sección
   siguiente.

## La cuadrícula: bahías pintadas

Es el elemento firma de la app. Cada celda se dibuja como una bahía de
parqueo real, y el estado se lee por **relleno y contenido**, no por color:

- **LIBRE** — bahía vacía, fondo `concreto`, delineada en `demarcacion`.
  Se lee como un espacio disponible porque está vacía.
- **OCUPADA** — bahía rellena de `asfalto`, con la placa en `demarcacion` y el
  tiempo transcurrido. Se lee como ocupada porque hay algo adentro.
- **MANTENIMIENTO** — bahía con rayado diagonal, como el achurado real de una
  vía cerrada. Se lee como zona bloqueada.

Esto es a propósito accesible: se distingue a distancia, bajo sol directo, y
sin depender de la percepción cromática. **No agregues un chip de color encima
para "reforzar" el estado**: eso deshace el sistema.

Las estadías largas se señalan con la intensidad del borde de `demarcacion`,
que aumenta gradualmente con el tiempo. Nunca con un cambio de matiz.

## Tokens estructurales

Todos en `core/theme/`. Nunca uses un literal aunque coincida con la escala.

- `AppSpacing` — 4 / 8 / 12 / 16 / 24 / 32
- `AppRadius` — 8 / 12 / 16
- `AppElevation` — 0 / 1 / 3
- `AppMotion` — 150 / 200 / 250 ms, curva `easeInOutCubic`, sin rebote

`AppMotion.effective(context, duration)` es el **único** punto que consulta la
preferencia de movimiento reducido del sistema. Toda animación pasa por ahí.

## Movimiento

- Duraciones cortas: 150–250 ms. Nada rebota, nada gira, nada llama la
  atención sobre sí mismo.
- Ninguna animación puede retrasar una acción del operador.
- El cambio de estado de una celda anima desde la celda tocada, no con un
  refresh del grid completo.
- Feedback táctil en cada acción (`tapFeedback()`).

## Rendimiento de la cuadrícula

Estas optimizaciones existen y no se pueden perder al agregar estilo:

- `CeldaCard` recibe solo `celdaId` y lee su dato con
  `ref.watch(provider.select(...))`. Cambiar una celda no reconstruye las demás.
- Cada tarjeta va envuelta en `RepaintBoundary` con `ValueKey(celda.id)`.
- Un **solo timer compartido** actualiza los tiempos transcurridos, nunca uno
  por tarjeta, y se cancela al salir de la pantalla.
- `const` en todo lo que pueda serlo.

## Escritura de interfaz

- Voz activa, y el botón dice exactamente qué pasa: "Registrar salida", no
  "Enviar". La acción conserva el mismo nombre en todo el flujo.
- Los errores explican **qué hacer**, no solo qué falló. Cuando un código de
  error tiene una acción posible, se ofrece como botón (patrón de
  `OPERADOR_SIN_TURNO_ABIERTO` → botón "Abrir turno").
- Los mensajes de error del backend se muestran **verbatim**; la app no los
  reescribe.
- Una pantalla vacía es una invitación a actuar, no solo un texto gris.

## Antes de dar por terminada una pantalla

- [ ] Maneja los tres estados: cargando (skeleton con la forma real del
      contenido), error (con reintentar) y vacío (con acción sugerida).
- [ ] Ningún color, radio, espaciado o duración fuera de los tokens.
- [ ] Objetivos táctiles ≥ 48 dp; los botones principales, 56 dp.
- [ ] El botón de submit no queda tapado por el teclado.
- [ ] Contraste AA verificado sobre la superficie real.
- [ ] Movimiento reducido respetado.
- [ ] `flutter analyze` limpio y `flutter test` en verde.
