extends Node2D

@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
@onready var scudo = $Area2Dscudo
@onready var scudo_slime_dx = $hitboxes/scudo_slime_dx
@onready var scudo_slime_sx = $hitboxes/scudo_slime_sx
@onready var dialogue_box = $DialogueBox #per le interazioni e i dialoghi
var shader_material = ShaderMaterial.new()
var can_start = true
var shield = true
var dialogues = {}
signal game_started(valore: int) #l'int è la difficoltà
var incremento_difficolta = 2 #aumenta di 1 per ogni wave completata
var first_wave = true #serve per il check per capire se sia o meno la prima wave

func _ready():
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	load_dialogues()
	player_an_sp.material = null #di default è spenta
	
	
func load_dialogues():
	var file = FileAccess.open("res://dialogue/dialogues.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		#eprint("Contenuto del file JSON: ", json_text)  # Debug: visualizza il contenuto
		
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
		if (first_wave):
			dialogue_box.show_dialogue(dialogues["startDefense"])
		else:
			dialogue_box.show_dialogue(dialogues["continueDefense"])
		player_an_sp.material = shader_material

func _input(event: InputEvent) -> void:
	if can_start and event.is_action_pressed("ui_accept"): #fa scomparire la barriera e inizia la "difesa"
		if (first_wave):
			$Area2Dscudo/scudo/AnimationPlayer.play("dissolvenza")
			first_wave = false
			print("prima ondata è iniziata")
		_on_area_2_dscudo_body_exited(player)
		$Area2Dscudo.monitoring = false
		scudo_slime_dx.disabled = true
		scudo_slime_sx.disabled = true
		scudo = false
		emit_signal("game_started", incremento_difficolta)
	elif can_start and event.is_action_pressed("return_home"):
		can_start = false
		if !scudo:
			$Area2Dscudo/scudo/AnimationPlayer.play("dissolvenza_inv")
			scudo_slime_dx.disabled = false
			scudo_slime_sx.disabled = false
			await $Area2Dscudo/scudo/AnimationPlayer.animation_finished
		scene_change()


func _on_enemy_spawner_wave_ended() -> void:
	
	dialogue_box.visible = true
	dialogue_box.show_dialogue(dialogues["waveEnded"])
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)  # add the timer to the scene tree to work correctly
	timer.start()
	await timer.timeout
	dialogue_box.visible = false
	timer.queue_free()  # cleanup the timer
	incremento_difficolta+=1
	print("difficolta: ", incremento_difficolta)
	$Area2Dscudo.monitoring = true

func scene_change():
	#cambio scena
	get_tree().change_scene_to_file("res://scene/hub_map.tscn")
