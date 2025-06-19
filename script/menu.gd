extends Control

@onready var vbox = $MarginContainer/VBoxContainer

func _ready():
	vbox.scale = Vector2(2,2)


func _on_gioca_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	#cambio scena
	get_tree().change_scene_to_file("res://scene/hub_map.tscn")


func _on_esci_pressed() -> void:
	get_tree().quit()
