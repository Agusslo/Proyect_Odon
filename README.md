# Proyecto Metroidvania — El Caballero Libélula

Metroidvania 2D **cyberpunk** en **Godot 4.7** (GDScript). Un mercado callejero nocturno bajo la lluvia, lleno de carteles, cables y puestos de comida. El protagonista es un caballero insecto con yelmo de cuernos, alas de libélula, capa raída, brazo robótico de bronce y una katana de filo rojo. Base jugable con arquitectura por componentes, pensada para que 3 personas trabajen en paralelo sin pisarse.

## Cómo abrirlo

1. Abrí Godot 4.7, elegí **Importar**, seleccioná el archivo `project.godot` y después **Importar y editar**.
2. Apretá **F5** (o el botón ▶ arriba a la derecha) para jugar.

> Al empezar, el juego carga la última partida guardada. Para arrancar siempre de cero mientras prueban, abrí `world/main/main.tscn`, seleccioná el nodo `Main` y en el Inspector desmarcá **Load Save On Start**.

## Controles

| Acción | Teclado | Joystick |
|---|---|---|
| Moverse | A / D o flechas | Stick izq. / cruceta |
| Saltar (mantener = más alto) | Espacio o Z | A |
| Atacar (+ arriba / + abajo en el aire) | J o X | X |
| Dash *(desbloqueable)* | K, C o Shift | RB |
| Interactuar (terminal) | E | Y |

## Qué ya funciona

- **Movimiento** con aceleración, coyote time, jump buffer y salto de altura variable.
- **Combate**: espadazo hacia adelante, arriba y abajo. Pegar hacia abajo sobre un enemigo te hace rebotar (*pogo*).
- **Daño**: vida, invencibilidad con parpadeo, knockback, y pinches que te devuelven al último suelo seguro.
- **Habilidades desbloqueables**: Doble salto (*Alas de Libélula*), Dash (*Impulso Sináptico*) y Planeo (*Planeo Nocturno*, programado pero todavía sin ubicar en el mapa).
- **Mapa interconectado**: 3 salas unidas por puertas, con fundido a negro y cámara limitada a cada sala.
- **Terminales de recarga**: curan, guardan la partida en disco y marcan el punto de reaparición.
- **Muerte y reaparición** en la última terminal.
- **Ambiente de mercado cyberpunk**: ciudad de fondo en 4 capas con *parallax* (cielo, edificios lejanos, fachadas con carteles y cables con farolitos), lluvia, carteles que titilan, puestos de comida y faroles cálidos.
- **HUD** con vida, nombre de la sala y mensajes.

## El mapa actual

```
                 ┌───────────────────┐
                 │ Sala 3            │
                 │ Azotea del Mercado│
                 │ • Dash            │
                 │ • Terminal        │
                 └─────────┬─────────┘
                           │ (puerta alta: necesita DOBLE SALTO)
┌──────────────────────────┴──────┐     ┌──────────────────────────────┐
│ Sala 1  Callejón Umbral         │─────│ Sala 2  Mercado de Neón      │
│ • Inicio • Terminal • Pinches   │     │ • 2 drones • Pinches         │
│                                 │     │ • Alas de Libélula (doble    │
│                                 │     │   salto) arriba a la derecha │
└─────────────────────────────────┘     └──────────────────────────────┘
```

Este es el *gating* clásico de un Metroidvania: desde el inicio ya se ve la cornisa alta a la izquierda, pero recién se puede subir después de conseguir las alas en la Sala 2.

## Estructura de carpetas

Organizada **por entidad** (todo lo de una cosa en un mismo lugar), no por tipo de archivo:

```
res://
├── autoloads/          Singletons globales (siempre cargados)
│   ├── game_state.gd     habilidades, flags del mundo, guardado
│   └── event_bus.gd      señales globales entre escenas
├── components/         Piezas reutilizables por CUALQUIER entidad
│   ├── health_component.gd
│   ├── hitbox_component.gd      (lo que pega)
│   ├── hurtbox_component.gd     (lo que recibe)
│   ├── hit_flash_component.gd   (parpadeo blanco al recibir daño)
│   └── neon_flicker_component.gd (neón que titila)
├── data/abilities.gd   Catálogo de habilidades (constantes y textos)
├── entities/
│   ├── player/         Caballero: player.gd, sword_component.gd, escena y animaciones
│   └── enemies/crawler/  Dron rastrero de seguridad
├── world/
│   ├── main/           Escena raíz (nunca se destruye), fondo de ciudad y lluvia
│   ├── rooms/          room.gd (script base) + room_01..03.tscn
│   └── objects/        door, save_point (terminal), ability_pickup, spikes,
│                       neon_sign (carteles, puestos, farolitos) y street_lamp
├── ui/                 HUD
└── assets/             sprites, tiles (tileset.tres), background, props y UI
```

