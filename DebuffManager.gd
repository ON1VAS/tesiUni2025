extends Node

# Parametri configurabili
const ENERGY_THRESHOLDS = {
	"buffplus": 100,
	"blocco1": 80,
	"blocco2": 40,
	"blocco3": 30,
	"blocco4": 20,
	"blocco5": 10,
}
# Variabile per tenere traccia dello stato del debuff
var debuff_active = false

func apply_to_player(player):
	# Reset valori
	var energia = GlobalStats.energia
	player.speed = 200
	player.can_roll = true
	player.can_jump = true
	player.ignore_jump_input = false
	player.attack_input_delay = 0.0
	if energia < ENERGY_THRESHOLDS["buffplus"]:
		player.damage = 25 
	
	# Debuff 1: rallenta
	if energia < ENERGY_THRESHOLDS["blocco1"]:
		player.speed = 150
		player.damage = 10
	
	if energia < ENERGY_THRESHOLDS["blocco2"]:
		player.speed = 100
		player.attack_input_delay = 0.5 #mezzo secondo di delay negli attacchi
		player.can_roll = false #rimosso il roll
		
	
	# Debuff 3: disabilita salto
	if energia < ENERGY_THRESHOLDS["blocco3"]:
		  # velocità diminuita, tolto salto
		player.speed = 50
		player.can_jump = false
		player.ignore_jump_input = true
	
	if energia > 0 and energia < ENERGY_THRESHOLDS["blocco5"]: #perdita di 1 hp ogni 10 secondi
		if player.health > 1:
			await get_tree().create_timer(10.0).timeoutTimer
			player.health -= 1

func enemy_damage_multiplier():
	var energia = GlobalStats.energia
	if energia < ENERGY_THRESHOLDS["blocco4"]:
		return 1.5
	return 1.0

func is_vignette_active() -> bool: #vignetta per oscurare parte del campo visivo
	return GlobalStats.energia <= ENERGY_THRESHOLDS["blocco3"]
	
func is_sliding_active() -> bool: 
	return GlobalStats.energia < ENERGY_THRESHOLDS["buffplus"]
	
