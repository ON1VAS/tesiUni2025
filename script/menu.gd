extends Control

@onready var vbox = $MarginContainer/VBoxContainer
@onready var panel = $howtoplaypanel
@onready var audio_settings_panel = $UI
func _ready():
	vbox.scale = Vector2(2,2)
	panel.visible = false
	audio_settings_panel.visible = false

func _on_gioca_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	#cambio scena
	get_tree().change_scene_to_file("res://scene/hub_map.tscn")


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
