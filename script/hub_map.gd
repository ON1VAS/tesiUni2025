extends Node2D

@onready var dialogue_box = $DialogueBox  # Riferimento al nodo DialogueBox
@onready var npcJoanna = $npc_Joanna  # Riferimento al nodo NPC
@onready var npcEleonore = $npc_eleonore  # Riferimento al nodo NPC
var player_in_range = false
var can_start_dialogue = true  # Nuovo flag per controllare la possibilità di iniziare dialogo

func _ready():
	npcJoanna.connect("body_entered", _on_npc_body_entered)
	npcJoanna.connect("body_exited", _on_npc_body_exited)
	npcEleonore.connect("body_entered", _on_npc_body_entered)
	npcEleonore.connect("body_exited", _on_npc_body_exited)
	# Ascolta il segnale dalla dialogue box se viene aggiunto (opzionale)
	# if dialogue_box.has_signal("dialogue_ended"):
	#     dialogue_box.connect("dialogue_ended", self, "_on_dialogue_ended")

func _on_npc_body_entered(body):
	if body.name == "protagonista":
		player_in_range = true
		can_start_dialogue = true  # Reset possibilità dialogo solo entrando nell'area
		print("Player entrato nell'area dell'NPC")

func _on_npc_body_exited(body):
	if body.name == "protagonista":
		player_in_range = false
		can_start_dialogue = true  # anche se esce, resetto questa flag per sicurezza
		print("Player uscito dall'area dell'NPC")

func _input(event):
	if player_in_range and can_start_dialogue and event.is_action_pressed("ui_accept"):
		print("Tasto di interazione premuto")
		_start_dialogue()

func _start_dialogue():
	var lines = [
		"Ciao, viaggiatore!",
		"Abbiamo bisogno di viveri e altre risorse.",
		"Ti prego, sei l'unico che può procurarcele..."
	]
	dialogue_box.show_dialogue(lines)
	can_start_dialogue = false  # Impedisco riavvio del dialogo finché non esce e rientra
