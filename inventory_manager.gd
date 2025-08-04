extends Node

var items: Array[BonusItem] = []

func add_item(item: BonusItem):
	if not items.has(item):
		items.append(item)

func use_item(index: int, player: Node):
	if index >= 0 and index < items.size():
		var item = items[index]
		# Applica solo se non già attivo
		if not BonusManager.active_bonus.has(item.bonus_key):
			BonusManager.add_bonus(item.bonus_key, item.bonus_value)
			player.apply_temp_bonus()
			items.remove_at(index)
