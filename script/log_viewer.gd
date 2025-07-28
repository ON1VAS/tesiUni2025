extends Control

@onready var log_text: RichTextLabel = $VBoxContainer/LogText
@onready var back_button: Button = $Button
@onready var scroll = $VBoxContainer/LogText/HScrollBar
var recovery_log_path = "user://recovery_log.txt"
signal annulla_log

func _ready():
	self.visible = false
	mostra_tutti_i_log()
	back_button.pressed.connect(torna_al_menu)

func mostra_tutti_i_log():
	log_text.clear()
	
	if FileAccess.file_exists(recovery_log_path):
		var file = FileAccess.open(recovery_log_path, FileAccess.READ)
		var contenuto = file.get_as_text()
		file.close()

		# Optional: miglioramento visivo con separatori
		var log_entries = contenuto.strip_edges().split("\n")
		for entry in log_entries:
			log_text.append_text(entry + "\n")
		log_text.scroll_to_line((log_text.get_line_count() - 1))

	else:
		log_text.append_text("📂 Nessun log trovato.")

func torna_al_menu():
	annulla_log.emit()
