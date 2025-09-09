extends VBoxContainer

var minuti := 0
@onready  var label: Label = $minutiSelezionati
func _ready():
	update_label()
	$up.pressed.connect(_on_button_up_pressed)
	$down.pressed.connect(_on_button_down_pressed)
	
func _on_button_up_pressed():
	if (minuti < 15):
		minuti+=1
		update_label()
	else:
		minuti = 1
		update_label()
	

func _on_button_down_pressed():
	if (minuti >= 1):
		minuti-=1
		update_label()
	else:
		minuti = 15
		update_label()

func update_label():
	label.text = str(minuti)

func get_value():
	return minuti
