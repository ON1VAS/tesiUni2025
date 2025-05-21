extends Node2D

@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
@onready var scudo = $Area2Dscudo
var shader_material = ShaderMaterial.new()

func _ready():
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta
	scudo.monitoring = false
	await get_tree().create_timer(0.1).timeout
	scudo.monitoring = true
	

func _on_area_2_dscudo_body_exited(body: Node2D) -> void:
	if body.name == "protagonista":
		print("uscito")
		player_an_sp.material = null


func _on_area_2_dscudo_body_entered(body: Node2D) -> void:
	if body.name == "protagonista":
		print("entrato")
		player_an_sp.material = shader_material
