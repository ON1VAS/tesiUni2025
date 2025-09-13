extends CharacterBody2D

@onready var sword_hitbox = $SwordHitbox/CollisionShape2D
@onready var hitbox_timer = $HitboxTimer
@onready var healthbar = $HealthBar
@onready var death_overlay: CanvasLayer = $DeathOverlay


var pending_respawn_pos: Vector2 = Vector2.INF
var is_dying: bool = false  # guardia per evitare retrigger
var killbox_death := false # per risolvere bug della killzone

const GRAVITY = 400.0
const JUMP_FORCE = -244
const MAX_HEALTH = 150.00
const ROLL_FORCE = 400
var currentMaxHealth = MAX_HEALTH
var health = MAX_HEALTH
@export var speed = 200
@export var damage = 10
var facing_direction = 1  # 1 = destra, -1 = sinistra
var is_rolling = false
var is_invincible = false
var can_jump = true
var can_roll = true
var ignore_jump_input := false
var damage_timer : SceneTreeTimer = null
#gestione salti
var max_jumps = 1
var jumps_done = 0
var extra_jump = 0
var jump_force = 0 #potenza in più di salto
var regen = false
var attack_input_delay = 0.0 #per debuff sul delay attacchi
var is_losing_health_over_time := false


signal player_defeated

# Configurazione hitbox per ogni animazione perchè se cambio gli sprite urlo, accomodiamo per i prossimi attacchi anche
var attack_properties = {
	"attack": {"delay": 0.1, "duration": 0.15, "keyframes": [1,2]},
	"attackfermo": {"delay": 0.1, "duration": 0.15, "keyframes": [1,2]},
	"attack2": {"delay": 0.15, "duration": 0.2, "keyframes": [2,3]},
	"attackfermo2": {"delay": 0.15, "duration": 0.2, "keyframes": [2,3]}
}
#servono per gestire i power up dopo
var base_stats := {
	"damage" : 10,
	"currentMaxHealth": MAX_HEALTH,
	"regen": 0,
	"temp_hp": 0,
	"jump_force": 0,
	"extra_jump": 0, #gestito l'incremento dei salti
	"killshield": 0
}


func _ready():
	$AnimatedSprite2D.play("idle")
	$HealthBar.value = health
	sword_hitbox.disabled = true #disattivato di default
	$SwordHitbox.set_collision_layer_value(2, true)  # Abilita layer 2 (player_weapon)
	$SwordHitbox.set_collision_mask_value(6, true) #abilita la maschera per colpire i nemici
	if not hitbox_timer.timeout.is_connected(_on_hitbox_timer_timeout):
		hitbox_timer.timeout.connect(_on_hitbox_timer_timeout)
	apply_temp_bonus()
	
func start_attack(anim_name: String):
	$AnimatedSprite2D.play(anim_name)
	var props = attack_properties[anim_name]
	hitbox_timer.start(props.delay) #si inizia ad attivarlo per la prima volta
	
	#non viene ancora usato, ma si potrebbe implementare
	#imposta il danno del player
	#emit_signal("hit_landed", damage) #non viene ancora usato, ma si potrebbe implementare

func _physics_process(delta):
	DebuffManager.apply_to_player(self)
	if GlobalStats.in_menu: #il giocatore non può fare nulla se sta nel menu
		$AnimatedSprite2D.play("idle")
		return
	# Movimento e gravità
	velocity.y += delta * GRAVITY
	
	if is_rolling:
		is_invincible = true
	else:
		is_invincible = false
		
	if is_rolling:
		move_and_slide()
		return
	
	# Input movimento
	var input_left = Input.is_action_pressed("ui_left") #per debuff sull'inerzia del movimento
	var input_right = Input.is_action_pressed("ui_right")
	var target_speed = 0
	var left = input_left
	var right = input_right

	if DebuffManager.is_command_inverted():
		var temp = left
		left = right
		right = temp

	if left:
		target_speed = -speed
		facing_direction = -1
	elif right:
		target_speed = speed
		facing_direction = 1

	if DebuffManager.is_sliding_active():
		# Inerzia: meno controllo
		velocity.x = lerp(velocity.x, float(target_speed), delta * 2)  # oppure 2 per più scivolamento
	else:
		# Movimento normale, reattivo
		velocity.x = target_speed

	
	if Input.is_action_pressed("ui_down"):
		position.y = position.y + 2
		
	
# SALTO MULTIPLO
	if Input.is_action_just_pressed("ui_up") and not ignore_jump_input and can_jump:
		if jumps_done < max_jumps + extra_jump:
			velocity.y = JUMP_FORCE + jump_force
			jumps_done += 1
		



	
	if Input.is_action_just_pressed("roll") and is_on_floor() and can_roll:
		is_rolling = true
		$AnimatedSprite2D.play("roll")
		velocity.x = ROLL_FORCE * facing_direction
		await $AnimatedSprite2D.animation_finished
		velocity.x = 0
	
	# Attacchi (solo se non sta già eseguendo un'animazione di attacco)
	if $AnimatedSprite2D.animation not in attack_properties.keys():
		if Input.is_action_just_pressed("attackfast"):
			await get_tree().create_timer(attack_input_delay).timeout
			start_attack("attack" if velocity.x == 0 else "attackfermo")
		elif Input.is_action_just_pressed("attackpesant"):
			await get_tree().create_timer(attack_input_delay).timeout
			start_attack("attack2" if velocity.x == 0 else "attackfermo2")
	# Animazioni normali (solo se non sta attaccando)
		elif not is_on_floor():
			$AnimatedSprite2D.play("jump" if velocity.y < 0 else "fall")
		elif velocity.x != 0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")
	
	# Flip
	$AnimatedSprite2D.flip_h = facing_direction < 0
