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

var command_inverted := false #debuff per inversione comandi
var command_timer := 0.0
var invert_interval := 2.0 # cambia ogni 5 secondi

func apply_to_player(player):
	# Reset valori
	var energia = GlobalStats.energia
	player.speed = 200
	player.can_roll = true
	player.can_jump = true
	player.ignore_jump_input = false
	player.attack_input_delay = 0.0
	
	if energia < ENERGY_THRESHOLDS["buffplus"]: #se l'energia è 100, avremo un bonus all'attacco
		player.damage = 25
	
	# Debuff 1: rallenta e diminuisce il danno, questo in realtà sarebbe la "normalità"
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
		if get_tree().current_scene.name != "game":
			return
		command_timer += get_process_delta_time() #timer per invertire i comandi
		if command_timer >= invert_interval:
			command_timer = 0
			command_inverted = randi() % 2 == 0  # true o false casuale, ha il 50% di possibilità di invertire i comandi di moviemnto
		if is_instance_valid(player) and player.health > 1 and not player.has_meta("losing_health"):
			player.set_meta("losing_health", true)
			var local_player_ref = player
			var timer := get_tree().create_timer(10.0)
			await timer.timeout
			
			if get_tree().current_scene.name != "game":
				return

	# Ricontrolla dopo il timeout se il player è ancora valido
			if is_instance_valid(local_player_ref):
				print("🩸 Timer scaduto, player valido: procedo a togliere vita")
				local_player_ref.health -= 1
				print("🔥 Vita attuale del player dopo il danno:", local_player_ref.health)
				local_player_ref.SetHealthBar()
				if local_player_ref.health < 1:
					local_player_ref.die()
			if is_instance_valid(player):
				player.set_meta("losing_health", false)
				print("♻️ Flag 'losing_health' rimesso a false")


func enemy_damage_multiplier(): #moltiplicatore del danno dei nemici
	var energia = GlobalStats.energia
	if energia < ENERGY_THRESHOLDS["blocco4"]:
		return 1.5
	return 1.0
func is_sliding_active() -> bool: #diminuisce la responsività del movimento aggiungendo un rallentamento nel iniziare e finire movimento, come se scivolasse
	return GlobalStats.energia < ENERGY_THRESHOLDS["blocco4"]

func is_vignette_active() -> bool: #vignetta per oscurare parte del campo visivo
	return GlobalStats.energia <= ENERGY_THRESHOLDS["blocco3"]

func is_command_inverted() -> bool: #randomicamente inverte i comandi
	return command_inverted
