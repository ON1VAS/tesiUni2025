extends Node

#Dizionario con chiave = nome oggetto, valore = { item, quantity, active }
var items: Dictionary = {}

#Lista di tutte le risorse BonusItem disponibili (modifica i path con i tuoi reali)
var all_bonus_items := [
	preload("res://items/cosciotta_carne.tres"),
	preload("res://items/mela.tres"),
	preload("res://items/piuma.tres"),
	preload("res://items/regen_potion.tres"),
	preload("res://items/molla.tres")
	#aggiungi qui tutte le risorse .tres che vuoi possano essere ricompense della pool
]

var inventario = []  #Lista di dizionari, es. [{ "id": "pozion", "quantita": 3 }, ...]

var pending_rewards := []

const INVENTARIO_PATH = "user://inventario.json"

func _ready() -> void:
	carica_inventario()

func get_item_by_name(name: String) -> BonusItem:
	for item in all_bonus_items:
		if item.name == name:
			return item
	return null

func salva_inventario():
	var to_save = []
	for key in items.keys():
		var entry = items[key]
		to_save.append({"id": key, "quantita": entry["quantity"]})
	var file = FileAccess.open(INVENTARIO_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(to_save))
	file.close()
	print("Inventario salvato:", to_save)

func carica_inventario():
	if FileAccess.file_exists(INVENTARIO_PATH):
		var file = FileAccess.open(INVENTARIO_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		if data and typeof(data) == TYPE_ARRAY:
			inventario = data
			items.clear()
			for entry in inventario:
				var item_name = entry["id"]
				var quantity = entry["quantita"]
				var item_instance = get_item_by_name(item_name)
				if item_instance != null:
					items[item_name] = {
						"item": item_instance,
						"quantity": quantity,
						"active": false
					}
			print("Inventario caricato:", items)
		else:
			print("File inventario danneggiato o formato errato")
	else:
		inventario = []
		items.clear()
		print("File inventario non trovato, inventario vuoto")

func add_item(item: BonusItem):
	if not items.has(item.name):
		items[item.name] = {
			"item": item,
			"quantity": 1,
			"active": false
		}
	else:
		items[item.name]["quantity"] += 1
	salva_inventario()
	print("Item aggiunto:", item.name, "x", items[item.name]["quantity"])

func use_item(item_name: String, player: Node):
	if not items.has(item_name):
		return

	var entry = items[item_name]
	var item = entry["item"]

	if not entry["active"]:
		BonusManager.add_bonus(item.bonus_key, item.bonus_value)
		player.apply_temp_bonus()
		entry["quantity"] -= 1
		entry["active"] = true

		if entry["quantity"] <= 0:
			items.erase(item_name)
	salva_inventario()

#assegna i reward
func assegna_reward(minuti: int):
	print("Assegnazione reward per", minuti, "minuti")
	for i in range(minuti):
		if all_bonus_items.size() == 0:
			print("Nessun oggetto disponibile nella pool")
			break

		var item = all_bonus_items.pick_random()
		add_item(item)
		print("Ricompensa ottenuta:", item.name)
		InventoryManager.pending_rewards.append(item)

func reset_used_items():
	for key in items.keys():
		var entry = items[key]
		entry["active"] = false
	salva_inventario()
	print("Oggetti usati resettati")
