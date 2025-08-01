extends Node2D


#oggetti
@onready var player = $protagonista
@onready var player_an_sp = $protagonista/AnimatedSprite2D
@onready var timer = $HUD/timer
@onready var timerlabel = $HUD/timerlabel
@onready var dialogue_box = $DialogueBox #per le interazioni e i dialoghi
#variabili
var shader_material = ShaderMaterial.new()
var time_left: float
var dialogues = {}
#Signal
signal timerfinito

func _ready():
	#disattiva la shader luminosa attorno al player
	var shader = preload("res://scene/player.gdshader")
	shader_material.shader = shader
	player_an_sp.material = null #di default è spenta, dovrebbe almeno
	GlobalStats.is_sleeping = false
	#setup timer
	time_left = GlobalStats.secondi_totali
	timerlabel.text = format_time(time_left)
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_timeout)
	timer.start()


#gestione timer, gestisce il label e il timer
func _on_timer_timeout():
	time_left -= 1
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
	#animazione transizione
	GlobalStats.is_sleeping = true
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	GlobalStats.im_back = true
	#cambio della scena
	get_tree().change_scene_to_file(Scena)

func _on_timerfinito():
	scene_change("res://scene/hub_map.tscn")


func _on_protagonista_player_defeated():
	#dialogue_box.visible = true
	#dialogue_box.show_dialogue(dialogues["defeated"])
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer) 
	timer.start()
	await timer.timeout
	#dialogue_box.visible = false
	timer.queue_free()  # cleanup the timer
	scene_change("res://scene/hub_map.tscn")
