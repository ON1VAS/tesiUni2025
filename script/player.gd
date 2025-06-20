extends CharacterBody2D

@onready var sword_hitbox = $SwordHitbox/CollisionShape2D
@onready var hitbox_timer = $HitboxTimer
@onready var healthbar = $HealthBar

const GRAVITY = 400.0
const JUMP_FORCE = -200
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

func _ready():
	print(self.name)
	$AnimatedSprite2D.play("idle")
	$HealthBar.value = health
	sword_hitbox.disabled = true #disattivato di default
	$SwordHitbox.set_collision_layer_value(2, true)  # Abilita layer 2 (player_weapon)
	$SwordHitbox.set_collision_mask_value(6, true) #abilita la maschera per colpire i nemici
	if not hitbox_timer.timeout.is_connected(_on_hitbox_timer_timeout):
		hitbox_timer.timeout.connect(_on_hitbox_timer_timeout)
	
func start_attack(anim_name: String):
	$AnimatedSprite2D.play(anim_name)
	var props = attack_properties[anim_name]
	hitbox_timer.start(props.delay) #si inizia ad attivarlo per la prima volta
	
	#non viene ancora usato, ma si potrebbe implementare
	#imposta il danno del player
	#emit_signal("hit_landed", damage) #non viene ancora usato, ma si potrebbe implementare

func _physics_process(delta):
	DebuffManager.apply_to_player(self)
	if GlobalStats.is_sleeping or GlobalStats.in_menu: #il giocatore non può fare nulla se sta dormendo
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
		
	
	# Salto
	if can_jump and not ignore_jump_input:
		if Input.is_action_just_pressed("ui_up") and is_on_floor():
			velocity.y = JUMP_FORCE
			print("Can jump:", can_jump, "| Ignore input:", ignore_jump_input)
	else:
	# Forza il blocco verticale
		if Input.is_action_just_pressed("ui_up"):
			print("SALTO BLOCCATO")  # Debug
			velocity.y = 0  # Se vuoi proprio bloccare anche tentativi


	
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
