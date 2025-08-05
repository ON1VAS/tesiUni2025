### InventoryManager.gd
extends Node

#Chiave: item name, Valore: dizionario con {item, quantity, active}
var items: Dictionary = {}

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
