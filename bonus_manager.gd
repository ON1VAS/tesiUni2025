extends Node

#var base_stats := {
	#"damage" : 10,
	#"currentMaxHealth": MAX_HEALTH,
	#"regen": false,
	#"temp_hp": false,
	#"jump_force": JUMP_FORCE,
	#"extra_jump": 0,
	#"killshield": false
#}

var active_bonus := {}

func add_bonus(key: String, value):
	# Se il bonus esiste già, somma o aggiorna in base al tipo
	if active_bonus.has(key):
		var current_value = active_bonus[key]
		if typeof(current_value) in [TYPE_INT, TYPE_FLOAT] and typeof(value) in [TYPE_INT, TYPE_FLOAT]:
			active_bonus[key] = current_value + value
		else:
			# Per booleani o altri tipi, sovrascrivi direttamente
			active_bonus[key] = value
	else:
		active_bonus[key] = value

func clear():
	active_bonus.clear()
