extends Node2D

# Se vuoi mostrare che modalità stai continuando (opzionale):
var mode := LevelFlow.Mode.PLATFORM_CAMPAIGN
@onready var continue_btn: Button = $MarginContainer/VBoxContainer/Continua

var _ui_accum := 0.0
const UI_TICK := 0.25

func _ready() -> void:
	# Se arrivi qui al termine di un livello platform, assicura la modalità corrente
	$AnimatedSprite2D.play("default")
	$AnimatedSprite2D2.play("default")
	LevelFlow.current_mode = LevelFlow.Mode.PLATFORM_CAMPAIGN
	RestLock.lock_changed.connect(_refresh_ui)
	_refresh_ui()

func _on_riposa_pressed() -> void:
	# Cura (recupera il player come preferisci: autoload, singleton, o salvataggio)
	var player := _get_player_reference()
	if player and "max_health" in player and "health" in player and "SetHealthBar" in player:
		player.health = player.max_health
		player.SetHealthBar()
	# Avvia il lock 5 minuti
	RestLock.start(300)
	_refresh_ui()

func _on_continua_pressed() -> void:
	if RestLock.is_active():
		return
	# Debuff random SOLO in campagna platform
	if LevelFlow.current_mode == LevelFlow.Mode.PLATFORM_CAMPAIGN:
		var chosen := DebuffManager.set_random_debuff()
		print("Debuff scelto automaticamente:", chosen)

	# Avanza pista platform e carica
	var next_scene := LevelFlow.advance_and_get_next(LevelFlow.current_mode)
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
	else:
		push_error("Fine livelli della campagna platform (nessun prossimo livello).")
		# opzionale: vai a una scena finale/credits/menu


func _process(delta: float) -> void:
	if RestLock.is_active():
		_ui_accum += delta
		if _ui_accum >= UI_TICK:
			_ui_accum = 0.0
			_refresh_ui()
	elif _ui_accum != 0.0:
		_ui_accum = 0.0
		_refresh_ui()

func _refresh_ui() -> void:
	if RestLock.is_active():
		continue_btn.text = _format_time(RestLock.remaining())
		continue_btn.disabled = true
	else:
		continue_btn.text = "Continua"
		continue_btn.disabled = false

func _format_time(rem: int) -> String:
	var minutes: int = rem / 60
	var seconds: int = rem % 60
	return "%02d:%02d" % [minutes, seconds]

func _get_player_reference() -> Node:
	return null
