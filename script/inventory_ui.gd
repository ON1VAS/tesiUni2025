### InventoryUI.gd
extends Control

@onready var item_list = $PanelContainer/VBoxContainer/ItemList
@onready var use_button = $PanelContainer/VBoxContainer/HBoxContainer/useButton
@onready var close_button = $PanelContainer/VBoxContainer/HBoxContainer/closeButton

var player_ref: Node = null

func _ready():
	use_button.pressed.connect(_on_use_pressed)
	close_button.pressed.connect(_on_close_pressed)
	item_list.item_selected.connect(_on_item_selected)


func open_inventory(player):
	player_ref = player
	if not visible:
		_refresh_list()
		visible = true

func _refresh_list():
	item_list.clear()
	for entry in InventoryManager.items.values():
		var item = entry["item"]
		var quantity = entry["quantity"]
		var icon = item.icon

		var max_name_length = 13  # oppure 18, dipende dalla tua UI
		var item_name = item.name
		var display_name := ""

		if item_name.length() > max_name_length:
			item_name = item_name.substr(0, max_name_length - 1) + "…"

		display_name = "%s x%d" % [item_name, quantity]

		item_list.add_item(display_name, icon)
		item_list.set_item_tooltip(item_list.item_count - 1, "%s x%d\n%s" % [item.name, quantity, item.description])




func _on_use_pressed():
	var selected = item_list.get_selected_items()
	if selected.is_empty():
		return
	var index = selected[0]
	var item_name = InventoryManager.items.keys()[index]
	InventoryManager.use_item(item_name, player_ref)
	_refresh_list()

func _on_close_pressed():
	visible = false
	GlobalStats.in_menu = false
	$PanelContainer/VBoxContainer/descriptionLabel.text = ""

func _on_item_selected(index: int):
	if index >= 0 and index < InventoryManager.items.size():
		var item_name = InventoryManager.items.keys()[index]
		var item = InventoryManager.items[item_name]["item"]
		$PanelContainer/VBoxContainer/descriptionLabel.text = item.description
	else:
		$PanelContainer/VBoxContainer/descriptionLabel.text = ""
