extends Node2D

# Se vuoi mostrare che modalità stai continuando (opzionale):
var mode := LevelFlow.Mode.PLATFORM_CAMPAIGN

func _ready() -> void:
	# Se arrivi qui al termine di un livello platform, assicura la modalità corrente
	$AnimatedSprite2D.play("default")
	$AnimatedSprite2D2.play("default")
	LevelFlow.current_mode = LevelFlow.Mode.PLATFORM_CAMPAIGN

func _on_riposa_pressed() -> void:
	# Cura (recupera il player come preferisci: autoload, singleton, o salvataggio)
	var player := _get_player_reference()
	if player and "max_health" in player and "health" in player and "SetHealthBar" in player:
		player.health = player.max_health
		player.SetHealthBar()
	# Avvia il lock 5 minuti
	RestLock.start(300)

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

func _process(_delta: float) -> void:
	# Se vuoi disabilitare il tasto "Continua" via UI, usa RestLock.remaining()
	pass

func _get_player_reference() -> Node:
	# Implementa secondo la tua architettura: ad es. un autoload PlayerState, o un nodo persistente
	return null
