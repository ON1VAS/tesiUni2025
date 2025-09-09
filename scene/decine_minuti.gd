#decineMinuti.gd
extends VBoxContainer

@export var values: Array[int] = [0,1]
@onready  var label: Label = $Label3

var current_index := 0
signal decina_changed(value: int)

func _ready():
	update_label()
	$minuti1Up.pressed.connect(_on_button_up_pressed)
	$minuti1Down.pressed.connect(_on_button_down_pressed)
	decina_changed.emit(get_value())  #invia valore iniziale

func _on_button_up_pressed():
	current_index = (current_index + 1) % values.size()
	update_label()
	decina_changed.emit(get_value())  #notifica il cambio della decina

func _on_button_down_pressed():
	current_index = (current_index - 1 + values.size()) % values.size()
	update_label()
	decina_changed.emit(get_value()) #notifica il cambio della decina

func update_label():
	label.text = str(values[current_index])
	

func get_value() -> int:
	return values[current_index]
