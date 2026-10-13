# ODÓN — El Caballito del Diablo

Metroidvania 2D en **Godot 4.7** (GDScript 2.0). Pixel art oscuro cyberpunk, combate rápido, y una protagonista con un brazo demoníaco. Arquitectura por componentes pensada para que 3 personas trabajen en paralelo sin pisarse.

> El documento completo de historia (mundo, pacto, actos, jefes y finales) está en el doc **"ODÓN — Lore del Caballito del Diablo"**. Acá va el resumen y todo lo técnico.

---

## La historia en corto

**Odón** es una ciudad-colmena que la corporación **Colmena Reina** levantó sobre el pantano de las libélulas, después de exterminarlas. Al perforar el Fondo para los cimientos despertaron a **Zébul, el Señor de las Moscas**. Su zumbido, **la Estática**, vuelve locos a todos los bichos con implantes.

**Ninfa** era la última guardiana libélula. Murió ahogada en el barro cuando drenaron el pantano. En el Fondo, Zébul le ofreció volver a la vida a cambio de cargar su brazo: un brazo demoníaco que quema, desgarra y **devora**. Cada criatura que come la hace más fuerte… y le devuelve a Zébul un pedazo de su poder.

En muchos países a la libélula le dicen *caballito del diablo*. Ahora tienen razón.

## Lo que la hace distinta (y no una copia de Hollow Knight)

| Sistema | Cómo funciona |
|---|---|
| **Devorar** (L / F) | No hay curación quieta. Los enemigos con poca vida quedan **aturdidos y brillan en rojo**: acercate y devoralos. Cura 1 de vida y da Brasas. Los jefes no se aturden: sueltan **trozos de carne** al recibir mucho daño |
| **Brasas** | La barra de fuego de 3 segmentos (arriba a la izquierda, debajo de la vida). Se ganan pegando (el zarpazo da el doble) y devorando. **Cada segmento lleno = una Garra Infernal**. Se apagan solas si dejás de pelear |
| **Combo** | Katana (tajo de arriba) → katana (tajo de abajo) → **Zarpazo** con el brazo demoníaco: doble de daño y mucho más empuje. **Pegar no te mueve**: podés pegar quieta o corriendo |
| **Hambre** | Si pasan 2 minutos sin devorar, el brazo tiene Hambre: pega +1, pero cada 25 s te muerde 1 de vida (nunca la última). Devorar o una charca lo calman |
| **Charcas** | Los puntos de guardado: Ninfa se sumerge como cuando era ninfa. Curan todo, calman el Hambre y guardan |
| **Muerte** | Despertás en la última charca y el brazo se queda con tus Brasas. No hay sombra que perseguir |

## Poderes

| Poder | Qué hace | Dónde se consigue | Qué abre |
|---|---|---|---|
| **Alas de Ceniza** | Doble salto: las alas rotas arden un instante | Mercado de Neón | Cornisas de 5 tiles |
| **Garra Infernal** (I / V) | Lanza una mano de fuego que atraviesa enemigos. Cuesta 1 segmento de Brasas (33) | **Desde el principio**: es el poder del brazo | (pensada para romper sellos de ceniza) |
| **Galope del Diablo** (dash) | Te volvés sombra: invulnerable, atravesás enemigos y los quemás | Azotea Sigma | Abismos de 12 tiles |
| **Planeo de Brasas** | Mantener saltar en el aire | Recompensa de La Recolectora | El campo de pinches del Mirador |
| **Fragmento de Núcleo** | +1 vida máxima | Torre de Cables y Ductos Bajos (escondidos) | — |

## Enemigos

| Enemigo | Qué hace | Cómo se le gana |
|---|---|---|
| **Escarabajo Chatarra** | Patrulla el piso | 2 golpes lo aturden: devoralo |
| **Polilla de Señal** | Flota y se lanza en picada cuando te ve | 1 golpe la aturde |
| **Garrapata Torreta** | Escupe bolas de plasma | **El proyectil se devuelve con la katana** |
| **La Recolectora** (jefe) | Embestida, salto con onda expansiva y lluvia de chatarra. A media vida se enfurece | 34 de vida. Devorá los trozos que suelta para aguantar |

## El mapa: Distrito Colmena Baja

