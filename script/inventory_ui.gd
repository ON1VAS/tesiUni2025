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

		var max_name_length = 13
		var item_name = item.name
		var display_name := ""

		if item_name.length() > max_name_length:
			item_name = item_name.substr(0, max_name_length - 1) + "…"

		display_name = "%s x%d" % [item_name, quantity]

		item_list.add_item(display_name, icon)
		item_list.set_item_tooltip(
			item_list.item_count - 1,
			"%s x%d\n%s" % [item.name, quantity, item.description]
		)

func _on_use_pressed():
	var selected = item_list.get_selected_items()
	if selected.is_empty():
		return
	
	var index = selected[0]
	var item_name = InventoryManager.items.keys()[index]
	InventoryManager.use_item(item_name, player_ref)
	
	# 🔹 salviamo l’indice corrente
	var old_index = index
	
	_refresh_list()
	
	# 🔹 manteniamo la selezione dopo il refresh
	if item_list.item_count > 0:
		if old_index >= item_list.item_count:
			old_index = item_list.item_count - 1
		item_list.select(old_index)
		_on_item_selected(old_index)

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

func _input(event):
	if not visible:
		return
	
	var cols = item_list.max_columns
	if cols <= 0:
		cols = 1
	
	var current = item_list.get_selected_items()
	var index = current[0] if not current.is_empty() else 0
	var max_index = item_list.item_count - 1
	
	# Freccia destra
	if event.is_action_pressed("ui_right"):
		var next_index = index + 1
		if index % cols == cols - 1 or next_index > max_index:
			next_index = index - (cols - 1)
			if next_index > max_index:
				next_index = max_index
		item_list.select(next_index)
		_on_item_selected(next_index)
	
	# Freccia sinistra
	elif event.is_action_pressed("ui_left"):
		var prev_index = index - 1
		if index % cols == 0 or prev_index < 0:
			prev_index = index + (cols - 1)
			if prev_index > max_index:
				prev_index = max_index
		item_list.select(prev_index)
		_on_item_selected(prev_index)
	
	# Freccia giù
	elif event.is_action_pressed("ui_down"):
		var next_index = index + cols
		if next_index > max_index:
			next_index = index % cols
		item_list.select(next_index)
		_on_item_selected(next_index)
	
	# Freccia su
	elif event.is_action_pressed("ui_up"):
		var prev_index = index - cols
		if prev_index < 0:
			var last_row_start = max_index - (max_index % cols)
			prev_index = last_row_start + (index % cols)
			if prev_index > max_index:
				prev_index = max_index
		item_list.select(prev_index)
		_on_item_selected(prev_index)
	
	# Usa oggetto con Invio o E (ui_accept)
	elif event.is_action_pressed("ui_accept"):
		_on_use_pressed()
