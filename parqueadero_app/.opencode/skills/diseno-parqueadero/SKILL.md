---
name: diseno-parqueadero
description: Sistema de diseño visual de la app del parqueadero. Úsala siempre que se cree o modifique una pantalla, un widget, un color, un espaciado o una animación en parqueadero_app. Frases que la activan: "crea la pantalla de", "rediseña", "ajusta el estilo", "agrega un widget", "cambia el color", "haz que se vea mejor", "nueva vista de".
---

# Sistema de diseño — App de Parqueadero

> **Reforma "Asfalto y Demarcación" (2026-09-15).** Esta skill se reescribió por
> completo: el tema pasó de superficie **clara** (`concreto #F8F7F2`) a
> **oscura** (`asfaltoOscuro #1A1A1A`), y la paleta cambió de 6 a 8 tokens.
> Si encuentras código que usa `concreto`, `verdeSenal`, `demarcacion`, `linea`
> o `tinta`, es código **anterior a la reforma**: migrarlo es parte del trabajo,
> no lo dejes conviviendo con la paleta nueva.

## Concepto

La identidad visual sale del objeto real: **asfalto oscuro con demarcación
amarilla pintada**. Un parqueadero no es verde ni rojo; es concreto, asfalto y
líneas amarillas. Toda decisión estética se deriva de ahí.

La audacia se concentra en **un solo lugar: la cuadrícula de celdas**. Todo lo
demás —formularios, listados, diálogos— es deliberadamente tranquilo. Si una
pantalla que no es la cuadrícula empieza a llamar la atención, está mal.

Contexto de uso: operador de pie, una mano, luz solar directa, misma tarea
decenas de veces por turno, cliente esperando. Nada puede cansar ni distraer.
Un error de cobro cuesta dinero: la legibilidad y el objetivo táctil mandan
sobre la estética.

## Paleta

Definida en `core/theme/app_colors.dart`. Ninguna pantalla declara un color.

| Token            | Hex       | Uso                                                              |
| ---------------- | --------- | ---------------------------------------------------------------- |
| `asfaltoOscuro`  | `#1A1A1A` | Fondo raíz, celdas LIBRES, celdas MANTENIMIENTO                  |
| `asfaltoMedio`   | `#2B2B2B` | Tarjetas, AppBar, celdas OCUPADAS, contenedor de zona            |
| `asfaltoClaro`   | `#3D3D3D` | Bordes, divisores, botones secundarios, campos de búsqueda       |
| `amarilloPastel` | `#F2E85C` | Delineado de celdas, acentos, badges "Abierto"/"Admin"           |
| `verdePastel`    | `#9BCD9B` | Botón primario, badges "Pagado"/"Vigente"/"Operador"             |
| `blancoHueso`    | `#F5F5F0` | Texto principal sobre asfalto                                    |
| `grisClaro`      | `#B0B0A8` | Texto secundario, íconos inactivos, badges "Cerrado"             |
| `terracota`      | `#D97A5A` | Alertas, badge "Pendiente de arqueo", cerrar sesión              |

### Contraste real medido (WCAG 2.x)

No son estimaciones: están calculadas y verificadas por test.

| Color            | sobre `asfaltoOscuro` | sobre `asfaltoMedio` |
| ---------------- | --------------------- | -------------------- |
| `blancoHueso`    | 15.91:1               | 12.95:1              |
| `amarilloPastel` | 13.65:1               | 11.11:1              |
| `verdePastel`    | 9.61:1                | 7.82:1               |
| `grisClaro`      | 7.97:1                | 6.49:1               |
| `terracota`      | 5.70:1                | **4.64:1**           |

### Reglas de color innegociables

1. **`amarilloPastel` NUNCA es texto sobre fondo claro.** Sobre blanco puro da
   **1.27:1** — ilegible. Solo vive sobre asfalto, o como línea, borde y relleno.
2. Todo texto pasa **WCAG AA (4.5:1)** sobre la superficie donde se usa. Existe
   un test de regresión que calcula el contraste real; si lo rompes, se arregla
   el color, no el test.
