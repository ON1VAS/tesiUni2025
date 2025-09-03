extends Area2D

@export var damage_amount := 9999
@onready var marker: Node2D = $Marker2D
var _cooldown := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("giocatore"): return
	if "is_dying" in body and body.is_dying: return
	if marker == null: return

	# marca come morte-da-killbox e imposta il respawn
	if "killbox_death" in body:
		body.killbox_death = true
	if "pending_respawn_pos" in body:
		body.pending_respawn_pos = marker.global_position

	# infliggi il danno "letale"
	if body.has_method("Damage"):
		body.Damage(damage_amount)
	elif body.has_method("die"):
		body.die()

	# mini cooldown contro doppi eventi
	_cooldown = true
	await get_tree().create_timer(0.2).timeout
	_cooldown = false
