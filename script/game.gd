extends Node2D

@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
@onready var scudo = $Area2Dscudo
@onready var dialogue_box = $DialogueBox #per le interazioni e i dialoghi
var shader_material = ShaderMaterial.new()
var can_start = true

func _ready():
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta
	
	
	

func _on_area_2_dscudo_body_exited(body: Node2D) -> void:
	if body.name == "protagonista":
		can_start = false
		print("uscito ", can_start)
		dialogue_box.visible = false
		player_an_sp.material = null


func _on_area_2_dscudo_body_entered(body: Node2D) -> void:
	if body.name == "protagonista":
		
		can_start = true
		print("entrato ", can_start)
		dialogue_box.visible = true
		dialogue_box.talk_prompt("Premi [E] per disattivare lo scudo e iniziare la difesa")
		player_an_sp.material = shader_material

func _input(event: InputEvent) -> void:
	if can_start and event.is_action_pressed("ui_accept"):
		$Area2Dscudo/scudo/AnimationPlayer.play("dissolvenza")
		_on_area_2_dscudo_body_exited(player)
		$Area2Dscudo.monitoring = false
