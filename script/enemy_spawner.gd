extends Node2D
#configurazione dello spawner
@export var enemies: Array[PackedScene] = []
@export var spawn_points: Array[Marker2D] = []
@export var max_enemies: int = 2
@export var spawn_interval: float = 3.0

var current_enemies: int = 0
var defeated_enemies: int = 0

func _ready():
	$Timer.wait_time = spawn_interval #fa il preload dei nemici e li aggiunge all'array
	enemies.append(preload("res://scene/ape.tscn"))
	#enemies.append(preload("res://scene/golem.tscn"))
	#enemies.append(preload("res://scene/chinghiale.tscn"))
	#enemies.append(preload("res://provapermodificare/ragno/ragno.tscn"))
	#enemies.append(preload("res://scene/slime.tscn"))


func _on_timer_timeout() -> void: #loop che spawna i nemici
	if current_enemies >= max_enemies:
		return
	spawn_enemy()

func spawn_enemy(): #spawna i nemici
	var enemy_scene = enemies.pick_random()
	var spawn_point = spawn_points.pick_random()
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	enemy.dead.connect(_on_enemy_dead)
	add_child(enemy)
	current_enemies += 1
	print("nemico spawnato: ", enemy.name," ", spawn_point.name)

func _on_game_game_started() -> void: #timer
	$Timer.start()

func _on_enemy_dead(): #così il gioco sa quando la wave è finita
	defeated_enemies+=1
	print("nemico morto. nemici rimanenti: ", current_enemies - defeated_enemies)
	if (current_enemies == defeated_enemies):
		wave_finished()

func wave_finished():
	print("wave finita")
