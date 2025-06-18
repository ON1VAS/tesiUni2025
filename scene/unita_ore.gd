extends VBoxContainer

@export var values: Array[int] = [0,1,2,3,4,5,6,7,8,9]
@onready  var label: Label = $Label2
var current_index := 0
signal cambia_decine_ore
func _ready():
	update_label()
	$ore2Up.pressed.connect(_on_button_up_pressed)
	$ore2Down.pressed.connect(_on_button_down_pressed)

func _on_button_up_pressed():
	current_index = (current_index + 1) % values.size()
	if current_index >=5:
		cambia_decine_ore.emit()
	update_label()

func _on_button_down_pressed():
	current_index = (current_index -1 + values.size()) % values.size()
	if current_index >=5:
		cambia_decine_ore.emit()
	update_label()

func update_label():
	label.text = str(values[current_index])
	

func get_value() -> int:
	return values[current_index]