```
                         ┌──────────────┐
                         │ 3 TORRE DE   │ (vertical)
                         │   CABLES     │──────────┐
                         │          ◆   │          │
                         └──────┬───────┘   ┌──────┴────────┐   ┌──────────────┐   ┌──────────────┐
                                │           │ 4 AZOTEA      │───│ 5 PASARELA   │───│ 6 FOSA DE    │
┌────────────┐   ┌──────────────┴──┐        │   SIGMA       │   │   ROTA       │   │  CHATARRA    │
│ 1 CALLEJÓN │───│ 2 MERCADO DE    │        │ ● charca      │   │ abismos:     │   │ ☠ JEFE       │
│   UMBRAL   │   │   NEÓN          │        │ ★ GALOPE      │   │ pide GALOPE  │   │ ★ PLANEO     │
│ ● charca   │   │ ★ ALAS          │        └───────────────┘   └──────────────┘   └──────┬───────┘
│ inicio     │   └─────────────────┘                                                      │
└─────┬──────┘                                                                            │
      │ (cornisa: pide ALAS)          ┌──────────────┐   ┌──────────────────────┐         │
      └───────────────────────────────│ 8 DUCTOS     │───│ 7 MIRADOR DEL        │─────────┘
                                      │   BAJOS  ◆   │   │   ENJAMBRE           │
                                      └──────────────┘   │ ● charca             │
                                                         │ pinches: pide PLANEO │
                                                         └──────────────────────┘
● charca (guardado)    ★ habilidad    ◆ Fragmento de Núcleo
```

---

## Cómo abrirlo

1. Abrí Godot 4.7, elegí **Importar**, seleccioná `project.godot` y después **Importar y editar**.
2. Apretá **F5**. Arranca la pantalla de título; con **Nueva partida** se ve la intro (cualquier botón la saltea).

> **Para probar algo puntual:** abrí `world/main/main.tscn`, seleccioná `Main` y en el Inspector cambiá **Starting Room Path**. Desmarcá **Load Save On Start** para empezar de cero y **Play Intro** para no ver la intro cada vez.

## Controles

| Acción | Teclado | Joystick |
|---|---|---|
| Moverse | A / D o flechas | Stick izq. / cruceta |
| Saltar (mantener = más alto) | Espacio o Z | A |
| Atacar (combo de 3; + arriba / + abajo en el aire) | J o X | X |
| **Devorar** | L o F | LB |
| **Garra Infernal** | I o V | B |
| Galope del Diablo (dash) | K, C o Shift | RB |
| Planear | Mantener saltar mientras caés | A |
| Sumergirse en la charca | E | Y |
| Pausa | Esc | Start |
| *Prueba: desbloquear todos los poderes* | F1 | — |

**Cómo se usan los poderes**
- **Combo:** apretá J tres veces seguidas. El tercer golpe es el **Zarpazo**: más daño y empuje. Si apretás un poquito antes de que termine el golpe anterior, **no se pierde**: sale apenas se pueda (buffer). Pegar no te frena ni te empuja: podés seguir corriendo mientras atacás.
- **Devorar:** pegale a un enemigo hasta que quede **aturdido brillando en rojo** (nunca se muere sin aturdirse antes). Acercate y apretá **L**: te curás 1 y ganás Brasas. Si le volvés a pegar, muere sin comértelo.
- **Garra Infernal:** apretá **I** cuando tengas **al menos un segmento de Brasas lleno** (late y brilla cuando está listo). Si no alcanza, la barra tiembla en rojo y aparece un aviso. Para llenar Brasas: pegale a enemigos (el zarpazo da el doble) o devoralos.
- **Galope del Diablo:** **K** o Shift. Mientras dura sos intocable y quemás lo que atravesás.
- **Alas de Ceniza:** saltar otra vez en el aire. **Planeo:** mantener saltar mientras caés.
- Alas, Galope y Planeo se consiguen recorriendo el mapa. Para probarlos todos de una, apretá **F1** en el juego (también llena las Brasas).

**El HUD (arriba a la izquierda)**
- **Retrato** de Ninfa en un aro de hierro. Con Hambre late en rojo y aparece "HAMBRE".
- **Vida:** celdas hexagonales. Al perder una destella blanca y se apaga; al curarte "salta". Con **1 sola de vida**, la última se pone roja y late.
- **Brasas:** 3 segmentos de fuego. Cuando uno se llena destella; los llenos brillan suave.

---

## El look: pixel art oscuro cyberpunk

- **Resolución del juego: 480 × 270**, escalada a la ventana. Todo el arte es pixel art donde **1 píxel = 1 unidad del juego**.
- **Filtro "Nearest"** en todo el proyecto (Proyecto > Configuración > Renderizado > Texturas). Nada de suavizado: los píxeles se ven filosos.
- **Post-proceso** (`shaders/post_fx.gdshader`, nodo `PostFX` en `main.tscn`): bloom para los neones y el fuego, aberración cromática suave, sombras azuladas, viñeta y líneas de barrido muy sutiles. Todo se ajusta desde el Inspector.
- **Paleta**: noche azul petróleo, concreto casi negro, y luces en rojo, turquesa, ámbar y **magenta**. El rojo-fuego queda reservado para Ninfa y su brazo.

