extends Control

@onready var vbox = $MarginContainer/VBoxContainer
@onready var panel = $howtoplaypanel
@onready var audio_settings_panel = $UI
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
	panel.visible = true


func _on_chiudi_pressed() -> void:
	panel.visible = false


func _on_opzioni_pressed() -> void:
	audio_settings_panel.visible = true


func _on_opzioni_closed_pressed() -> void:
	audio_settings_panel.visible = false


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
