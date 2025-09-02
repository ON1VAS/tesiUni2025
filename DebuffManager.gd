extends Node

signal debuffs_updated

var _grace_no_debuff := false  # se true, il prossimo "continua" NON assegna debuff

# Concedi la grazia (chiamata quando riposi)
func grant_rest_grace() -> void:
	_grace_no_debuff = true
# Attiva il processing per timer inversione comandi & drain HP
func _ready() -> void:
	set_process(true)

# === Stato e configurazione ===
var platform_mode: bool = false  # true quando siamo in un livello platform
var active_debuffs: = {}         # set di string -> true
var command_inverted := false
var _invert_timer := 0.0
var invert_interval := 2.0       # ogni 2s può flippare

# Per perdita HP ogni 10s
var _hp_drain_timer_running := false
var _player_ref: WeakRef = null

# === Debuff disponibili (nomi canonicali) ===
const DEBUFF = {
	"SLOW": "SLOW",
	"LOW_DAMAGE": "LOW_DAMAGE",
	"ATTACK_DELAY": "ATTACK_DELAY",
	"NO_ROLL": "NO_ROLL",
	"NO_JUMP": "NO_JUMP",
	"HP_DRAIN": "HP_DRAIN",
	"INVERT_COMMANDS": "INVERT_COMMANDS",
	"ENEMY_DAMAGE_UP": "ENEMY_DAMAGE_UP",
	"SLIDING": "SLIDING",
	"VIGNETTE": "VIGNETTE",
}

# (opzionale) mappa icone: DEBUFF_NAME -> Texture2D
# metti i path giusti ai tuoi asset
var DEBUFF_ICON: Dictionary = {
	"SLOW": preload("res://testures/Platform/DebuffIcons/slow.png"),
	"LOW_DAMAGE": preload("res://testures/Platform/DebuffIcons/low_damage.png"),
	"ATTACK_DELAY": preload("res://testures/Platform/DebuffIcons/attack_delay.png"),
	"NO_ROLL": preload("res://testures/Platform/DebuffIcons/no_roll.png"),
	"NO_JUMP": preload("res://testures/Platform/DebuffIcons/no_jump.png"),
	"HP_DRAIN": preload("res://testures/Platform/DebuffIcons/hp_drain.png"),
	"INVERT_COMMANDS": preload("res://testures/Platform/DebuffIcons/invert.png"),
	"ENEMY_DAMAGE_UP": preload("res://testures/Platform/DebuffIcons/enemy_up.png"),
	"SLIDING": preload("res://testures/Platform/DebuffIcons/sliding.png"),
	"VIGNETTE": preload("res://testures/Platform/DebuffIcons/vignette.png"),
}

## Abilita/Disabilita l'effetto del manager nei livelli platform
func set_platform_mode(enabled: bool) -> void:
	platform_mode = enabled
	set_process(enabled)  # ferma _process quando non sei in platform
	if not platform_mode:
		# sospendi effetti runtime, ma NON cancelli la lista
		command_inverted = false
		_hp_drain_timer_running = false
	debuffs_updated.emit()

# Usa (e consuma) la grazia; ritorna true se la grazia c'era
func consume_rest_grace() -> bool:
	if _grace_no_debuff:
		_grace_no_debuff = false
		return true
	return false

## Imposta i debuff attivi da un array di stringhe (sovrascrive lo stato)
func set_debuffs(debuff_names: Array[String]) -> void:
	active_debuffs.clear()
	for n in debuff_names:
		active_debuffs[n] = true
	debuffs_updated.emit()

## Aggiungi o rimuovi un debuff singolo
func add_debuff(name: String) -> void:
	active_debuffs[name] = true
	debuffs_updated.emit()

func remove_debuff(name: String) -> void:
	active_debuffs.erase(name)
	debuffs_updated.emit()