## Arquitectura en 3 ideas

### 1. Componentes (composición en vez de herencia)

En lugar de un script gigante que hace todo, cada responsabilidad es un nodo chico que se "enchufa". El jugador y el dron usan **los mismos** `HealthComponent`, `HurtboxComponent` y `HitboxComponent`: lo único que cambia es la configuración en el Inspector.

```
Player (CharacterBody2D)              Crawler (CharacterBody2D)
├── AnimatedSprite2D                  ├── AnimatedSprite2D
├── CollisionShape2D                  ├── CollisionShape2D
├── Camera2D                          ├── HealthComponent      (vida 3)
├── HealthComponent       (vida 5)    ├── HurtboxComponent     ← lo lastima la espada
├── HurtboxComponent      ← enemigos  ├── HitboxComponent      → lastima al jugador
└── Sword (SwordComponent)            ├── HitFlashComponent
    └── SwordHitbox (HitboxComponent) └── FloorCheck (RayCast2D)
        ├── CollisionShape2D
        └── Slash (Polygon2D)
```

Los componentes se comunican **por señales** (patrón Observer): la Hurtbox no sabe si su dueño es un jugador o un enemigo, solo avisa con `hit_received`.

### 2. Autoloads: el estado vive fuera de las escenas

- **GameState** recuerda habilidades, objetos agarrados (`world_flags`) y la última terminal. Cuando volvés a una sala, esta se crea de cero y le pregunta a GameState qué mostrar. Por eso un pickup ya agarrado no reaparece.
- **EventBus** conecta escenas que no se conocen: una puerta emite `room_change_requested` y Main la escucha, sin que la puerta sepa que Main existe.

### 3. Main persistente + salas intercambiables

```
Main (Node2D)
├── CityBackground     ← cielo, edificios, fachadas y cables en capas (Parallax2D)
├── RoomContainer      ← acá se carga UNA sala a la vez
├── Player             ← nunca se destruye: conserva vida y estado
├── Rain (CanvasLayer) ← lluvia sobre toda la pantalla
├── HUD (CanvasLayer)
└── TransitionLayer
    └── Fade (ColorRect)   fundido a negro entre salas
```

### Capas de física

| # | Nombre | Quién está en ella | Qué detecta (máscara) |
|---|---|---|---|
| 1 | world | tiles, pinches (parte sólida) | — |
| 2 | player | cuerpo del jugador | world |
| 3 | enemies | cuerpo de enemigos | world |
| 4 | playerHurtbox | hurtbox del jugador | 7 enemyHitbox |
| 5 | enemyHurtbox | hurtbox de enemigos | 6 playerHitbox |
| 6 | playerHitbox | espada | — |
| 7 | enemyHitbox | enemigos, pinches | — |

Puertas, pickups y terminales son `Area2D` con máscara **2 (player)**.

## Guías rápidas

### Crear una sala nueva

1. **Escena > Nueva escena**. Elegí **Otro nodo**, buscá `Node2D` y renombralo (por ejemplo `Room04`).
2. En el Inspector, en **Script**, cargá `res://world/rooms/room.gd`. Completá **Room Name**.
3. Agregale estos hijos con esos nombres exactos: `Decor`, `Tiles` (TileMapLayer), `PlayerStart` (Marker2D), `Doors`, `Objects` y `Enemies` (todos los demás son Node2D). `Decor` va primero para que quede detrás de los tiles.
4. Seleccioná `Tiles`. En el Inspector, en **Tile Set**, cargá `res://assets/tiles/tileset.tres` y pintá en el panel **TileMap** de abajo. Los tiles pintados definen los límites de la cámara.
5. Arrastrá `world/objects/door.tscn` adentro de `Doors` y ubicala en una abertura de la pared. En el Inspector completá:
   - **Door Id**: único, por ejemplo `r04_izq`.
   - **Target Room Path**: la sala destino.
   - **Target Door Id**: el id de la puerta donde vas a aparecer.
   - **Spawn Side**: hacia qué lado aparece el jugador al llegar.