### Ninfa: animada en partes, convertida a píxeles

Ninfa sale **directamente del concepto** (`art_source/ninfa/concepto.png`), sin redibujarla:

1. La vista de costado se separó en partes: cabeza, alas, brazo demoníaco, katana, piernas y cuerpo (`art_source/ninfa/partes/`).
2. `art_source/ninfa/herramientas/ninfa_anim.py` anima esas partes rotándolas sobre sus articulaciones, y **convierte cada cuadro a pixel art** (56 px de alto) con una paleta fija, contorno de 1 px, ojo blanco y grietas de fuego. Cada animación son unas pocas **poses clave** que se interpolan con suavizado; la capa de la cintura para abajo es una parte aparte que flamea, y las alas tiemblan como las de una libélula.
3. `build_ninfa_frames.gd` arma `entities/player/ninfa_frames.tres` (un `SpriteFrames`) con las tiras de `assets/characters/ninfa/`.
4. En el juego, `player.gd` agrega el "jugo": se estira al saltar, se aplasta al caer, se inclina al correr y hace un pequeño rebote al darse vuelta (`_squash()`).

Animaciones: `idle, run, jump, fall, attack, attack2, zarpazo, attack_up, attack_down, dash, glide, hurt, devour, cast, death, rest`.

**Para retocar una animación**: en `ninfa_anim.py` cada animación es una lista de poses (ángulo por parte). Cambiá los números, corré:
```
python3 ninfa_anim.py ../partes ../../../assets/characters/ninfa
godot --headless --path <proyecto> --script art_source/ninfa/herramientas/build_ninfa_frames.gd -- <carpeta>/frames.json
```
(necesita Python con numpy, scipy y Pillow). También se pueden editar los PNG de `assets/characters/ninfa/` a mano en Aseprite o LibreSprite: cada tira tiene cuadros de 140×97.

---

## Estructura de carpetas

```
res://
├── autoloads/              game_state (guardado), event_bus (señales), game_feel (hit-stop, temblor, efectos)
├── components/             health, hitbox, hurtbox, hit_flash, neon_flicker
├── data/abilities.gd       Catálogo de poderes (nombres y textos)
├── entities/
│   ├── player/             player.gd (Ninfa y los sistemas del pacto), sword_component.gd (combo),
│   │   │                   ninfa_frames.tres, player.tscn
│   │   └── powers/         garra_infernal, afterimage (sombras del galope), flesh_chunk (trozos del jefe)
│   ├── enemies/            enemy.gd (base: aturdido + devorar), beetle, moth, tick, projectile
│   └── bosses/recolectora/ el jefe, su onda expansiva y la chatarra que cae
├── fx/                     chispas, explosión, polvo, estallido al devorar
├── shaders/                rim_light (borde de luz + destello), post_fx (look de pantalla)
├── world/
│   ├── main/               escena raíz, fondo, primer plano, lluvia
│   ├── rooms/              room.gd + room_01..08.tscn
│   └── objects/            puerta, charca (save_point), pickups, pinches, carteles, faroles, vapor, arena de jefe
├── ui/                     título, intro, HUD, pausa
├── assets/                 todo el arte (pixel art)
└── art_source/             concepto, partes de Ninfa y herramientas (Godot no los importa)
```

## Arquitectura en 4 ideas

### 1. Componentes

Ninfa, los enemigos, el jefe, la Garra Infernal y hasta el proyectil enemigo usan **los mismos** `HealthComponent`, `HurtboxComponent` y `HitboxComponent`. Por eso devolver una bola de plasma o que la Garra atraviese enemigos no necesitó código especial.

```
Player (CharacterBody2D, player.gd)
├── Sprite (AnimatedSprite2D, ninfa_frames.tres, shader rim_light)
├── ArmGlow              brillo rojo del brazo
├── CollisionShape2D
├── Camera2D
├── HealthComponent
├── HurtboxComponent     ← lo que la lastima
├── Sword (SwordComponent)
│   └── SwordHitbox      ← katana / zarpazo (cambia daño y tamaño según el golpe)
├── DashHitbox           ← quema lo que atraviesa el Galope
├── DevourParticles
└── DashTrail
```

### 2. Herencia corta para los enemigos

`enemy.gd` (clase `Enemy`) resuelve lo común: retroceso, destello, muerte, y **aturdido + devorar**. Cada enemigo solo escribe su comportamiento en `_ai(delta)`. Para que un enemigo nuevo se pueda devorar no hay que hacer nada; para que no (como el jefe), `can_be_devoured = false`.