## Applica i debuff al player (chiamala in _ready del livello e quando cambi debuff)
func apply_to_player(player: Node) -> void:
	if not platform_mode: 
		return

	_player_ref = weakref(player)

	# RESET valori "baseline"
	if "speed" in player: player.speed = 200
	if "damage" in player: player.damage = 15
	if "can_roll" in player: player.can_roll = true
	if "can_jump" in player: player.can_jump = true
	if "ignore_jump_input" in player: player.ignore_jump_input = false
	if "attack_input_delay" in player: player.attack_input_delay = 0.0
	if "jump_force" in player: player.jump_force = 0

	# --- Applica effetti singoli ---
	if active_debuffs.has(DEBUFF.SLOW):
		if "speed" in player: player.speed = 150

	if active_debuffs.has(DEBUFF.LOW_DAMAGE):
		if "damage" in player: player.damage = 10

	if active_debuffs.has(DEBUFF.ATTACK_DELAY):
		if "attack_input_delay" in player: player.attack_input_delay = 0.5

	if active_debuffs.has(DEBUFF.NO_ROLL):
		if "can_roll" in player: player.can_roll = false

	if active_debuffs.has(DEBUFF.NO_JUMP):
		if "jump_force" in player and "JUMP_FORCE" in player:
			player.can_jump = true
			player.ignore_jump_input = false
			player.jump_force = -player.JUMP_FORCE * 0.5

	# HP drain parte/continua tramite timer asincrono
	if active_debuffs.has(DEBUFF.HP_DRAIN):
		_start_hp_drain_loop()
	else:
		_hp_drain_timer_running = false

	# INVERT_COMMANDS è gestito da _process con flip casuale
	# ENEMY_DAMAGE_UP, SLIDING e VIGNETTE sono esposti come getter

## Pulisce tutto
func clear_all() -> void:
	active_debuffs.clear()
	command_inverted = false
	_hp_drain_timer_running = false
	_player_ref = null
	debuffs_updated.emit()

# === Helper che il tuo player o l'HUD può interrogare ===

func enemy_damage_multiplier() -> float:
	if platform_mode and active_debuffs.has(DEBUFF.ENEMY_DAMAGE_UP):
		return 1.5
	return 1.0

func is_sliding_active() -> bool:
	if platform_mode and active_debuffs.has(DEBUFF.SLIDING):
		return true
	return false

func is_vignette_active() -> bool:
	if platform_mode and active_debuffs.has(DEBUFF.VIGNETTE):
		return true
	return false

func is_command_inverted() -> bool:
	if platform_mode and active_debuffs.has(DEBUFF.INVERT_COMMANDS) and command_inverted:
		return true
	return false


# === Loop inversione comandi & drain HP ===

func _process(delta: float) -> void:
	if not platform_mode:
		return

	# Flip random dei comandi se attivo
	if active_debuffs.has(DEBUFF.INVERT_COMMANDS):
		_invert_timer += delta
		if _invert_timer >= invert_interval:
			_invert_timer = 0.0
			command_inverted = randi() % 2 == 0

# Perdita di 1 HP ogni 10 secondi finché attivo e su livello platform
func _start_hp_drain_loop() -> void:
	if _hp_drain_timer_running:
		return
	_hp_drain_timer_running = true
	call_deferred("_hp_drain_coroutine")

# Pool dei debuff candidati (escludi quelli che non vuoi mai dare a caso)
func _random_debuff_pool() -> Array:
	# Usa DEBUFF.values() per tutti. Se vuoi filtrare, modifica l'array qui.
	return DEBUFF.values()

# Ritorna il nome del debuff scelto
func pick_random_debuff() -> String:
	var pool := _random_debuff_pool()
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]

# Sceglie UN debuff a caso e lo imposta, sovrascrivendo gli altri
func set_random_debuff() -> String:
	var pool = _random_debuff_pool().filter(
		func(n): return not active_debuffs.has(n)
	)
	if pool.is_empty():
		return ""  # già li hai tutti

	var d = pool[randi() % pool.size()]
	active_debuffs[d] = true
	debuffs_updated.emit()
	return d

func get_active_debuffs() -> Array[String]:
	var out: Array[String] = []
	for k in active_debuffs.keys():
		out.append(String(k))
	return out


func get_primary_debuff() -> String:
	# se c’è un solo debuff (come nel tuo set_random_debuff) restituisce quello
	for k in active_debuffs.keys():
		return k
	return ""

@warning_ignore("redundant_await")
func _hp_drain_coroutine() -> void:
	while _hp_drain_timer_running and platform_mode and active_debuffs.has(DEBUFF.HP_DRAIN):
		await get_tree().create_timer(10.0).timeout
		if not _hp_drain_timer_running:
			break
		var p: Node = _player_ref.get_ref() if _player_ref else null
		if p and "health" in p and "SetHealthBar" in p:
			if p.health > 1:
				p.health -= 1
				p.SetHealthBar()
			elif "die" in p:
				p.die()
