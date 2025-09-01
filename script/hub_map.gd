extends Node2D

@onready var dialogue_box = $DialogueBox  # Riferimento al nodo DialogueBox
@onready var npcJoanna = $npc_Joanna  # Riferimento al nodo NPC
@onready var npcEleonore = $npc_eleonore  # Riferimento al nodo NPC
@onready var player = $protagonista
@onready var startGame = $Area2DstartGame
@onready var player_an_sp = $protagonista/AnimatedSprite2D
@onready var timer_selector = $CanvasLayer/TimerSelector
@onready var background_overlay = $CanvasLayer/BackgroundOverlay
@onready var tempo_rimanente = $CanvasLayer/tempo_rimanente
@onready var log_viewer = $CanvasLayer/LogViewer
@onready var inventoryUI = $CanvasLayer/InventoryUI
@onready var RewardNotifier = $CanvasLayer/RewardNotifier
var player_in_range = false
var can_start_dialogue = true  # Nuovo flag per controllare la possibilità di iniziare dialogo
var dialogues = {}
var npc_name = ""
var can_start_game = false
var shader_material = ShaderMaterial.new()
var can_rest = false
var can_read_log = false
var can_tornare_menu = false
var cooldown: float

var mela = preload("res://items/mela.tres")
var piuma = preload("res://items/piuma.tres")
var carne = preload("res://items/cosciotta_carne.tres")
var molla = preload("res://items/molla.tres")
var regen_potion = preload("res://items/regen_potion.tres")

func _ready():
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta
	#vari connect
	npcJoanna.connect("body_entered", _on_npc_body_entered.bind("npc_Joanna"))
	npcJoanna.connect("body_exited", _on_npc_body_exited.bind("npc_Joanna"))
	npcEleonore.connect("body_entered", _on_npc_body_entered.bind("npc_Eleonore"))
	npcEleonore.connect("body_exited", _on_npc_body_exited.bind("npc_Eleonore"))
	startGame.connect("body_entered", _on_start_game_area_entered)
	startGame.connect("body_exited", _on_start_game_area_exited)
	
	#carica dialoghi
	load_dialogues()
	timer_selector.visible = false
	background_overlay.visible = false
	tempo_rimanente.visible = false
	BonusManager.clear()
	InventoryManager.reset_used_items()
	player.reset_temp_bonus()
	player.hide_health_bar()
	if GlobalStats.im_back:
		tempo_rimanente.calcola_tempo()
		GlobalStats.im_back = false
	#mostra i reward nel caso ce ne siano
	mostra_reward_post_gioco()
	
	if GlobalStats.is_sleeping:
		tempo_rimanente.scale = Vector2(2, 2)
		tempo_rimanente.visible = true
		# Ancoraggio in alto a destra
		tempo_rimanente.anchor_left = 1.0
		tempo_rimanente.anchor_right = 1.0
		tempo_rimanente.anchor_top = 0.0
		tempo_rimanente.anchor_bottom = 0.0
		# Resetta i margini
		tempo_rimanente.offset_left = -tempo_rimanente.size.x - 20
		tempo_rimanente.offset_right = -300
		tempo_rimanente.offset_top = 100
		tempo_rimanente.offset_bottom = 0
		# Pivot in alto a destra (opzionale)
		tempo_rimanente.pivot_offset = Vector2(tempo_rimanente.size.x, 0)
		tempo_rimanente.back_button.visible = false




func _process(delta: float):
	#fa partire il timer di pausa
	if GlobalStats.is_sleeping:
		tempo_rimanente.calcola_tempo()
	elif GlobalStats.secondi_totali == 0:
		if can_rest and timer_selector.visible:
			background_overlay.visible = true
		else:
			background_overlay.visible = false
		tempo_rimanente.visible = false
	


func _on_npc_body_entered(body, npc):
	if body.name == "protagonista":
		npc_name = npc
		player_in_range = true
		can_start_dialogue = true  # Reset possibilità dialogo solo entrando nell'area
		dialogue_box.visible = true
		dialogue_box.show_dialogue(dialogues["Talk"])
		player_an_sp.material = shader_material


func _on_npc_body_exited(body,npc):
	if body.name == "protagonista":
		player_in_range = false
		can_start_dialogue = true  # anche se esce, resetto questa flag per sicurezza
		dialogue_box.visible = false
		npc_name = npc
		player_an_sp.material = null


