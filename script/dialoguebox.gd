extends CanvasLayer
@onready var dialogue_label = $PanelContainer/DialogueLabel
@onready var panel_container = $PanelContainer

var dialogue_lines: Array = []
var current_line = 0
var is_active = false

func _ready():
	# cambia colore testo
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	
	
# Funzione per avviare il dialogo
func show_dialogue(lines: Array):
	dialogue_lines = lines
	current_line = 0
	is_active = true
	self.visible = true
	_show_next_line()  # Mostra subito la prima riga


# Mostra la prossima riga del dialogo
func _show_next_line():
	if current_line < dialogue_lines.size():
		print("Mostrando riga: ", current_line)  # Debug: per vedere quale riga viene visualizzata
		
		
		dialogue_label.text = dialogue_lines[current_line]  # Mostra la riga corrente
		current_line += 1  # Aumenta il contatore dopo aver mostrato il testo
	else:
		_end_dialogue()  # Se non ci sono più righe, termina il dialogo

# Termina il dialogo
func _end_dialogue():
	self.visible = false
	is_active = false
	dialogue_lines = [] #resetto array
	current_line = 0

# Gestisce l'input dell'utente (tasto di avanzamento)
func _input(event):
	if is_active and event.is_action_pressed("ui_accept"):
		_show_next_line()  # Mostra la prossima riga solo quando il tasto viene premuto

func talk_prompt(text):
	dialogue_label.text = text
