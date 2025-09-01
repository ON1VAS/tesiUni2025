extends Node2D

@onready var boss: Node = $Boss
@onready var boss_trigger : Area2D = $BossTrigger
@onready var player = $protagonista
@onready var camera: Camera2D = $protagonista/Camera2D
@onready var hud := $BossHUD
@onready var sprite2D4 = $Sprite2D4
@onready var sprite2D5 = $Sprite2D5

@onready var canc_tilemap = $TileMapLayer4
@onready var canc_hitbox = $hitboxes/CollisionShape2D12

func _process(delta):
	# Mantieni solo la coordinata X del player, Y rimane fissa
	sprite2D4.position.x = player.position.x
	sprite2D5.position.x = player.position.x
	
func _ready() -> void:
	DebuffManager.set_platform_mode(true)
	DebuffManager.apply_to_player($protagonista)
	boss_trigger.body_entered.connect(_on_boss_trigger_body_entered) #meglio che lo forzo il trigger non si sa mai
	hud.visible = false  # parte spento
	
	if boss.has_signal("died"):
		boss.died.connect(_on_boss_died)



func _on_boss_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
	#attiviamo sto boss
		if boss.has_method("activate"):
			boss.activate()
		else:
			# fallback: se preferisci un flag pubblico
			boss.active = true
		# opzionale: cambia musica, chiudi porte, ecc.
		boss_trigger.queue_free() # trigger “usa e getta”
		# Accendi HUD e collegalo al boss
		hud.setup(boss, player, camera)

func _on_boss_died() -> void:
	# spegni il TileMap
	if is_instance_valid(canc_tilemap):
		canc_tilemap.visible = false
		canc_tilemap.set_deferred("collision_enabled", false)

	# spegni la collisione extra
	if is_instance_valid(canc_hitbox):
		canc_hitbox.set_deferred("disabled", true)
