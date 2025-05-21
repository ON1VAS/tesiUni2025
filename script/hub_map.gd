extends Node2D

@onready var dialogue_box = $DialogueBox  # Riferimento al nodo DialogueBox
@onready var npcJoanna = $npc_Joanna  # Riferimento al nodo NPC
@onready var npcEleonore = $npc_eleonore  # Riferimento al nodo NPC
@onready var player = $protagonista
@onready var startGame = $Area2DstartGame
@onready var player_an_sp = $protagonista/AnimatedSprite2D
var player_in_range = false
var can_start_dialogue = true  # Nuovo flag per controllare la possibilità di iniziare dialogo
var dialogues = {}
var npc_name = ""
var can_start_game = false
var shader_material = ShaderMaterial.new()



func _ready():
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta
	npcJoanna.connect("body_entered", _on_npc_body_entered.bind("npc_Joanna"))
	npcJoanna.connect("body_exited", _on_npc_body_exited.bind("npc_Joanna"))
	npcEleonore.connect("body_entered", _on_npc_body_entered.bind("npc_Eleonore"))
	npcEleonore.connect("body_exited", _on_npc_body_exited.bind("npc_Eleonore"))
	
	startGame.connect("body_entered", _on_start_game_area_entered)
	startGame.connect("body_exited", _on_start_game_area_exited)
	load_dialogues()
	# Ascolta il segnale dalla dialogue box se viene aggiunto (opzionale)
	# if dialogue_box.has_signal("dialogue_ended"):
	#     dialogue_box.connect("dialogue_ended", self, "_on_dialogue_ended")

func _on_npc_body_entered(body, npc):
	if body.name == "protagonista":
		npc_name = npc
		player_in_range = true
		can_start_dialogue = true  # Reset possibilità dialogo solo entrando nell'area
		dialogue_box.visible = true
		dialogue_box.talk_prompt("Parla [E]")
		print("Player entrato nell'area dell'NPC")
		print(npc_name)

func _on_npc_body_exited(body,npc):
	if body.name == "protagonista":
		player_in_range = false
		can_start_dialogue = true  # anche se esce, resetto questa flag per sicurezza
		dialogue_box.visible = false
		print("Player uscito dall'area dell'NPC")
		npc_name = npc

#res://dialogue/dialogues.json
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
	

func _input(event):
	if player_in_range and can_start_dialogue and event.is_action_pressed("ui_accept"):
		_start_dialogue()
	if can_start_game and event.is_action_pressed("ui_accept"):
		scene_change()
		
		

func _start_dialogue():
	if npc_name=="npc_Eleonore":
		if player.position.x > npcEleonore.position.x:
			$npc_eleonore/AnimatedSprite2D.flip_h = true
		else:
			$npc_eleonore/AnimatedSprite2D.flip_h = false
	
	if npc_name=="npc_Joanna":
		if player.position.x > npcJoanna.position.x:
			$npc_Joanna/AnimatedSprite2D.flip_h = true
		else:
			$npc_Joanna/AnimatedSprite2D.flip_h = false
	
	
	if dialogues.has(npc_name):
		dialogue_box.show_dialogue(dialogues[npc_name])
		can_start_dialogue = false  # Impedisco riavvio del dialogo finché non esce e rientra
	else:
		print("dialogo non trovato per ", npc_name)

#cambio scena, inizio gioco
func _on_start_game_area_entered(body):
	if body.name == "protagonista":
		dialogue_box.talk_prompt("Premi [E] per uscire e difendere la base")
		dialogue_box.visible = true
		can_start_game = true
		print("entrata ", can_start_game)

func _on_start_game_area_exited(body):
	can_start_game = false
	dialogue_box.visible = false
	print("uscita ", can_start_game)

func scene_change():
	#cambio scena
	get_tree().change_scene_to_file("res://scene/game.tscn")
