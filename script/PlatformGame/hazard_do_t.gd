extends Area2D

@export var damage: int = 10
@export var tick_seconds: float = 3.0
@export var affect_group: String = "giocatore"   # il tuo gruppo player
@export var first_tick_immediate: bool = true    # true = colpisce subito quando entri

# Mappa: corpo -> timer corrente (ricreato ad ogni tick)
var _timers: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true   # assicurati sia true
	monitorable = true

func _on_body_entered(body: Node) -> void:
	# Filtra per gruppo (se vuoi colpire solo il player)
	if affect_group != "" and not body.is_in_group(affect_group):
		return
	# Serve la funzione Damage(dam)
	if not body.has_method("Damage"):
		return

	if first_tick_immediate:
		body.Damage(damage)

	_start_tick_loop_for(body)

func _on_body_exited(body: Node) -> void:
	# smetti di pianificare tick per quel body
	if _timers.has(body):
		_timers.erase(body)

func _start_tick_loop_for(body: Node) -> void:
	if not is_instance_valid(body):
		return

	# crea un timer "usa e getta"
	var t: SceneTreeTimer = get_tree().create_timer(tick_seconds)
	_timers[body] = t

	t.timeout.connect(func ():
		# se il body non esiste più o non è più dentro, stop
		if not is_instance_valid(body):
			_timers.erase(body)
			return
		# è ancora sovrapposto?
		var still_overlapping := false
		for b in get_overlapping_bodies():
			if b == body:
				still_overlapping = true
				break

		if not still_overlapping:
			_timers.erase(body)
			return

		# applica danno e ricomincia il loop
		if body.has_method("Damage"):
			body.Damage(damage)

		_start_tick_loop_for(body)
	)
