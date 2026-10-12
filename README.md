# ODÓN — La ciudad-colmena

Metroidvania 2D en **Godot 4.7** (GDScript 2.0), con arte en alta resolución, animación por huesos y arquitectura por componentes pensada para que 3 personas trabajen en paralelo sin pisarse.

---

## La idea del juego

**Odón** era una ciudad-colmena: millones de insectos viviendo en una torre de panales. Una corporación los "mejoró" fusionándolos con máquinas, y algo salió mal. Una señal llamada **la Estática** corrompió a todo bicho con un implante: ahora son chatarra viva que ataca a cualquiera.

Sos **la última Libélula guardiana**. Tenés un yelmo de cuernos, alas de libélula, una katana y un **brazo de bronce** que absorbe la energía de los enemigos que golpeás. Con esa energía te curás. Tu objetivo: bajar por la ciudad hasta la Torre y apagar la Estática.

**Lo que tomamos de Hollow Knight** no es su personaje sino sus cualidades: silueta compacta de cabeza grande, combate rápido y preciso, curarse con la energía de pegar, atmósfera melancólica y un mapa que se abre a medida que ganás habilidades.

### Los enemigos

| Enemigo | Qué hace | Cómo se le gana |
|---|---|---|
| **Escarabajo Chatarra** | Patrulla el piso y da vuelta en paredes y bordes | 3 espadazos. Saltale encima y pegá hacia abajo (pogo) |
| **Polilla de Señal** | Flota en su zona y se lanza en picada cuando te ve | 2 espadazos. Esperá que baje |
| **Garrapata Torreta** | Se infla y escupe una bola de plasma cuando te tiene a tiro | 3 espadazos. **El proyectil se puede devolver con la espada** |
| **La Recolectora** (jefe) | Un escarabajo-excavadora gigante con 3 ataques: embestida, salto con onda expansiva y lluvia de chatarra. A media vida se enfurece y todo va más rápido | 34 de vida. Esquivá la embestida, saltá la onda y castigá después de cada ataque |

### Habilidades

| Habilidad | Dónde está | Qué abre |
|---|---|---|
| **Alas de Libélula** (doble salto) | Mercado de Neón, arriba a la derecha | Cornisas de 5 tiles de alto |
| **Impulso Sináptico** (dash) | Azotea Sigma, al final | Abismos de 12 tiles en la Pasarela Rota |
| **Planeo Nocturno** (planeo) | Recompensa por vencer a La Recolectora | El campo de pinches del Mirador |
| **Fragmento de Núcleo** (+1 vida máx.) | Hay 2 escondidos: Torre de Cables y Ductos Bajos | — |

### El mapa: Distrito Colmena Baja

```
                         ┌──────────────┐
                         │ 3 TORRE DE   │ (vertical)
                         │   CABLES     │──────────┐
                         │ ◆ núcleo     │          │
                         └──────┬───────┘   ┌──────┴────────┐   ┌──────────────┐   ┌──────────────┐
                                │           │ 4 AZOTEA      │───│ 5 PASARELA   │───│ 6 FOSA DE    │
┌────────────┐   ┌──────────────┴──┐        │   SIGMA       │   │   ROTA       │   │  CHATARRA    │
│ 1 CALLEJÓN │───│ 2 MERCADO DE    │        │ ● nido        │   │ abismos:     │   │ ☠ JEFE       │
│   UMBRAL   │   │   NEÓN          │        │ ★ DASH        │   │ pide DASH    │   │ ★ PLANEO     │
│ ● nido     │   │ ★ DOBLE SALTO   │        └───────────────┘   └──────────────┘   └──────┬───────┘
│ inicio     │   └─────────────────┘                                                      │
└─────┬──────┘                                                                            │
      │ (cornisa: pide DOBLE SALTO)   ┌──────────────┐   ┌──────────────────────┐         │
      └───────────────────────────────│ 8 DUCTOS     │───│ 7 MIRADOR DEL        │─────────┘
                                      │   BAJOS      │   │   ENJAMBRE           │
                                      │ ◆ núcleo     │   │ ● nido               │
                                      └──────────────┘   │ pinches: pide PLANEO │
                                                         └──────────────────────┘
● nido = punto de guardado    ★ = habilidad    ◆ = Fragmento de Núcleo
```

El recorrido es un **circuito**: después del jefe, el Mirador y los Ductos te devuelven al Callejón Umbral por la cornisa que viste al principio y no podías subir. Ese "¡ah, era por acá!" es el corazón del género.

