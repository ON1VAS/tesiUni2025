extends Node2D


#oggetti
@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
@onready var timer = $HUD/timer
@onready var timerlabel = $HUD/timerlabel
#variabili
var shader_material = ShaderMaterial.new()
var time_left: float
#Signal
signal timerfinito

func _ready():
	#disattiva la shader luminosa attorno al player
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta, dovrebbe almeno
	GlobalStats.is_sleeping = false
	GlobalStats.in_menu = false
	#attiva bonus oggetti
	player.apply_temp_bonus()
	#setup timer
	time_left = GlobalStats.secondi_totali
	timerlabel.text = format_time(time_left)
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_timeout)
	timer.start()


#gestione timer, gestisce il label e il timer
func _on_timer_timeout():
	time_left -= 1
	#regen vita data da regen potion
	if player.regen and player.health < player.MAX_HEALTH:
		player.health += 1
		print("vita: ", player.health)
	if time_left <= 0:
		timer.stop()
		time_left = 0
		# Eventuale azione al termine del timer
		timerlabel.text = "Tempo scaduto!"
		emit_signal("timerfinito")
	else:
		timerlabel.text = format_time(time_left)

#fornisce i secondi in minuti : secondi
func format_time(seconds:float) -> String:
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

func scene_change(Scena: String):
	#assegna ricompense prima del cambio scena
	var minuti_giocati = int(GlobalStats.secondi_totali / 60)
	if minuti_giocati > 0:
		InventoryManager.assegna_reward(1 + minuti_giocati)
	
	#animazione transizione
	GlobalStats.is_sleeping = true
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	GlobalStats.im_back = true
	
	get_tree().change_scene_to_file(Scena)

func _on_timerfinito():
	#toglie i bonus
	player.reset_temp_bonus()
	BonusManager.clear()
	scene_change("res://scene/hub_map.tscn")


func _on_protagonista_player_defeated():
	
	#toglie i bonus
	player.reset_temp_bonus()
	BonusManager.clear()
	player.hide_health_bar()
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer) 
	timer.start()
	await timer.timeout
	timer.queue_free()  # cleanup the timer
	scene_change("res://scene/hub_map.tscn")
