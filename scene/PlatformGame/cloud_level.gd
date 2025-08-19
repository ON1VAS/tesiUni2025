extends Node2D

@onready var player = $protagonista
@onready var sprite2D5 = $Sprite2D5
@onready var sprite2D3 = $Sprite2D3
@onready var sprite2D4 = $Sprite2D4

func _ready() -> void:
	DebuffManager.set_platform_mode(true)
	DebuffManager.apply_to_player($protagonista)


func _process(delta):
	# Mantieni solo la coordinata X del player, Y rimane fissa
	sprite2D5.position.x = player.position.x
	sprite2D4.position.x = player.position.x
	sprite2D3.position.x = player.position.x