# Modifica la posizione dell'Area2D (SwordHitbox), non della CollisionShape
	if facing_direction<0:
		$SwordHitbox.position.x = 65 * facing_direction  # 65 va esattamete dall'altra parte
		$CollisionShape2D.position.x = facing_direction + 10
		
	else:
		$SwordHitbox.position.x = 10 * facing_direction  # co 10 sta giusto davanti al cavaliere
		$CollisionShape2D.position.x = facing_direction
	move_and_slide()
	
	#reset salti
	if is_on_floor():
		jumps_done = 0

func SetHealthBar(): #imposto barretta vita
	$HealthBar.value = health
	var health_perc = 0.5 + ((health / currentMaxHealth)/2 ) #il giocatore cambia dimensione in base a quanta vita ha

func Damage (dam): #la vita diminuisce di un certo dam
	if is_invincible:
		return
	health-= dam #fa diminuire la vita in base a quanto danno prendi
	SetHealthBar() #aggiorna la healthbar in "tempo reale"
	if health <= 0: #pe capire se funziona, qua po se deve fa la roba dell acrepaggine
		die()


func die():
	if is_dying:
		return
	is_dying = true 
	health = 0  # Assicurati che la salute non vada sotto zero
	#$death_sound.play()
	$AnimatedSprite2D.play("death")
	is_invincible = true
	set_physics_process(false)  # Disabilita il movimento del personaggio
	set_process(false)  # Disabilita altri processi
	player_defeated.emit()
	if damage_timer:
		damage_timer.stop()
		damage_timer = null

func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation in attack_properties.keys():
		sword_hitbox.disabled = true #Non mi serve più tenerla attiva
		$AnimatedSprite2D.play("idle")
	elif $AnimatedSprite2D.animation == "roll":
		is_rolling = false
		$AnimatedSprite2D.play("idle")
	elif $AnimatedSprite2D.animation == "death":
		if killbox_death and pending_respawn_pos != Vector2.INF:
			global_position = pending_respawn_pos
			pending_respawn_pos = Vector2.INF
			killbox_death = false
			
			# 3) ricarica la vita (o quello che preferisci per le killbox)
			if health <= 0:
				health = max(1, int(currentMaxHealth * 0.5))  # mezza vita SOLO per killbox
			SetHealthBar()
			$AnimatedSprite2D.play("idle")
			velocity = Vector2.ZERO
			is_invincible = false
			is_rolling = false
			jumps_done = 0
			is_dying = false
		else:
			pending_respawn_pos = Vector2.INF
			killbox_death = false
		# attesa 5 secondi e cambio scena al menu, accendo il layout quando perde il giocatore
			if death_overlay and LevelFlow.current_mode != LevelFlow.Mode.SURVIVOR_MODE:
				death_overlay.show_countdown(5)
			
			DebuffManager.clear_all()
			DebuffManager.set_platform_mode(false) # spegne anche effetti runtime (vignetta ecc.)
			await get_tree().create_timer(5.0).timeout
			get_tree().change_scene_to_file("res://scene/menu.tscn")
	# pulizie comuni
		pending_respawn_pos = Vector2.INF
		killbox_death = false
		set_physics_process(true)
		set_process(true)


func _on_hitbox_timer_timeout() -> void:
	var current_anim = $AnimatedSprite2D.animation
	
	if current_anim in attack_properties:
		var props = attack_properties[current_anim]
		
		if sword_hitbox.disabled:
			# Attiva hitbox
			sword_hitbox.disabled = false
			hitbox_timer.start(props.duration)  # Durata hitbox
		else:
			# Disattiva hitbox
			sword_hitbox.disabled = true
			
			# Se ci sono più keyframe, programma la prossima attivazione
			var next_activation = props.delay * 1.5  # Regola questo valore
			hitbox_timer.start(next_activation)

func hide_health_bar():
	healthbar.visible = false

func show_health_bar():
	healthbar.visible = true


#nel caso siano valori numerici li cambia, nel caso sia booleani li rende true
func apply_temp_bonus():
	if GlobalStats.in_intermezzo:
		print("apply_temp_bonus: intermezzo attivo, non applico")
		return
	for key in BonusManager.active_bonus:
		if not base_stats.has(key):
			continue  # ignora bonus non riconosciuti

		var current_value = self.get(key)
		var bonus_value = BonusManager.active_bonus[key]

		match typeof(current_value):
			TYPE_INT, TYPE_FLOAT:
				self.set(key, current_value + bonus_value)
			TYPE_BOOL:
				self.set(key, bonus_value)
			_:
				push_warning("Tipo non gestito per bonus: %s" % key)

	# Se cambia la max health, aggiorna salute e barra
	if BonusManager.active_bonus.has("currentMaxHealth"):
		health = currentMaxHealth
		SetHealthBar()
	if BonusManager.has_method("clear"):
		BonusManager.clear()
	else:
		# fallback: svuota la mappa se non hai un metodo dedicato
		BonusManager.active_bonus.clear()



func reset_temp_bonus():
	for key in base_stats:
		self.set(key, base_stats[key])
	# Reset salute e barra se necessario
	if base_stats.has("currentMaxHealth"):
		health = currentMaxHealth
		SetHealthBar()
		

func force_kill_and_respawn_at(pos: Vector2) -> void:
	# chiamata dalla Killbox; imposta il punto e fa partire la morte
	pending_respawn_pos = pos
	Damage(health)  # o direttamente: die()