### 3. Autoloads

- **GameState**: habilidades, objetos agarrados, vida extra, salas visitadas, última charca, si ya viste la intro.
- **EventBus**: une escenas que no se conocen (el jugador avisa Brasas, Hambre y vida; el HUD escucha).
- **GameFeel**: `hit_stop()`, `shake()`, `spawn_fx()`.

### 4. Main persistente + salas intercambiables

```
Main
├── CityBackground, RoomContainer (una sala a la vez), Player, FX, Foreground
├── Rain, PostFX, HUD, PauseMenu   (CanvasLayer)
├── TransitionLayer/Fade
└── Intro                          (solo en partida nueva; el mundo queda en pausa)
```

### Capas de física

| # | Nombre | Quién | Detecta |
|---|---|---|---|
| 1 | world | tiles, pinches, barreras | — |
| 2 | player | cuerpo de Ninfa | world |
| 3 | enemies | cuerpo de enemigos y jefe | world |
| 4 | playerHurtbox | hurtbox de Ninfa | 7 |
| 5 | enemyHurtbox | hurtbox de enemigos y proyectiles | 6 |
| 6 | playerHitbox | katana, zarpazo, galope, garra | — |
| 7 | enemyHitbox | enemigos, proyectiles, pinches | — |

---

## Guías rápidas

### Medidas

- **1 tile = 16 unidades**. El arte del mundo está guardado a 4× (cada píxel es un bloque de 4×4) y se muestra a escala **0.25**: así las escenas no cambian, y en pantalla cada bloque es un píxel exacto.
- Ninguna sala puede ser **más angosta que 30 tiles ni más baja que 17**.
- Salto: ~3.5 tiles. Doble salto: ~6. Doble salto + galope: ~13 de largo.

### Crear una sala

Lo más fácil: duplicar `room_05.tscn`. Desde cero: raíz `Node2D` con `room.gd`, hijos `Decor`, `Tiles` (TileMapLayer con `res://assets/tiles/tileset.tres`, **Scale 0.25**), `PlayerStart`, `Doors`, `Objects`, `Enemies`, y un `atmosphere.tscn` con su **Room Size**. Pintá con la pestaña **Terrains** (terreno *Concreto*).

### Puertas

`door.tscn` en una abertura de 3 tiles. **Door Id**, **Target Room Path**, **Target Door Id** y **Spawn Offset** (`(32, 12)` en pared izquierda, `(-32, 12)` en la derecha). Siempre de a pares.

### Objetos

| Qué | Escena | Configurar |
|---|---|---|
| Poder | `ability_pickup.tscn` | **Ability** (`double_jump`, `dash`, `glide`, `garra`) y **Pickup Id** único |
| +1 vida | `health_core.tscn` | **Pickup Id** único |
| Charca | `save_point.tscn` | **Save Id** único; apoyada en el piso |
| Pinches | `spikes.tscn` | uno por tile |

### Ajustar el "game feel"

En el Inspector del nodo `Player` están todos los números agrupados: movimiento, salto, Galope, combate (ventana del combo), Brasas (cuánto da cada golpe, cuánto cuesta la Garra, cuándo se apagan), Devorar (alcance) y Hambre (cada cuánto).

---

## Pruebas

El juego tiene un playtest automático que recorre las 8 salas y controla 115 cosas (incluye: pegar quieta no te mueve, correr y pegar a la vez, buffer del combo, HUD de Brasas) (combo, aturdir y devorar, Brasas, Hambre, charcas, Garra, Galope, jefe, guardado, muerte, pausa). No viene en el zip para no ensuciar el proyecto; si lo quieren, pídanlo.

## Próximos pasos

1. **Sonido**: tajo, zarpazo, mordida al devorar, zumbido de la Estática, música.
2. **Sellos de ceniza**: paredes que solo rompe la Garra Infernal (para esconder secretos).
3. **Cadena del Pacto**: engancharse a anclas demoníacas (la recompensa que el lore le da a La Recolectora).
4. **Ira y Forma del Diablo**: barra que se llena al recibir daño; llena, 8 segundos de forma demoníaca.
5. **Recuerdos de la madre** (4 escondidos) para el final verdadero.

## Trabajo en equipo con Git

- **`.godot/` nunca se sube**. Sí se suben los `.import` y los `.uid`.
- **Una escena, un dueño a la vez**: mapa en `world/rooms/`, Ninfa en `entities/player/`, enemigos en `entities/enemies/`.
- **Ramas por feature** y Pull Request. **`git pull` antes de abrir Godot**, probar con F5 antes de hacer push.