---

## Cómo abrirlo

1. Abrí Godot 4.7, elegí **Importar**, seleccioná el archivo `project.godot` y después **Importar y editar**.
2. Apretá **F5** (o el botón ▶ arriba a la derecha). Arranca la pantalla de título.

> La primera vez Godot tarda un poco en importar las imágenes HD. Es normal.

> **Para probar algo puntual:** abrí `world/main/main.tscn`, seleccioná el nodo `Main` y en el Inspector cambiá **Starting Room Path** a la sala que quieras. Desmarcá **Load Save On Start** para empezar siempre de cero. Con **F6** se juega la escena abierta.

## Controles

| Acción | Teclado | Joystick |
|---|---|---|
| Moverse | A / D o flechas | Stick izq. / cruceta |
| Saltar (mantener = más alto) | Espacio o Z | A |
| Planear *(desbloqueable)* | Mantener saltar mientras caés | A |
| Atacar (+ arriba / + abajo en el aire) | J o X | X |
| Dash *(desbloqueable)* | K, C o Shift | RB |
| **Curarse** (mantener) | L o F | LB |
| Interactuar (nido) | E | Y |
| Pausa | Esc | Start |

**Curarse:** cada espadazo a un enemigo llena el medallón de bronce (arriba a la izquierda). Con un tercio lleno, mantené **L** quieto en el piso y recuperás una celda. Si te pegan mientras te curás, se corta.

## Qué ya funciona

- **Pantalla de título** (Continuar / Nueva partida / Salir) y **menú de pausa**.
- **Movimiento** con aceleración, coyote time, jump buffer, salto de altura variable, doble salto, dash y planeo.
- **Combate** con espadazo hacia adelante, arriba y abajo, pogo, **hit-stop** (el juego se congela una fracción de segundo al pegar), temblor de cámara, chispas y retroceso.
- **Energía y curación** al estilo Hollow Knight.
- **3 enemigos y 1 jefe** con su propia IA.
- **8 salas** conectadas, con 3 nidos de guardado, 3 habilidades, 2 fragmentos de vida y una arena de jefe con barreras.
- **Guardado en disco**: habilidades, vida máxima, objetos agarrados, jefe vencido, salas visitadas y último nido.
- **Muerte y reaparición** en el último nido.
- **HUD** con celdas de vida hexagonales, medallón de energía, barra del jefe, nombre de la zona la primera vez que entrás, y destello rojo al recibir daño.
- **Ambiente**: ciudad en 5 capas de parallax con la Torre-colmena al fondo, lluvia, niebla baja, motas de luz, vapor, carteles de neón que titilan y una capa de primer plano.

---

## Estructura de carpetas

Organizada **por entidad** (todo lo de una cosa en un mismo lugar), no por tipo de archivo:

```
res://
├── autoloads/              Singletons globales (siempre cargados)
│   ├── game_state.gd         habilidades, flags, vida extra, guardado
│   ├── event_bus.gd          señales globales entre escenas
│   └── game_feel.gd          hit-stop, temblor de cámara, efectos
├── components/             Piezas reutilizables por CUALQUIER entidad
│   ├── health_component.gd
│   ├── hitbox_component.gd       (lo que pega)
│   ├── hurtbox_component.gd      (lo que recibe)
│   ├── hit_flash_component.gd
│   └── neon_flicker_component.gd
├── data/abilities.gd       Catálogo de habilidades (nombres y textos)
├── entities/
│   ├── player/             player.gd, sword_component.gd, knight_rig.tscn (partes + huesos)
│   ├── enemies/
│   │   ├── enemy.gd          clase base de todos los enemigos
│   │   ├── beetle/           Escarabajo Chatarra
│   │   ├── moth/             Polilla de Señal
│   │   ├── tick/             Garrapata Torreta
│   │   └── projectile/       bola de plasma (se puede devolver)
│   └── bosses/recolectora/ el jefe, su onda expansiva y la chatarra que cae
├── fx/                     chispas, explosión de muerte, polvo (se borran solos)
├── shaders/rim_light.gdshader   luz de borde + destello blanco al recibir daño
├── world/
│   ├── main/               escena raíz, fondo de ciudad, primer plano y lluvia
│   ├── rooms/              room.gd (script base) + room_01..08.tscn
│   └── objects/            puerta, nido, pickups, pinches, carteles, faroles,
│                           vapor, atmósfera, barrera y arena de jefe
├── ui/                     título, HUD y pausa
├── assets/                 todo el arte HD (personaje, enemigos, tiles, fondo, props, fx, ui, fuentes)
└── art_source/             concepto y hoja de partes originales (Godot no los importa)
```

