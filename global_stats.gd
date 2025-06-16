extends Node

#energia
var energia: int = 100
const SAVE_PATH := "user://save_data.json"

func _ready():
	carica_dati()
	

func riduci_energia(valore: int):
	energia= max(energia - valore, 0)
	print("Energia attuale: ", energia)
	salva_dati()
	
func aumenta_energia(valore: int):
	energia= min(energia + valore, 100)
	print("Energia attuale: ", energia)
	salva_dati()

func carica_dati():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(content)
		if data and data.has("energia"):
			energia = data["energia"]
			print("energia caricata: ", energia)
		else:
			print("file di salvataggio danneggiato")
	else:
		print("file di salvataggio non trovato")


func salva_dati():
	var save_data = {"energia": energia}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("dati salvati")
