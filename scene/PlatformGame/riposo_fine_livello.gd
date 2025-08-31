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
	var p := _get_player_reference()
	if p and "max_health" in p and "health" in p and "SetHealthBar" in p:
		p.health = p.max_health
		p.SetHealthBar()

	DebuffManager.clear_all()
	DebuffManager.grant_rest_grace()  # ⬅️ salta il prossimo debuff
	RestLock.start(300)               # 5 minuti
	_refresh_ui()


func _on_continua_pressed() -> void:
	if RestLock.is_active():
		return
	# Debuff random SOLO in campagna platform
	if LevelFlow.current_mode == LevelFlow.Mode.PLATFORM_CAMPAIGN:
		# Se hai riposato prima, salta il debuff UNA volta
		if not DebuffManager.consume_rest_grace():
			var chosen := DebuffManager.set_random_debuff()
			print("Debuff scelto automaticamente:", chosen)
		else:
			print("Riposo effettuato: nessun debuff questa volta.")

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
