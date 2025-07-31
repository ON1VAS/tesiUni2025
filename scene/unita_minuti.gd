extends VBoxContainer

@export var values: Array[int] = [0,1,2,3,4,5,6,7,8,9]
@onready  var label: Label = $Label4

var current_index := 0

func _ready():
	update_label()
	$minuti2Up.pressed.connect(_on_button_up_pressed)
	$minuti2Down.pressed.connect(_on_button_down_pressed)

func _on_button_up_pressed():
	current_index = (current_index + 1) % values.size()
	update_label()

func _on_button_down_pressed():
	current_index = (current_index -1 + values.size()) % values.size()
	update_label()

func update_label():
	label.text = str(values[current_index])
	

func get_value() -> int:
	return values[current_index]

func set_max_value_from_decina(decina: int):
	if decina == 1:
		values = [0, 1, 2, 3, 4, 5]  # max 15
	else:
		values = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

	# Se l'indice attuale è fuori dal nuovo range, rimettilo a 0
	if current_index >= values.size():
		current_index = 0
	update_label()
