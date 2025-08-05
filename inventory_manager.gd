### InventoryManager.gd
extends Node

#gestione salvataggio
const INVENTORY_SAVE_PATH := "user://inventory.json"

#Chiave: item name, Valore: dizionario con {item, quantity, active}
var items: Dictionary = {}

func _ready():
	load_inventory()

func add_item(item: BonusItem):
	if not items.has(item.name):
		items[item.name] = {
			"item": item,
			"quantity": 1,
			"active": false
		}
	else:
		items[item.name]["quantity"] += 1
	print("Item aggiunto:", item.name, "x", items[item.name]["quantity"])
	save_inventory()

func use_item(item_name: String, player: Node):
	if not items.has(item_name):
		return

	var entry = items[item_name]
	var item = entry["item"]

	# Se non è già attivo, attiva il bonus e decrementa
	if not entry["active"]:
		BonusManager.add_bonus(item.bonus_key, item.bonus_value)
		player.apply_temp_bonus()
		entry["quantity"] -= 1
		entry["active"] = true

		# Se finiti, rimuovi dall'inventario
		if entry["quantity"] <= 0:
			items.erase(item_name)
	
	if not BonusManager.active_bonus.has(item.bonus_key):
		BonusManager.add_bonus(item.bonus_key, item.bonus_value)
		player.apply_temp_bonus()
		items[item_name][1] -= 1
		if items[item_name][1] <= 0:
			items.erase(item_name)
	save_inventory()

func save_inventory():
	var data = {}

	for name in items.keys():
		var entry = items[name]
		data[name] = {
			"quantity": entry["quantity"],
			"active": entry["active"],
			"bonus_key": entry["item"].bonus_key,
			"bonus_value": entry["item"].bonus_value
		}

	var file = FileAccess.open(INVENTORY_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("💾 Inventario salvato")

func load_inventory():
	if not FileAccess.file_exists(INVENTORY_SAVE_PATH):
		print("📂 Nessun file inventario trovato.")
		return

	var file = FileAccess.open(INVENTORY_SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if data == null:
		print("Errore nel parsing del file inventario.")
		return

	items.clear()

	for name in data.keys():
		var info = data[name]
		var item = BonusItem.new()
		item.name = name
		item.bonus_key = info["bonus_key"]
		item.bonus_value = info["bonus_value"]

		items[name] = {
			"item": item,
			"quantity": info["quantity"],
			"active": info["active"]
		}

	print("📦 Inventario caricato:", items.keys())