## Arquitectura en 4 ideas

### 1. Componentes (composición en vez de herencia)

Cada responsabilidad es un nodo chico que se "enchufa". El jugador, los enemigos, el jefe y hasta el proyectil usan **los mismos** `HealthComponent`, `HurtboxComponent` y `HitboxComponent`: solo cambia la configuración en el Inspector. Por eso devolver una bola de plasma no necesitó código especial: el proyectil tiene una Hurtbox con 1 de vida, y la espada la rompe como a cualquier enemigo.

```
Player (CharacterBody2D)                 Beetle (CharacterBody2D, enemy.gd)
├── KnightRig  (partes + huesos)         ├── Visual  (cuerpo + 3 patas animadas)
├── CollisionShape2D                     ├── CollisionShape2D
├── Camera2D                             ├── HealthComponent      (vida 3)
├── HealthComponent       (vida 5+)      ├── HurtboxComponent     ← lo lastima la espada
├── HurtboxComponent      ← enemigos     ├── HitboxComponent      → lastima al jugador
├── Sword (SwordComponent)               └── FloorCheck (RayCast2D)  ← detecta bordes
│   └── SwordHitbox (HitboxComponent)
├── HealParticles
└── DashTrail
```

Los componentes se comunican **por señales**: la Hurtbox no sabe si su dueño es un jugador o un enemigo, solo avisa con `hit_received`.

### 2. Herencia corta para los enemigos

`enemy.gd` (clase `Enemy`) resuelve lo común: unirse al grupo `enemies`, retroceso al recibir un golpe, destello, explosión al morir. Cada enemigo **solo escribe su comportamiento** sobrescribiendo `_ai(delta)`. Por eso el escarabajo entero tiene menos de 50 líneas.

### 3. Autoloads: el estado vive fuera de las escenas

- **GameState** recuerda habilidades, objetos agarrados (`world_flags`), vida extra, salas visitadas y el último nido. Cuando volvés a una sala, se crea de cero y le pregunta a GameState qué mostrar. Por eso un pickup ya agarrado no reaparece y un jefe vencido no revive.
- **EventBus** conecta escenas que no se conocen: el jefe emite `boss_health_changed` y el HUD lo escucha, sin que ninguno sepa que el otro existe.
- **GameFeel** centraliza el "jugo": `GameFeel.hit_stop()`, `GameFeel.shake(fuerza, duración)` y `GameFeel.spawn_fx(escena, posición)`. Cualquier script puede usarlo.

### 4. Main persistente + salas intercambiables

```
Main (Node2D)
├── CityBackground   ← cielo, ciudad lejana, media, cercana y cables (Parallax2D)
├── RoomContainer    ← acá se carga UNA sala a la vez
├── Player           ← nunca se destruye: conserva vida y estado
├── FX               ← chispas y explosiones (grupo "fx_layer")
├── Foreground       ← siluetas en primer plano (parallax más rápido)
├── Rain, HUD, PauseMenu (CanvasLayer)
└── TransitionLayer/Fade   fundido a negro entre salas
```

### Capas de física

| # | Nombre | Quién está en ella | Qué detecta (máscara) |
|---|---|---|---|
| 1 | world | tiles, pinches, barreras | — |
| 2 | player | cuerpo del jugador | world |
| 3 | enemies | cuerpo de enemigos y jefe | world |
| 4 | playerHurtbox | hurtbox del jugador | 7 enemyHitbox |
| 5 | enemyHurtbox | hurtbox de enemigos y proyectiles | 6 playerHitbox |
| 6 | playerHitbox | espada | — |
| 7 | enemyHitbox | enemigos, proyectiles, pinches | — |

Puertas, pickups, nidos y el disparador de la arena son `Area2D` con máscara **2 (player)**.

---

## Guías rápidas

### Medidas que hay que saber

- La pantalla del juego mide **480 × 270** y se escala ×3 a la ventana.
- **1 tile = 16 unidades** de juego. Todo el arte está dibujado a **4×** (un tile es una imagen de 64 px) y se muestra a escala **0.25**. Así se ve nítido en pantallas grandes.
- Ninguna sala puede ser **más angosta que 30 tiles ni más baja que 17**, o la cámara muestra lo que hay afuera.
- Salto simple: ~3.5 tiles de alto. Doble salto: ~6. Doble salto + dash: ~13 de largo. Usen estos números para decidir qué habilidad pide cada obstáculo.

