extends Area2D
var health:= 50 #vita dummy

@onready var hurtbox = $CollisionShape2D
@onready var player: Node2D = get_tree().get_first_node_in_group("giocatore") as Node2D

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
		take_damage(player.damage)  # Danno base (puoi passare un valore dal player)

func take_damage(amount: int):
	#health -= amount #reso immortale
	show_damage_text(amount)
	if health <= 0:
		queue_free()


func show_damage_text(amount: int):
	var label := Label.new()
	label.text = "%d danni" % amount
	label.modulate = Color.RED
	label.add_theme_font_size_override("font_size", 16)
	get_tree().current_scene.add_child(label)
	
	# posizione sopra la testa
	label.global_position = global_position + Vector2(0, -40)

	# piccolo effetto di salita + dissolvenza
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(Callable(label, "queue_free"))
