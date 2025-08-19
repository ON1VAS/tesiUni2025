extends Node

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

# === API pubblica ===

## Abilita/Disabilita l'effetto del manager nei livelli platform
func set_platform_mode(enabled: bool) -> void:
	platform_mode = enabled
	if not platform_mode:
		clear_all()

## Imposta i debuff attivi da un array di stringhe (sovrascrive lo stato)
func set_debuffs(debuff_names: Array[String]) -> void:
	active_debuffs.clear()
	for n in debuff_names:
		active_debuffs[n] = true

## Aggiungi o rimuovi un debuff singolo
func add_debuff(name: String) -> void:
	active_debuffs[name] = true

func remove_debuff(name: String) -> void:
	active_debuffs.erase(name)

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
		if "can_jump" in player: player.can_jump = false
		if "ignore_jump_input" in player: player.ignore_jump_input = true

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
	var d := pick_random_debuff()
	if d == "":
		return ""
	active_debuffs.clear()
	active_debuffs[d] = true
	return d


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
