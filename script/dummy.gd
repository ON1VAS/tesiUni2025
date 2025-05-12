extends Area2D
var health:= 50 #vita dummy

@onready var hurtbox = $CollisionShape2D

func _ready():
	$CollisionShape2D.disabled = false
	self.set_collision_layer_value(6, true)  # Abilita layer 6 (enemy_hurt)
	self.set_collision_mask_value(2, true)  # Deve rilevare layer 2 (player_weapon)
	area_entered.connect(_on_hurtbox_area_entered)
	$spriteDummy.play("idle")
func _on_hurtbox_area_entered(area: Area2D):
	# Se l'area è la SwordHitbox del giocatore
	if area.is_in_group("player_weapon"):
		$spriteDummy.play("hit")
		take_damage(10)  # Danno base (puoi passare un valore dal player)

func take_damage(amount: int):
	#health -= amount #reso immortale
	
	if health <= 0:
		queue_free()
