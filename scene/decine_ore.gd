extends VBoxContainer

@export var values: Array[int] = [0,1,2]
@onready  var label: Label = $Label1

var current_index := 0

func _ready():
	update_label()
	$oreUp.pressed.connect(_on_button_up_pressed)
	$oreDown.pressed.connect(_on_button_down_pressed)

func _on_button_up_pressed():
	var next_index = (current_index + 1) % values.size()
	var unit_node = get_parent().get_node("unitaOre")
	var unit_val = unit_node.get_value()
	# Se la prossima decina è 2 e unità > 4, salta 2
	if next_index == 2 and unit_val > 4:
		next_index = 0  # torna a 0 o a 1 a seconda della logica, qui faccio a 0 per esempio
	current_index = next_index
	update_label()

func _on_button_down_pressed():
	var prev_index = (current_index - 1 + values.size()) % values.size()
	var unit_node = get_parent().get_node("unitaOre")
	var unit_val = unit_node.get_value()
	# Se la precedente decina è 2 e unità > 4, salta 2
	if prev_index == 2 and unit_val > 4:
		prev_index = 1  # vai a 1 se 2 è disabilitato, oppure a 0 basato sulla logica
	current_index = prev_index
	update_label()

func update_label():
	label.text = str(values[current_index])
	

func get_value() -> int:
	return values[current_index]

func reset_decine():
	current_index = 0  # Riporta a 0
	update_label()

func _on_unita_ore_cambia_decine_ore():
	var unitaOre = get_parent().get_node("unitaOre")
	if current_index == 2 and unitaOre.get_value() >= 5:
		reset_decine()
	elif current_index ==2:
		current_index = 1  # Se non è > 5, torna a 1
		update_label()
