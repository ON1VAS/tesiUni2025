extends Node

# Percorsi file salvataggio
var save_file_path = "user://timestamp.save"   # per timestamp (tempo reale)
const SAVE_PATH := "user://save_data.json"     # per energia
var recovery_log_path := "user://recovery_log.txt" # per log di recupero energia

var http_request: HTTPRequest

#variabile per capire se il protagonista sta dormendo
var is_sleeping = false
# Energia
var energia: float = 100

# Timestamp per il reset giornaliero
var timestamp: int

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_request_completed)

	carica_dati()

	await get_tree().process_frame  # assicura inizializzazione HTTPRequest

	var url = "http://worldtimeapi.org/api/ip"
	var error = http_request.request(url)
	if error != OK:
		print("❌ Errore nella chiamata HTTPRequest.request():", error)
		usa_fallback_locale()

# Funzioni per energia - indipendenti dal timestamp
func riduci_energia(valore: int):
	energia = max(energia - valore, 0)
	print("Energia attuale:", energia)
	salva_dati()

func aumenta_energia(valore: int):
	energia = min(energia + valore, 100)
	print("Energia attuale:", energia)
	salva_dati()

# Carica energia da file JSON
func carica_dati():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var data = JSON.parse_string(content)
		if data and data.has("energia"):
			energia = data["energia"]
			print("Energia caricata:", energia)
		else:
			print("File di salvataggio energia danneggiato")
	else:
		print("File di salvataggio energia non trovato")

# Salva energia su JSON
func salva_dati():
	var save_data = {"energia": energia}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Dati energia salvati")

# Callback richiesta HTTP completata
func _on_http_request_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var time_unix = json["unixtime"]
		print("🌐 Orario reale:", time_unix)
		procedi_con_timestamp(time_unix)
	else:
		print("❌ Errore nella risposta HTTP:", response_code)
		usa_fallback_locale()

# Fallback al tempo locale
func usa_fallback_locale():
	var time_unix = Time.get_unix_time_from_system()
	print("🕒 Fallback locale:", time_unix)
	procedi_con_timestamp(time_unix)

# Gestione timestamp per reset
func procedi_con_timestamp(current_time: int):
	if not FileAccess.file_exists(save_file_path):
		timestamp = current_time
		var file = FileAccess.open(save_file_path, FileAccess.WRITE)
		file.store_64(timestamp)
		file.close()
	else:
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		timestamp = file.get_64()
		file.close()

	controlla_reset(current_time)

# Controllo e reset energia dopo 24h reali
func controlla_reset(current_time: int):
	var elapsed = current_time - timestamp
	if elapsed >= 86400:
		print("✅ È passato un giorno! Reset energia.")
		energia = 100
		salva_dati()

		timestamp = current_time
		var file = FileAccess.open(save_file_path, FileAccess.WRITE)
		file.store_64(timestamp)
		file.close()
	else:
		var ore_mancanti = (86400 - elapsed) / 3600.0
		print("⏳ Manca ancora %.2f ore per il prossimo reset." % ore_mancanti)

func simula_recupero_energia(ore: int, minuti: int):
	var secondi_totali = (ore * 3600) + (minuti * 60)
	var energia_per_secondo = 100.0 / 86400.0
	var bonus = 1.0
	#if is_sleeping:
	#	bonus = 1.5  # bonus se si dorme || ci pensiamo in un secondo momento

	var energia_recuperata = secondi_totali * energia_per_secondo * bonus
	var energia_finale = round(energia_recuperata)

	aumenta_energia(energia_finale)

	# Ora corrente come stringa
	var now = Time.get_datetime_string_from_system(true)  # es. "2025-06-18 15:30:00"

	# Messaggio da scrivere nel log
	var log_entry = "%s -> Ho riposato %d ore e %d minuti recuperando %d energia\n" % [now, ore, minuti, energia_finale]

	# Scrittura su file in modalità append
	var file: FileAccess
	if FileAccess.file_exists(recovery_log_path):
		file = FileAccess.open(recovery_log_path, FileAccess.READ_WRITE)
		file.seek_end()
	else:
		file = FileAccess.open(recovery_log_path, FileAccess.WRITE)

	file.store_string(log_entry)
	file.close()

	print("📘 Log aggiornato:", log_entry.strip_edges())
