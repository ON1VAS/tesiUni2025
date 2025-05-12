extends CharacterBody2D

var movement_speed = 100 
@onready var player = get_tree().get_first_node_in_group("giocatore") 
@onready var anim = $AnimatedSprite2D
@onready var hp = 20
@onready var min_distance = 300
@onready var hurtbox = $Hurtbox
@onready var sword_hitbox = $Pungiglione/CollisionShape2D
@onready var hitbox_timer = $HitboxTimer

func _ready():
	print(self.name)
	sword_hitbox.disabled = true #disattivato di default
	$Pungiglione.set_collision_layer_value(2, true)  # Abilita layer 2 (player_weapon)
	$Pungiglione.set_collision_mask_value(6, true) #abilita la maschera per colpire i nemici
	if not hitbox_timer.timeout.is_connected(_on_hitbox_timer_timeout):
		hitbox_timer.timeout.connect(_on_hitbox_timer_timeout)


# Configurazione hitbox per ogni animazione perchè se cambio gli sprite urlo, accomodiamo per i prossimi attacchi anche
var attack_properties = {
	"attack": {"delay": 0.1, "duration": 0.15, "keyframes": [1,3]},
}


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation in attack_properties.keys():
		sword_hitbox.disabled = true #Non mi serve più tenerla attiva
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
