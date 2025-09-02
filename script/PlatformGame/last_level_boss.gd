extends Node2D

@onready var boss: Node = $Boss
@onready var boss_trigger : Area2D = $BossTrigger
@onready var finale_trigger : Area2D = $finale   # 👈 il tuo trigger finale
@onready var player = $protagonista
@onready var camera: Camera2D = $protagonista/Camera2D
@onready var hud := $BossHUD
@onready var sprite2D4 = $Sprite2D4
@onready var sprite2D5 = $Sprite2D5
@onready var canc_tilemap = $TileMapLayer4
@onready var canc_hitbox = $hitboxes/CollisionShape2D12
@onready var final_message: Label = $CanvasLayer/FinalMessage  # 👈 il label del messaggio
@onready var timer: Timer = $FinalTimer  # 👈 un Timer in scena (one_shot = true, wait_time = 20)

func _process(delta):
	# Mantieni solo la coordinata X del player
	sprite2D4.position.x = player.position.x
	sprite2D5.position.x = player.position.x
	
func _ready() -> void:
	DebuffManager.set_platform_mode(true)
	DebuffManager.apply_to_player($protagonista)
	boss_trigger.body_entered.connect(_on_boss_trigger_body_entered)
	hud.visible = false
	
	if boss.has_signal("died"):
		boss.died.connect(_on_boss_died)

	# collega il trigger finale
	finale_trigger.body_entered.connect(_on_finale_trigger_body_entered)

	# nascondi il messaggio inizialmente
	final_message.visible = false


func _on_boss_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		if boss.has_method("activate"):
			boss.activate()
		else:
			boss.active = true
		boss_trigger.queue_free()
		hud.setup(boss, player, camera)

func _on_boss_died() -> void:
	if is_instance_valid(canc_tilemap):
		canc_tilemap.visible = false
		canc_tilemap.set_deferred("collision_enabled", false)

	if is_instance_valid(canc_hitbox):
		canc_hitbox.set_deferred("disabled", true)

func _on_finale_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		final_message.text = "Complimenti! Hai sconfitto il cattivo e salvato la ragazza!"
		final_message.visible = true
		timer.start()

func _on_final_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scene/menu.tscn")


func _on_finale_triggered_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