3. **`terracota` sobre `asfaltoMedio` da 4.64:1**: pasa AA con sólo 0.14 de
   margen. No lo aclares ni lo uses sobre nada más claro que `asfaltoMedio` sin
   volver a medir.
4. El estado de una celda **no se comunica con matiz de color**. Ver la sección
   siguiente.
5. No se introducen colores fuera de esta tabla ni de la paleta de estados.

## La cuadrícula: bahías pintadas

Es el elemento firma de la app. Cada celda se dibuja como una bahía de
parqueo real, y el estado se lee por **relleno y contenido**, no por color:

- **LIBRE** — fondo `asfaltoOscuro`, borde 2dp `amarilloPastel`, radio 8.
  Ícono de vehículo al 40% de opacidad en `grisClaro` + código en `blancoHueso`
  14sp w600. Se lee como espacio disponible porque está vacía.
- **OCUPADA** — fondo `asfaltoMedio`, borde 2dp `amarilloPastel`, radio 8.
  Ícono pequeño amarillo arriba a la derecha, placa en `amarilloPastel` 18sp
  w800 `letterSpacing: 1`, tiempo en `grisClaro` 12sp. Se lee ocupada porque
  hay algo adentro.
- **MANTENIMIENTO** — rayado diagonal a 45° alternando `asfaltoOscuro` y
  `asfaltoClaro` (raya de 10px), borde 2dp `asfaltoClaro`. Etiqueta
  "MANTENIMIENTO" 11sp w700 sobre negro al 80%, radio 4. Se lee como zona
  bloqueada, igual que el achurado real de una vía cerrada.

Altura mínima de celda: **110dp**.

El rayado se dibuja con `CustomPainter` o `ShaderMask`, **nunca con una imagen**.

Esto es a propósito accesible: se distingue a distancia, bajo sol directo, y
sin depender de la percepción cromática. **No agregues un chip de color encima
para "reforzar" el estado**: eso deshace el sistema.

Las estadías largas se señalan con la intensidad del borde de `amarilloPastel`,
que aumenta gradualmente con el tiempo. Nunca con un cambio de matiz.

## Paleta de estados

Vive en `core/theme/status_style.dart`, **separada de la paleta de marca** y
deliberadamente más saturada. Recalibrada para fondo oscuro en la reforma: los
tonos anteriores estaban oscurecidos para superficie clara y sobre asfalto
daban ~3.4:1, por debajo de AA.

| Tono      | Hex       | sobre `asfaltoOscuro` | sobre `asfaltoMedio` |
| --------- | --------- | --------------------- | -------------------- |
| `success` | `#7FD1A0` | 9.56:1                | 7.77:1               |
| `warning` | `#E8B563` | 9.30:1                | 7.57:1               |
| `danger`  | `#E88B7D` | 6.98:1                | 5.68:1               |
| `info`    | `#7FB3E8` | 7.89:1                | 6.42:1               |
| `neutral` | `#B0B0A8` | 7.97:1                | 6.49:1               |

El estado nunca se comunica solo por color: todo consumidor de `StatusStyle`
muestra también el ícono o la etiqueta.

## Tipografía

Familia: `Roboto` (Android) / San Francisco (iOS) / `Inter` como fallback web.

| Rol        | Tamaño | Peso | Uso                                      |
| ---------- | ------ | ---- | ---------------------------------------- |
| `display`  | 48sp   | w800 | contador de celdas libres                |
| `headline` | 26sp   | w800 | título de pantalla admin                 |
| `title`    | 18sp   | w700 | título de sección, placa en celda ocupada|
| `body`     | 15sp   | w500 | texto de listas                          |
| `label`    | 12sp   | w600 | labels de stats, chips, badges           |
| `caption`  | 11sp   | w700 | badges pequeños                          |

## Tokens estructurales

Todos en `core/theme/`. Nunca uses un literal aunque coincida con la escala.

- `AppSpacing` — 4 / 8 / 12 / 16 / 24 / 32
- `AppRadius` — 8 (botones secundarios, chips, search) / 12 (tarjetas, botones
  primarios) / 16 (contenedores grandes)
