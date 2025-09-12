extends Control

@onready var vbox = $MarginContainer/VBoxContainer
@onready var panel = $howtoplaypanel
@onready var audio_settings_panel = $UI

var _prev_focus: Control # per non perdere il focus di prima/dopo

func _ready():
	vbox.scale = Vector2(2,2)
	panel.visible = false
	audio_settings_panel.visible = false
	
	
	if vbox.get_child_count() > 0:
		var first_button = vbox.get_child(0)
		if first_button is Button:
			first_button.grab_focus()
	# Start campagna platform
#LevelFlow.start_run(LevelFlow.Mode.PLATFORM_CAMPAIGN)
#get_tree().change_scene_to_packed(LevelFlow.get_current_scene())
# Start survivor mode (se vuoi anche orchestrarla da LevelFlow)
#LevelFlow.start_run(LevelFlow.Mode.SURVIVOR_MODE)
#get_tree().change_scene_to_packed(LevelFlow.get_current_scene())

func _input(event):
	if event.is_action_pressed("esc_button"):
		_on_chiudi_pressed()
		_on_opzioni_closed_pressed()

func _on_esci_pressed() -> void:
	get_tree().quit()


func _on_howtoplay_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://scene/tutorial.tscn")


func _on_chiudi_pressed() -> void:
	panel.visible = false


func _on_opzioni_pressed() -> void:
	_prev_focus = get_viewport().gui_get_focus_owner()

	audio_settings_panel.visible = true

	# assicura che i controlli rispondano a ui_left/right e che W/S navighi
	for s in audio_settings_panel.find_children("*", "HSlider", true, false):
		s.focus_mode = Control.FOCUS_ALL
	for b in audio_settings_panel.find_children("*", "Button", true, false):
		b.focus_mode = Control.FOCUS_ALL

	await get_tree().process_frame
	$UI/Settings/Audio/HBoxContainer/VBoxContainer2/Master.grab_focus()


func _on_opzioni_closed_pressed() -> void:
	audio_settings_panel.visible = false
	if _prev_focus and is_instance_valid(_prev_focus):
		_prev_focus.grab_focus()


func _on_survivor_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished

	LevelFlow.start_run(LevelFlow.Mode.SURVIVOR_MODE)
	var first_scene: PackedScene = LevelFlow.get_current_scene()
	if first_scene:
		get_tree().change_scene_to_packed(first_scene)
	else:
		push_error("LevelFlow.survivor_mode_levels è vuoto: aggiungi le scene nell'Ispettore di LevelFlow.tscn.")



func _on_platform_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished

	# Avvia la run platform e vai al primo livello
	LevelFlow.start_run(LevelFlow.Mode.PLATFORM_CAMPAIGN)
	var first_scene: PackedScene = LevelFlow.get_current_scene()
	if first_scene:
		get_tree().change_scene_to_packed(first_scene)
	else:
		push_error("LevelFlow.platform_campaign_levels è vuoto: aggiungi le scene nell'Ispettore di LevelFlow.tscn.")
