extends Node

# Percorsi file salvataggio
var save_file_path = "user://timestamp.save"   # per timestamp (tempo reale)
const SAVE_PATH := "user://save_data.json"     # per energia
var recovery_log_path := "user://recovery_log.txt" # per log di recupero energia
var secondi_totali: int = 0  # Variabile per memorizzare i secondi totali, adnrà poi scalata
var secondi_totali2: int = 0 # Variabile per memorizzare i secondi totali
const SECONDI_TOTALI_PATH := "user://secondi_totali.json"  # Percorso per il file dei secondi totali
var energia_per_secondo = 100.0 / 86400.0
var http_request: HTTPRequest
var recupero_timer: Timer
var oreRiposo: int
var minutiRiposo: int
var motivoRiposo: String
#variabile per capire se il protagonista sta dormendo
var is_sleeping = false
var in_menu = false
var can_log = false
# Energia
var energia: float = 100
# Timestamp per il reset giornaliero
var timestamp: int

func _ready():
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_request_completed)
	
	recupero_timer = Timer.new()
	add_child(recupero_timer)
	recupero_timer.timeout.connect(_on_recupero_timer_timeout)
	carica_dati()
	if secondi_totali > 0:
		is_sleeping = true
	await get_tree().process_frame  # assicura inizializzazione HTTPRequest
	
	var url = "http://worldtimeapi.org/api/ip"
	var error = http_request.request(url)
	if error != OK:
		print("❌ Errore nella chiamata HTTPRequest.request():", error)
		usa_fallback_locale()
		
	#svuota_log_recupero()
	#mostra_log_recupero()
	

# Funzioni per energia - indipendenti dal timestamp
func riduci_energia(valore: int):
	energia = max(energia - valore, 0)
	print("Energia attuale:", energia)
	salva_dati()

func aumenta_energia(valore: float):
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
		
# Carica secondi totali
	if FileAccess.file_exists(SECONDI_TOTALI_PATH):
		var file = FileAccess.open(SECONDI_TOTALI_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		if data and data.has("secondi_totali"):
			secondi_totali = data["secondi_totali"]
			print("Secondi totali caricati:", secondi_totali)
			if secondi_totali > 0:
				
				recupero_timer.start()
		else:
			print("File di salvataggio secondi totali danneggiato")
	else:
		print("File di salvataggio secondi totali non trovato")

# Salva energia su JSON
func salva_dati():
	var save_data = {"energia": energia}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Dati energia salvati")
	
	# Salva secondi totali
	var secondi_data = {"secondi_totali": secondi_totali}
	var secondi_file = FileAccess.open(SECONDI_TOTALI_PATH, FileAccess.WRITE)
	secondi_file.store_string(JSON.stringify(secondi_data))
	secondi_file.close()
	print("Dati secondi totali salvati")

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

func _on_recupero_timer_timeout():
	if secondi_totali > 0:
		can_log = false
		secondi_totali -= 1
		print(secondi_totali)
		if secondi_totali == 0:
			is_sleeping = false
			in_menu = false
			recupero_timer.stop()
			can_log = true
			_log(oreRiposo, minutiRiposo, motivoRiposo)
	aumenta_energia(energia_per_secondo * 15)
	

func simula_recupero_energia(ore: int, minuti: int, motivo: String):
	is_sleeping = true
	oreRiposo = ore
	minutiRiposo = minuti
	motivoRiposo = motivo
	recupero_timer.start()
	secondi_totali = (ore * 3600) + (minuti * 60)
	secondi_totali2 = secondi_totali
	

func _log(ore: int, minuti: int, motivo: String):
	if can_log:
		# Ora corrente come stringa
		var now = Time.get_datetime_string_from_system(true)  # es. "2025-06-18 15:30:00"
		if (secondi_totali == 0):
			var bonus = 15.0
			var energia_recuperata = secondi_totali2 * energia_per_secondo * bonus
			var energia_finale = round(energia_recuperata)
			# Messaggio da scrivere nel log
			var log_entry = "%s -> Ho riposato %d ore e %d minuti recuperando %d energia\nMotivo: %s\n" % [now, ore, minuti, energia_finale, motivo]
		
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

func mostra_log_recupero(): #fa vedere cosa c'è nel log
	if FileAccess.file_exists(recovery_log_path):
		var file = FileAccess.open(recovery_log_path, FileAccess.READ)
		var contenuto = file.get_as_text()
		file.close()
		print("📖 Contenuto del log di recupero energia:\n", contenuto)
	else:
		print("📂 Nessun log di recupero trovato.")

func svuota_log_recupero():
	if FileAccess.file_exists(recovery_log_path):
		var file = FileAccess.open(recovery_log_path, FileAccess.WRITE)
		file.store_string("")  # Scrive una stringa vuota
		file.close()
		print("🗑️ Log svuotato correttamente.")
	else:
		print("⚠️ Nessun file di log da svuotare.")