- `AppElevation` — 0 / 1 / 3. **Sin `BoxShadow`** fuera de lo que ya define el
  tema.
- `AppMotion` — 150 / 200 / 250 ms, curva `easeInOutCubic`, sin rebote

`AppMotion.effective(context, duration)` es el **único** punto que consulta la
preferencia de movimiento reducido del sistema. Toda animación pasa por ahí.

## Componentes base

En `core/widgets/`. Sin lógica de negocio, parámetros tipados.

- **`AppButton`** — variantes `primary` (fondo `verdePastel`, texto asfalto),
  `outline` (borde y texto `amarilloPastel`, fondo transparente), `tertiary`
  (fondo `asfaltoClaro`, texto `blancoHueso`), `danger` (texto `terracota`, sin
  fondo). Altura **56dp** en primarios, **48dp** en secundarios. `InkWell` con
  feedback de 150ms. Nunca `ElevatedButton` con elevación.
- **`AppCard`** — fondo `asfaltoMedio`, borde 1px `asfaltoClaro`, radio 12,
  padding 16.
- **`AppChip`** — `active` (fondo amarillo, texto asfalto, w700) / `inactive`
  (fondo `asfaltoClaro`, texto `blancoHueso`). Altura ≥32dp, radio 8. Scroll
  horizontal en móvil. No usar el `Chip` de Material.
- **`AppBadge`** — píldora, padding 10/6, radio 16. `abierto` amarillo ·
  `pagado`/`vigente`/`operador` verde · `cerrado` gris · `pendiente` terracota.
- **`StatusBarTurno`** — banner 60dp, fondo `asfaltoMedio`, borde izquierdo 4dp
  (amarillo si abierto, terracota si cerrado).

## Responsividad

Tres breakpoints en `core/theme/app_breakpoints.dart`:

| Nombre     | Ancho        | Grid celdas | Stats | Navegación             | maxWidth |
| ---------- | ------------ | ----------- | ----- | ---------------------- | -------- |
| `compact`  | < 600        | 2 col       | 2 col | BottomNav / drawer     | 100%     |
| `medium`   | 600 – 1024   | 3 col       | 2 col | `NavigationRail`       | 720      |
| `expanded` | > 1024       | 4 col       | 4 col | Rail extendido/sidebar | 960      |

- **Nunca estirar tarjetas a todo el ancho**: usar `ConstrainedBox`.
- `SafeArea` en móvil; en web no aplica.
- En web: `ScrollConfiguration` para ocultar la barra horizontal,
  `MouseRegion` con `SystemMouseCursors.click` en lo clickeable, y estados de
  `hover`/`focus` visibles para navegación por teclado.
- Ancho mínimo 360dp.

## Movimiento

- Duraciones cortas: 150–250 ms. Nada rebota, nada gira, nada llama la
  atención sobre sí mismo.
- Solo `AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`.
- Ninguna animación puede retrasar una acción del operador.
- El cambio de estado de una celda anima desde la celda tocada, no con un
  refresh del grid completo.
- Feedback táctil en cada acción (`tapFeedback()`).

## Rendimiento de la cuadrícula

Estas optimizaciones existen y **no se pueden perder al agregar estilo**:

- `CeldaCard` recibe solo `celdaId` y lee su dato con
  `ref.watch(provider.select(...))`. Cambiar una celda no reconstruye las demás.
- Cada tarjeta va envuelta en `RepaintBoundary` con `ValueKey(celda.id)`.
- Un **solo timer compartido** actualiza los tiempos transcurridos, nunca uno
  por tarjeta, y se cancela al salir de la pantalla. Esto vale más que
  cualquier sugerencia de usar `Timer.periodic` dentro de la celda.
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
- [ ] Ningún texto amarillo sobre fondo claro.
- [ ] `Semantics` en celdas, botones y badges (la celda anuncia estado + placa
      + tiempo).
- [ ] Movimiento reducido respetado.
- [ ] Sin overflow en 360x640, 768x1024 y 1440x900.
- [ ] `flutter analyze` limpio y `flutter test` en verde.
