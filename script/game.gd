extends Node2D

@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
@onready var scudo = $Area2Dscudo
@onready var dialogue_box = $DialogueBox #per le interazioni e i dialoghi
var shader_material = ShaderMaterial.new()
var can_start = true
var dialogues = {}
signal game_started


func _ready():
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	load_dialogues()
	player_an_sp.material = null #di default è spenta
	
	
func load_dialogues():
	var file = FileAccess.open("res://dialogue/dialogues.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		print("Contenuto del file JSON: ", json_text)  # Debug: visualizza il contenuto
		
		var parsed = JSON.parse_string(json_text)
		
		if parsed != null:  # Controllo se il parsing è riuscito
			dialogues = parsed
		else:
			print("Errore nel parsing del JSON. Verifica la sintassi del file.")
		
		file.close()
	else:
		print("Errore: impossibile aprire il file JSON. Percorso: res://dialogue/dialogues.json")

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
		dialogue_box.show_dialogue(dialogues["startDefense"])
		player_an_sp.material = shader_material

func _input(event: InputEvent) -> void:
	if can_start and event.is_action_pressed("ui_accept"): #fa scomparire la barriera e inizia la "difesa"
		$Area2Dscudo/scudo/AnimationPlayer.play("dissolvenza")
		_on_area_2_dscudo_body_exited(player)
		$Area2Dscudo.monitoring = false
		game_started.emit()
