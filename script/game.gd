extends Node2D

const PLAYER_GROUP := "giocatore"
const ENEMIES_GROUP := "enemies"

@export var activation_radius: float = 280.0   # alza/abbassa a gusto
@export var one_shot_triggers: bool = true

@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
@onready var scudo = $Area2Dscudo
@onready var scudo_slime_dx = $hitboxes/scudo_slime_dx
@onready var scudo_slime_sx = $hitboxes/scudo_slime_sx
@onready var dialogue_box = $DialogueBox
@onready var energyBar = $CanvasLayer/VBoxContainer/energiaBar

var shader_material = ShaderMaterial.new()
var can_start = true
var shield = true
var dialogues = {}
signal game_started(valore: int)
var incremento_difficolta = 2
var first_wave = true

func _ready():
	# shader + UI
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	load_dialogues()
	player_an_sp.material = null
	player.show_health_bar()
	energyBar.value = GlobalStats.energia
	$CanvasLayer/VBoxContainer/energiaBar/Label.text = "%d / %d" % [GlobalStats.energia, 100]

	# modalità platform (come negli altri livelli)
	DebuffManager.set_platform_mode(true) # forza il debuff vignette (salta il random)
	DebuffManager.apply_to_player(player)

	# gruppo player
	if not player.is_in_group(PLAYER_GROUP):
		player.add_to_group(PLAYER_GROUP)

	# --- ATTIVAZIONE NEMICI (stessa logica degli altri livelli) ---
	# Spegni tutti i nemici presenti ora e crea ActivationArea dedicata
	for e in get_tree().get_nodes_in_group(ENEMIES_GROUP):
		_set_active_recursive(e, false)
		_create_activation_area(e)

	# Gestisci anche i nemici istanziati DOPO (_spawner_)
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(n: Node) -> void:
	# quando entra un nodo in scena, se è un nemico preparalo
	# (delay per assicurarsi che sia nel tree con i figli pronti)
	if n.is_in_group(ENEMIES_GROUP):
		call_deferred("_prepare_enemy_after_spawn", n)

func _prepare_enemy_after_spawn(enemy: Node) -> void:
	if not is_instance_valid(enemy): return
	_set_active_recursive(enemy, false)
	_create_activation_area(enemy)

# ----------------- Activation helpers -----------------

func _set_active_recursive(n: Node, active: bool) -> void:
	if n.has_method("set_process"): n.set_process(active)
	if n.has_method("set_physics_process"): n.set_physics_process(active)
	for c in n.get_children():
		_set_active_recursive(c, active)

func _create_activation_area(enemy: Node) -> void:
	# Area dedicata (non tocchiamo le aree dell’AI del nemico)
	var area := Area2D.new()
	area.name = "_LevelActivationArea"
	enemy.add_child(area)
	area.owner = get_tree().current_scene

	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = activation_radius
	cs.shape = shape
	area.add_child(cs)
	cs.owner = get_tree().current_scene

	# vede solo il player
	if "collision_layer" in player:
		area.collision_mask = player.collision_layer
	area.collision_layer = 0

	var cb := Callable(self, "_on_activation_enter").bind(enemy, area)
	if not area.is_connected("body_entered", cb):
		area.body_entered.connect(cb)
	area.monitoring = true

func _on_activation_enter(body: Node2D, enemy: Node, area: Area2D) -> void:
	if not body.is_in_group(PLAYER_GROUP):
		return
	_set_active_recursive(enemy, true)
	if one_shot_triggers:
		area.set_deferred("monitoring", false)


func load_dialogues():
	var file = FileAccess.open("res://dialogue/dialogues.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed != null:
			dialogues = parsed
		else:
			print("Errore nel parsing del JSON. Verifica la sintassi del file.")
		file.close()
	else:
		print("Errore: impossibile aprire il file JSON. Percorso: res://dialogue/dialogues.json")

func _on_area_2_dscudo_body_exited(body: Node2D) -> void:
	if body.name == "protagonista":
		can_start = false
		dialogue_box.visible = false
		player_an_sp.material = null

func _on_area_2_dscudo_body_entered(body: Node2D) -> void:
	if body.name == "protagonista":
		can_start = true
		dialogue_box.visible = true
		if first_wave:
			dialogue_box.show_dialogue(dialogues["startDefense"])
		else:
			dialogue_box.show_dialogue(dialogues["continueDefense"])
		player_an_sp.material = shader_material

func _input(event: InputEvent) -> void:
	if can_start and event.is_action_pressed("ui_accept"):
		if first_wave:
			$Area2Dscudo/scudo/AnimationPlayer.play("dissolvenza")
			first_wave = false
		_on_area_2_dscudo_body_exited(player)
		$Area2Dscudo.monitoring = false
		scudo_slime_dx.disabled = true
		scudo_slime_sx.disabled = true
		scudo = false
		emit_signal("game_started", incremento_difficolta)
	elif can_start and event.is_action_pressed("return_home"):
		can_start = false
		if !scudo:
			$Area2Dscudo/scudo/AnimationPlayer.play("dissolvenza_inv")
			scudo_slime_dx.disabled = false
			scudo_slime_sx.disabled = false
			await $Area2Dscudo/scudo/AnimationPlayer.animation_finished
		scene_change()

func _on_enemy_spawner_wave_ended() -> void:
	GlobalStats.riduci_energia(5)
	dialogue_box.visible = true
	dialogue_box.show_dialogue(dialogues["waveEnded"])
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	await timer.timeout
	dialogue_box.visible = false
	timer.queue_free()
	incremento_difficolta += 1
	$Area2Dscudo.monitoring = true
	energyBar.value = GlobalStats.energia
	$CanvasLayer/VBoxContainer/energiaBar/Label.text = "%d / %d" % [GlobalStats.energia, 100]

func scene_change():
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://scene/hub_map.tscn")


func _on_protagonista_player_defeated() -> void:
	pass