#res://dialogue/dialogues.json
func load_dialogues():
	var file = FileAccess.open("res://dialogue/dialogues.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		#print("Contenuto del file JSON: ", json_text)  # Debug: visualizza il contenuto
		
		var parsed = JSON.parse_string(json_text)
		
		if parsed != null:  # Controllo se il parsing è riuscito
			dialogues = parsed
		else:
			print("Errore nel parsing del JSON. Verifica la sintassi del file.")
		
		file.close()
	else:
		print("Errore: impossibile aprire il file JSON. Percorso: res://dialogue/dialogues.json")
	


func _input(event):
		
	if can_rest and event.is_action_pressed("ui_accept") and not $CanvasLayer/TimerSelector/VBoxContainer/TextEdit.has_focus() and !GlobalStats.is_sleeping:
		timer_selector.z_index = 1000
		timer_selector.visible = true
		background_overlay.visible = true
		GlobalStats.in_menu = true
		timer_selector.scale = Vector2(1.5,1.5)
		$CanvasLayer/TimerSelector/VBoxContainer/TextEdit.clear()
		var viewport_size = get_viewport().get_visible_rect().size  # dimensione effettiva della finestra visibile
		var offset = Vector2( -290, -140 )
		timer_selector.position = (viewport_size / 2 - (timer_selector.get_size() * timer_selector.scale) / 2) + offset
	
		
	
	if can_read_log and event.is_action_pressed("ui_accept"):
		background_overlay.visible = true
		GlobalStats.in_menu = true
		log_viewer.visible = true
		log_viewer.mostra_tutti_i_log()
		var viewport_size = get_viewport().get_visible_rect().size
		var offset = Vector2( -290, -140 )
		log_viewer.position = (viewport_size / 2 - (timer_selector.get_size() * timer_selector.scale) / 2) + offset
	
	if can_tornare_menu and event.is_action_pressed("ui_accept"):
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finished
		get_tree().change_scene_to_file("res://scene/menu.tscn")
	
	if event.is_action_pressed("tab") and !GlobalStats.in_menu:
		GlobalStats.in_menu = true
		
		inventoryUI.open_inventory(player)  #Questo chiama già _refresh_list()
	
	#debug per vedere gli oggetti
	if event.is_action_pressed("give_items"):
		
		InventoryManager.add_item(mela)
		InventoryManager.add_item(piuma)
		InventoryManager.add_item(carne)
		InventoryManager.add_item(molla)
		InventoryManager.add_item(regen_potion)
		
	if can_start_dialogue and player_in_range:
		_start_dialogue()

func _start_dialogue():
	if npc_name=="npc_Eleonore": #npc_Eleonore si girano se giocatore si trova dietro di lei
		if player.position.x > npcEleonore.position.x:
			$npc_eleonore/AnimatedSprite2D.flip_h = true
		else:
			$npc_eleonore/AnimatedSprite2D.flip_h = false
	
	if npc_name=="npc_Joanna": #npc_Joanna si gira se giocatore si trova dietro di lei
		if player.position.x > npcJoanna.position.x:
			$npc_Joanna/AnimatedSprite2D.flip_h = true
		else:
			$npc_Joanna/AnimatedSprite2D.flip_h = false
	
	
	if dialogues.has(npc_name):
		dialogue_box.visible = true
		dialogue_box.show_dialogue(dialogues[npc_name])
		can_start_dialogue = false  # Impedisco riavvio del dialogo finché non esce e rientra
	else:
		print("dialogo non trovato per ", npc_name)

#cambio scena, inizio gioco
func _on_start_game_area_entered(body):
	if body.name == "protagonista":
		dialogue_box.show_dialogue(dialogues["Exit"])
		dialogue_box.visible = true
		can_start_game = true
		player_an_sp.material = shader_material


func _on_start_game_area_exited(body):
	can_start_game = false
	dialogue_box.visible = false
	player_an_sp.material = null


func scene_change(Scena: String):
	#animazione transizione
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	#cambio della scena
	get_tree().change_scene_to_file(Scena)
	


func _on_area_riposo_body_entered(body):
	if body.name == "protagonista":
		if !GlobalStats.is_sleeping:
			dialogue_box.show_dialogue(dialogues["rest"])
			dialogue_box.visible = true
			can_rest = true
			player_an_sp.material = shader_material
		else:
			dialogue_box.show_dialogue(dialogues["wait"])
			dialogue_box.visible = true


func _on_area_riposo_body_exited(body):
	if body.name == "protagonista":
		dialogue_box.visible = false
		can_rest = false
		timer_selector.visible = false
		background_overlay.visible = false
		player_an_sp.material = null


func _on_timer_selector_annulla_orario():
	timer_selector.visible = false
	background_overlay.visible = false
	dialogue_box.visible = true
	GlobalStats.in_menu = false
	dialogue_box.show_dialogue(dialogues["rest"])
	

func _on_timer_selector_conferma_iniziato():
	timer_selector.visible = false
	GlobalStats.in_menu = false
	GlobalStats.is_sleeping = false
	GlobalStats.tempo_cooldown = GlobalStats.secondi_totali * 3
	
	scene_change("res://scene/pomodoro.tscn")
	#background_overlay.visible = true
	#tempo_rimanente.visible = true
	


func _on_area_log_body_entered(body):
	if body.name == "protagonista":
		dialogue_box.show_dialogue(dialogues["log"])
		dialogue_box.visible = true
		can_read_log = true
		player_an_sp.material = shader_material


func _on_area_log_body_exited(body):
	if body.name == "protagonista":
		dialogue_box.visible = false
		can_read_log = false
		background_overlay.visible = false
		player_an_sp.material = null


func _on_log_viewer_annulla_log():
	dialogue_box.visible = false
	can_read_log = false
	log_viewer.visible = false
	GlobalStats.in_menu = false
	background_overlay.visible = false


func _on_area_torna_menu_body_entered(body):
	if body.name == "protagonista":
		dialogue_box.show_dialogue(dialogues["torna_menu"])
		dialogue_box.visible = true
		can_tornare_menu = true
		player_an_sp.material = shader_material


func _on_area_torna_menu_body_exited(body):
	if body.name == "protagonista":
		dialogue_box.visible = false
		can_tornare_menu = false
		player_an_sp.material = null


func _on_tempo_rimanente_annulla_tempo_rimanente() -> void:
	dialogue_box.visible = false
	tempo_rimanente.visible = false
	GlobalStats.in_menu = false
	background_overlay.visible = false
	GlobalStats.in_menu = false
	

func mostra_reward_post_gioco():
	for item in InventoryManager.pending_rewards:
		RewardNotifier.show_reward("     Hai ottenuto: %s" % item.name, null)
	InventoryManager.pending_rewards.clear()
