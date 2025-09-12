extends Node2D
@onready var sfondo = $Sprite2D
@onready var player = $protagonista
@onready var menu = $CanvasLayer/Control/VBoxContainer

func _process(delta):
	# Mantieni solo la coordinata X del player
	sfondo.position.x = player.position.x

func _ready():
	DebuffManager.set_platform_mode(true)
	DebuffManager.apply_to_player($protagonista)
	# Connetti ogni CheckBox del menu
	for child in menu.get_children():
		if child is CheckBox:
			child.toggled.connect(_on_checkbox_toggled.bind(child.text))

	# Aggiorna lo stato iniziale (se alcuni debuff erano già attivi)
	_update_checkboxes()

func _on_checkbox_toggled(pressed: bool, debuff_name: String) -> void:
	if pressed:
		DebuffManager.add_debuff(debuff_name)
	else:
		DebuffManager.remove_debuff(debuff_name)
	DebuffManager.apply_to_player(player)

func _update_checkboxes() -> void:
	var active = DebuffManager.get_active_debuffs()
	for child in menu.get_children():
		if child is CheckBox:
			child.button_pressed = active.has(child.text)


func _on_button_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://scene/menu.tscn")
