extends Node
## Bus de eventos global (Autoload "EventBus").
##
## Es el patrón Observer a nivel de juego: quien AVISA emite una señal acá,
## y quien REACCIONA se conecta acá. Así una puerta no necesita conocer a Main,
## ni el jugador al HUD. Cada uno solo conoce al EventBus.
##
## Regla del equipo: solo van acá eventos que cruzan escenas.
## Si dos nodos están en la misma escena, conéctenlos directamente.

## Una puerta pide cambiar de sala. spawn_id = id de la puerta/santuario donde aparecer.
@warning_ignore("unused_signal")
signal room_change_requested(room_path: String, spawn_id: String)

## Se cargó una sala nueva (útil para el HUD, música, minimapa futuro...).
@warning_ignore("unused_signal")
signal room_entered(room_name: String)

## La vida del jugador cambió (el HUD la dibuja).
@warning_ignore("unused_signal")
signal player_health_changed(current: int, max_value: int)

## El jugador murió (Main se encarga del respawn).
@warning_ignore("unused_signal")
signal player_died

## Mostrar un mensaje en pantalla (habilidad nueva, partida guardada, etc.).
@warning_ignore("unused_signal")
signal message_requested(text: String, duration: float)