### Crear una sala nueva

La forma más fácil: **duplicar una sala existente** (clic derecho sobre `room_05.tscn` > Duplicar), borrar lo que no sirve y repintar.

Desde cero:

1. **Escena > Nueva escena**, raíz `Node2D` (por ejemplo `Room09`). En **Script** cargá `res://world/rooms/room.gd` y completá **Room Name** (aparece en pantalla la primera vez que se entra).
2. Agregale hijos con estos nombres exactos: `Decor`, `Tiles` (TileMapLayer), `PlayerStart` (Marker2D), `Doors`, `Objects` y `Enemies` (Node2D).
3. Arrastrá `world/objects/atmosphere.tscn` como hijo y poné en **Room Size** el tamaño de la sala en unidades (ancho en tiles × 16, alto × 16).
4. Seleccioná `Tiles`:
   - **Tile Set**: `res://assets/tiles/tileset.tres`.
   - **Transform > Scale**: `0.25, 0.25` ← **importante**: sin esto los tiles se ven 4 veces más grandes.
   - **Texture > Filter**: Linear Mipmap.
5. **Pintar con terrenos** (Godot elige solo los bordes correctos): en el panel **TileMap** de abajo, pestaña **Terrains**, elegí *Concreto* y pintá. Para las plataformas atravesables, en la pestaña **Tiles** usá la de la fila de abajo, a la izquierda.

### Conectar salas con puertas

1. Dejá una abertura de 3 tiles de alto en la pared.
2. Arrastrá `world/objects/door.tscn` adentro de `Doors` y ubicala en la abertura.
3. En el Inspector:
   - **Door Id**: único, por ejemplo `r09_izq`.
   - **Target Room Path**: la sala destino.
   - **Target Door Id**: el id de la puerta por la que vas a aparecer allá.
   - **Spawn Offset**: dónde aparece el jugador al LLEGAR por esta puerta. Pared izquierda `(32, 12)`, pared derecha `(-32, 12)`. Tiene que quedar **afuera** del área de la puerta.
4. Hacé lo mismo en la otra sala, apuntando de vuelta.

> ⚠️ Las puertas van **de a pares**. Si falta la de vuelta, el jugador aparece en `PlayerStart` y la consola avisa.

### Poner objetos

| Qué | Escena | Configurar |
|---|---|---|
| Habilidad | `world/objects/ability_pickup.tscn` | **Ability** y un **Pickup Id** único (`pickup_xxx`) |
| +1 vida máxima | `world/objects/health_core.tscn` | **Pickup Id** único (`nucleo_xxx`) |
| Nido de guardado | `world/objects/save_point.tscn` | **Save Id** único (`nido_xxx`). Va apoyado en el piso |
| Pinches | `world/objects/spikes.tscn` | Uno por tile, sobre el piso |
| Enemigos | `entities/enemies/*/*.tscn` | El escarabajo tiene **Start Direction** |

### Arena de jefe

Mirá `room_06.tscn`: un nodo `BossArena` (script `world/objects/boss_arena.gd`) con `Trigger` (Area2D donde empieza la pelea), `Gates` (barreras que cierran las salidas), `BossSpawn` y `RewardSpawn`. En el Inspector elegís la escena del jefe, el flag que recuerda que lo venciste, la recompensa y los límites de la arena.

### Decorar

Todo va adentro de `Decor`, que se dibuja detrás de los tiles.

- `neon_sign.tscn` sirve para **cualquier imagen con halo**: cambiá **Sign Texture**, **Glow Color** (con alfa 0 no brilla) y **Flicker**. Se actualiza en el editor al instante. En `assets/props/` hay carteles (`sign_red`, `sign_teal`, `sign_orange`, `sign_white`, `sign_wide`), puesto de comida (`stall`), farolitos (`lanterns`), holograma, caños, cajas y barriles.
- `street_lamp.tscn`: farol con cono de luz cálida.
- `steam_vent.tscn`: vapor saliendo del piso.

### Crear un enemigo nuevo

1. Duplicá la carpeta `entities/enemies/beetle/` y renombrala.
2. En el script dejá `extends Enemy` y reescribí solo `_ai(delta)`.
3. Cambiá las imágenes de `Visual` y ajustá las formas de colisión.

