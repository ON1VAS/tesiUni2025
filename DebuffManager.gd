extends Node

# Parametri configurabili
const ENERGY_THRESHOLDS = {
	"test": 100,
	"blocco1": 70,
	"blocco2": 40,
	"blocco3": 30,
	"blocco4": 20,
}
# Variabile per tenere traccia dello stato del debuff
var debuff_active = false

func apply_to_player(player):
	var energia = GlobalStats.energia
	
	# Reset valori
	player.speed = 200
	player.can_roll = true
	player.can_jump = true
	
	# Debuff 1: rallenta
	if energia < ENERGY_THRESHOLDS["blocco1"]:
		player.speed = 150
	
	if energia < ENERGY_THRESHOLDS["blocco2"]:
		player.can_roll = false
	
	# Debuff 3: disabilita salto
	if energia < ENERGY_THRESHOLDS["blocco3"]:
		player.can_jump = false  # aggiungi una variabile nel player
		player.speed = 50
	else:
		player.can_jump = true

func enemy_damage_multiplier():
	var energia = GlobalStats.energia
	if energia < ENERGY_THRESHOLDS["blocco4"]:
		return 1.5
	return 1.0

func is_vignette_active() -> bool:
	return GlobalStats.energia <= ENERGY_THRESHOLDS["blocco3"]
	