6. Guardala en `world/rooms/room_04.tscn` y agregá la puerta de vuelta en la otra sala.

> ⚠️ Las puertas se conectan **de a pares**. Si la puerta A lleva a B, B tiene que tener una puerta con el id que A espera. Si no, el jugador aparece en `PlayerStart` y en la consola sale un aviso.

### Poner una habilidad en el mapa

Arrastrá `world/objects/ability_pickup.tscn` a `Objects`, elegí la **Ability** y poné un **Pickup Id** único (por ejemplo `pickup_planeo`).

### Agregar una habilidad nueva

1. Agregá la constante y sus textos en `data/abilities.gd`.
2. Sumá el valor al `@export_enum` de `world/objects/ability_pickup.gd`.
3. Usala en `player.gd` con `GameState.has_ability(Abilities.LA_NUEVA)`.

### Decorar una sala

Arrastrá `world/objects/neon_sign.tscn` o `world/objects/street_lamp.tscn` adentro de `Decor`. En el cartel podés cambiar **Sign Texture** y **Glow Color**, y se actualiza al instante en el editor. En `assets/props/` hay carteles verticales (`sign_red`, `sign_teal`, `sign_white`, `sign_orange`), uno horizontal (`sign_wide`), un puesto de comida (`stall`) y una tira de farolitos (`lanterns`).

Los toldos rayados del tileset son **plataformas atravesables**: se suben desde abajo.

### Crear un enemigo nuevo

Duplicá la carpeta `entities/enemies/crawler/` y cambiá solo el script de movimiento. Los componentes de vida y daño se reutilizan tal cual.

## Arte

El Caballero Libélula, los drones, los tiles, la ciudad de fondo y la decoración ya tienen su arte en estilo pixel art. Cualquier sprite se reemplaza **sin tocar código**: basta con sobrescribir el PNG con el mismo tamaño de cuadro.

**Paleta del mercado:** fondo azul noche casi negro, ladrillo oscuro para el escenario, y luces en rojo `#FF3C46`, turquesa `#28DCC8`, naranja `#FFA028` y blanco cálido `#FFECE2`.

**Personaje:** yelmo azul acero, ojos blancos, coraza plateada con faja roja, capa gris oscura, brazo de bronce con luz naranja y katana negra con filo rojo. Cuando no ataca, la katana va enfundada en la espalda.

`assets/sprites/knight.png` es una tira horizontal de cuadros de **72×64 px**. Los pies del personaje van apoyados en la fila 58 de cada cuadro. El orden es:

| Cuadros | Animación |
|---|---|
| 0–3 | idle |
| 4–9 | run |
| 10–11 | jump |
| 12–13 | fall |
| 14–17 | attack (hacia adelante) |
| 18–20 | attack_up |
| 21–23 | attack_down |
| 24–25 | dash |
| 26–27 | glide |
| 28 | hurt |

Si el arte final usa otro tamaño u otra cantidad de cuadros, abran `entities/player/knight_frames.tres` (panel **SpriteFrames**) y rehagan las animaciones con el botón de cuadrícula ("agregar cuadros desde una hoja de sprites").

## Trabajo en equipo con Git

- **`.godot/` nunca se sube** (ya está en `.gitignore`). Sí se suben los `.import` y los `.uid`: sin ellos se rompen las referencias entre archivos.
- **Una escena, un dueño a la vez.** Los `.tscn` son texto, pero los conflictos de merge en ellos son difíciles de resolver. Por eso cada sala es su propio archivo: quien hace el mapa trabaja en `world/rooms/`, quien hace el jugador en `entities/player/`.
- **Ramas por feature**: `feature/sala-04`, `feature/wall-jump`, `fix/camara`. Se mergea a `main` con Pull Request y otra persona lo revisa.
- **Antes de abrir Godot, hacé `git pull`.** Antes de hacer push, probá el juego con F5.
- **Commits chicos** y con mensajes claros: `Agrega sala 4 con puerta a sala 2`.
- La primera vez que alguien abra y guarde una escena, Godot puede agregar líneas `uid=`. Es normal: commiteenlas una vez y listo.
