# cloud_level.gd
extends Node2D

const PLAYER_GROUP := "giocatore"
const ENEMIES_GROUP := "enemies"

@export var activation_radius: float = 280.0   # alza se vuoi svegliare da più lontano
@export var one_shot_triggers: bool = true

@onready var player: Node2D = $protagonista
@onready var sprite2D5: Node2D = $Sprite2D5
@onready var sprite2D3: Node2D = $Sprite2D3
@onready var sprite2D4: Node2D = $Sprite2D4
@onready var player_an_sp = $protagonista/AnimatedSprite2D
var shader_material = ShaderMaterial.new()

func _ready() -> void:
	# piattaforma on + debuff
	DebuffManager.set_platform_mode(true)
	DebuffManager.add_debuff("NO_JUMP")
	DebuffManager.apply_to_player(player)
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta
	

	# assicurati che il player sia nel gruppo corretto
	if player and not player.is_in_group(PLAYER_GROUP):
		player.add_to_group(PLAYER_GROUP)

	# spegni tutti i nemici e crea un'area di attivazione DEDICATA per ciascuno
	for e in get_tree().get_nodes_in_group(ENEMIES_GROUP):
		_set_active_recursive(e, false)
		_create_activation_area(e)

func _process(delta: float) -> void:
	# parallasse semplice: solo la X segue il player
	var px := player.position.x
	sprite2D5.position.x = px
	sprite2D4.position.x = px
	sprite2D3.position.x = px

# ---------------- helpers ----------------

func _set_active_recursive(n: Node, active: bool) -> void:
	if n.has_method("set_process"): n.set_process(active)
	if n.has_method("set_physics_process"): n.set_physics_process(active)
	for c in n.get_children():
		_set_active_recursive(c, active)

func _create_activation_area(enemy: Node) -> void:
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

	# la nostra area vede solo il player; non tocchiamo le aree dell'AI del nemico
	if player and ("collision_layer" in player):
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
