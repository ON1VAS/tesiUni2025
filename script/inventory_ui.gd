extends Control


@onready var item_list = $PanelContainer/VBoxContainer/ItemList
@onready var use_button = $PanelContainer/VBoxContainer/HBoxContainer/useButton
@onready var close_button = $PanelContainer/VBoxContainer/HBoxContainer/closeButton

var player_ref: Node = null

func _ready():
	use_button.pressed.connect(_on_use_pressed)
	close_button.pressed.connect(_on_close_pressed)

func open_inventory(player):
	player_ref = player
	if not visible:
		_refresh_list()
		visible = true


func _refresh_list():
	item_list.clear()
	var fallback_icon := preload("res://Godot_icon.png")  # Icona di test, assicurati esista

	for item in InventoryManager.items:
		var icon_to_use = item.icon if item.icon != null else fallback_icon
		item_list.add_item(item.name, icon_to_use)



func _on_use_pressed():
	var selected = item_list.get_selected_items()
	if selected.is_empty():
		return
	var index = selected[0]
	InventoryManager.use_item(index, player_ref)
	_refresh_list()

func _on_close_pressed():
	visible = false
	GlobalStats.in_menu = false
