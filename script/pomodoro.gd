extends Node2D



@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
var shader_material = ShaderMaterial.new()


func _ready():
	#disattiva la shader luminosa attorno al player
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta
