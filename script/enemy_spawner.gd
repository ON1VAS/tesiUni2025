extends Node2D
#configurazione dello spawner
@onready var ape = "res://scene/ape.tscn"
@onready var golem = "res://scene/golem.tscn"
@onready var cinghiale = "res://scene/chinghiale.tscn"
@onready var slime = "res://scene/slime.tscn"
@export var enemies: Array[PackedScene] = []
@export var spawn_points: Array[Marker2D] = []
@export var max_enemies: int = 5
@export var spawn_interval: float = 3.0

var current_enemies: int = 0

func _ready():
	$Timer.wait_time = spawn_interval
	enemies.append(preload("res://scene/ape.tscn"))
	enemies.append(preload("res://scene/golem.tscn"))
	enemies.append(preload("res://scene/chinghiale.tscn"))
	enemies.append(preload("res://scene/slime.tscn"))
	
	





func _on_timer_timeout() -> void:
	if current_enemies >= max_enemies:
		return
	spawn_enemy()

func spawn_enemy():
	var enemy_scene = enemies.pick_random()
	var spawn_point = spawn_points.pick_random()
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	add_child(enemy)
	current_enemies += 1
	print("nemico spawnato: ", enemy.name)

func _on_game_game_started() -> void:
	$Timer.start()