### Agregar una habilidad nueva

1. Agregá la constante y sus textos en `data/abilities.gd`.
2. Sumá el valor al `@export_enum` de `world/objects/ability_pickup.gd` (y de `boss_arena.gd` si puede ser recompensa).
3. Usala en `player.gd` con `GameState.has_ability(Abilities.LA_NUEVA)`.

### Ajustar cómo se siente

Casi todo está en el Inspector del nodo `Player`, agrupado: velocidad, salto, gravedad, dash, planeo, combate y curación. Probá cambiar **Gravity** o **Jump Velocity** y jugá: es la mejor forma de entender el "game feel".

---

## Arte

### El personaje: animación por huesos ("cutout")

La Libélula está armada con partes dibujadas en alta resolución (generadas con IA a partir del concepto de `art_source/knight/`). Cada parte es una imagen suelta que cuelga de un "hueso" y gira sobre su articulación; las animaciones solo rotan huesos.

Las proporciones son **compactas a lo Hollow Knight**: cabeza enorme, capa larga, piernas cortas. Las partes están aclaradas para leerse sobre la ciudad oscura, y el shader `rim_light` les agrega un borde de luz fría.

```
KnightRig (Node2D, cutout_rig.gd)
├── Torso                ← hueso raíz (la cadera)
│   ├── WingB, Cloak, Katana, WingA        (detrás del cuerpo)
│   ├── ThighBack → ShinBack               (pierna de atrás, más oscura)
│   ├── ArmBackUpper → ArmBackFore
│   ├── Head
│   ├── ThighFront → ShinFront
│   └── ArmRobotUpper → ArmRobotFore → KatanaHand   (brazo de bronce)
└── AnimationPlayer      ← idle, run, jump, fall, attack, attack_up,
                           attack_down, dash, glide, hurt, heal
```

- **Cambiar una parte** (otro casco, por ejemplo): reemplacen el PNG en `assets/characters/knight/` manteniendo orientación y tamaño parecido.
- **Retocar una animación**: abran `entities/player/knight_rig.tscn`, seleccionen `AnimationPlayer` y muevan las claves en el panel **Animación**.
- `cutout_rig.gd` imita lo básico de un AnimatedSprite2D (`play`, `animation`, `flip_h`).

### El mundo

Todo en HD (4×) con la misma paleta:

- **Fondo**: noche azul petróleo, niebla, y la Torre-colmena iluminada en ámbar.
- **Escenario**: concreto oscuro casi negro con bordes de acero remachado. Lo jugable se lee por contraste.
- **Luces**: rojo `#FF3C46`, turquesa `#28DCC8`, ámbar `#FFA028` y blanco cálido `#FFECE2`.
- **Enemigos**: chatarra oxidada + carne de bicho + un punto de luz (ojo o núcleo) para que se vean de lejos.

Fuentes: **Cinzel** (títulos) y **Rajdhani** (textos), ambas libres (licencias en `assets/fonts/`).

---

## Próximos pasos sugeridos

1. **Sonido**: es lo que más va a cambiar la sensación. Espadazo, golpe, salto, aterrizaje, curación, música ambiente con lluvia.
2. **Mapa del juego** (pantalla con las salas visitadas: `GameState.visited_rooms` ya las guarda).
3. **Segunda zona** con otra paleta (por ejemplo, el interior de la Torre) y su jefe.
4. **Ataque cargado** o **salto en pared** como 4ª habilidad.
5. **Más variantes** de enemigos reutilizando `Enemy`: escarabajo con escudo, polilla que dispara.

## Trabajo en equipo con Git

- **`.godot/` nunca se sube** (ya está en `.gitignore`). Sí se suben los `.import` y los `.uid`: sin ellos se rompen las referencias.
- **Una escena, un dueño a la vez.** Los conflictos de merge en `.tscn` son difíciles. Cada sala es su propio archivo: quien hace el mapa trabaja en `world/rooms/`, quien hace el jugador en `entities/player/`, quien hace enemigos en `entities/enemies/`.
- **Ramas por feature**: `feature/sala-09`, `feature/wall-jump`, `fix/camara`. Se mergea a `main` con Pull Request y otra persona lo revisa.
- **Antes de abrir Godot, `git pull`.** Antes de hacer push, probá el juego con F5.
- **Commits chicos** con mensajes claros: `Agrega sala 9 con puerta a sala 5`.
