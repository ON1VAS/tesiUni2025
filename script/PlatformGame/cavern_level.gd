extends Node2D

const PLAYER_GROUP := "giocatore"
const ENEMIES_GROUP := "enemies"

@export var activation_radius: float = 280.0  # aumenta se vuoi svegliare da più lontano
@export var one_shot_triggers: bool = true

#toglie l'evidenziato
@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
var shader_material = ShaderMaterial.new()

func _ready() -> void:
	#toglie l'evidenziato
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta
	
	if $protagonista and not $protagonista.is_in_group(PLAYER_GROUP):
		$protagonista.add_to_group(PLAYER_GROUP)

	# 1) spegni tutti i nemici e crea un'area DEDICATA per l'attivazione
	for e in get_tree().get_nodes_in_group(ENEMIES_GROUP):
		_set_active_recursive(e, false)
		_create_activation_area(e)

	DebuffManager.set_platform_mode(true)
	DebuffManager.apply_to_player($protagonista)

# ---------- helpers ----------

func _set_active_recursive(n: Node, active: bool) -> void:
	# attiva/disattiva process e physics del nodo + figli
	if n.has_method("set_process"): n.set_process(active)
	if n.has_method("set_physics_process"): n.set_physics_process(active)
	for c in n.get_children():
		_set_active_recursive(c, active)

func _create_activation_area(enemy: Node) -> void:
	# NON riusiamo aree esistenti del nemico (possono servire all'AI!)
	# Creiamo una nostra area figlia dedicata al wake-up.
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

	# Vede solo il player, non tocca i layer delle aree originali del nemico
	if $protagonista and ("collision_layer" in $protagonista):
		area.collision_mask = $protagonista.collision_layer
	area.collision_layer = 0

	# collega handler; bindiamo il riferimento al NEMICO e all'AREA
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
