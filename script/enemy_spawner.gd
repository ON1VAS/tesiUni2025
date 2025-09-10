extends Node2D

@export var enemies: Array[PackedScene] = []
@export var spawn_points: Array[Marker2D] = []
@export var max_enemies: int = 5
@export var spawn_interval: float = 5.0
@export var difficulty_interval: float = 30.0 #ogni quanti secondi aumenta la difficoltà

var current_enemies: int = 0

func _ready():
	# Carica le scene nemiche
	#enemies.append(preload("res://scene/ape.tscn"))
	#enemies.append(preload("res://scene/golem.tscn"))
	#enemies.append(preload("res://scene/chinghiale.tscn"))
	#enemies.append(preload("res://scene/slime.tscn"))
	#enemies.append(preload("res://scene/golem_pietra.tscn"))
	#enemies.append(preload("res://provapermodificare/ragno/ragno.tscn"))

	# Imposta e avvia il timer
	$Timer.wait_time = spawn_interval
	$Timer.start()
	


func _on_timer_timeout() -> void:
	if current_enemies < max_enemies:
		spawn_enemy()

func spawn_enemy():
	var enemy_scene = enemies.pick_random()
	var spawn_point = spawn_points.pick_random()
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	enemy.dead.connect(_on_enemy_dead)
	add_child(enemy)
	current_enemies += 1
	print("Nemico spawnato: ", enemy.name, " in ", spawn_point.name)

func _on_enemy_dead():
	current_enemies -= 1
	print("Nemico morto. Nemici attivi: ", current_enemies)


func _on_difficulty_timer_timeout():
	max_enemies += 1
	print("numero di nemici max incrementato")
	
