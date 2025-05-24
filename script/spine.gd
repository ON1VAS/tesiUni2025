# spine.gd
extends CharacterBody2D # Considera cambiarlo a Node2D se le spine non si muovono fisicamente

# --- Variabili Esportabili ---
@export var lifetime: float = 2.0
@export var animation_name: String = "spawn" # Es. "spawn", "idle_loop", "despawn"
@export var damage_amount: int = 15
@export var variation: int = 1 # Per differenziare le spine spawnate dal Golem

# --- Riferimenti ai Nodi ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_area: Area2D = $HitboxArea # L'Area2D che infligge danno
@onready var despawn_timer: Timer = $DespawnTimer
# Non c'è bisogno di una CollisionShape2D per il CharacterBody2D se non si muove
# o non interagisce fisicamente con il mondo. Se lo fa, assicurati sia configurata.

# --- Variabili Interne ---
var has_hit_target: bool = false # Per evitare colpi multipli se la spina rimane attiva

func _ready() -> void:
	# 1. Configura la HitboxArea
	if hitbox_area:
		# Layer della Hitbox: Generalmente 0 per le hitbox offensive,
		# non devono essere "colpite" da altre cose.
		hitbox_area.collision_layer = 0 # Non appartiene a un layer fisico da colpire

		# Maschera della Hitbox: Cosa questa hitbox deve rilevare.
		# Dovrebbe rilevare il layer dell'hurtbox del giocatore.
		# Assumiamo che il layer "player_hurtbox" sia il 7 (come da script del Golem).
		# CAMBIA QUESTO SE IL LAYER DEL TUO GIOCATORE È DIVERSO!
		hitbox_area.set_collision_mask_value(7, true) # Maschera per "player_hurtbox_layer"
		
		# Connetti il segnale. body_entered è per PhysicsBody2D.
		# Se l'hurtbox del player è un'Area2D, usa area_entered.
		# Per coprire entrambi i casi o se non sei sicuro, puoi connettere entrambi
		# e gestire la logica per evitare doppi danni.
		# Qui usiamo body_entered assumendo che il player sia un CharacterBody2D.
		hitbox_area.body_entered.connect(_on_hitbox_area_body_entered)
		# Potresti voler connettere anche area_entered se l'hurtbox del player è un'Area2D
		# hitbox_area.area_entered.connect(_on_hitbox_area_area_entered)
	else:
		print_rich("[color=yellow]Spine Warning:[/color] HitboxArea non trovata. Nessun danno.")

	# 2. Avvia l'animazione
	if animated_sprite and animation_name != "":
		animated_sprite.play(animation_name)
		# Se hai un'animazione di "spawn" e poi una di "idle_loop", potresti concatenarle:
		# animated_sprite.play("spawn")
		# await animated_sprite.animation_finished
		# if animated_sprite: # Controlla se il nodo esiste ancora (potrebbe essere stato despawnato)
		#     animated_sprite.play("idle_loop") # Assumendo che tu abbia un'animazione "idle_loop"
	else:
		print_rich("[color=yellow]Spine Warning:[/color] AnimatedSprite2D non trovato o nome animazione non specificato.")

	# 3. Configura e avvia il timer per la scomparsa
	if despawn_timer:
		despawn_timer.wait_time = lifetime
		despawn_timer.one_shot = true
		despawn_timer.timeout.connect(_on_despawn_timer_timeout)
		despawn_timer.start()
	else:
		print_rich("[color=yellow]Spine Warning:[/color] DespawnTimer non trovato. Despawn manuale dopo 'lifetime'.")
		await get_tree().create_timer(lifetime).timeout
		if is_instance_valid(self): # Controlla se esiste ancora prima di chiamare queue_free
			queue_free()
	
	# 4. Logica specifica per la variazione (opzionale)
	# Questo viene chiamato dopo che il Golem ha impostato 'variation'
	# print("Spina creata con variazione: ", variation)
	# match variation:
	# 	1:
	# 		animated_sprite.modulate = Color.WHITE
	# 		damage_amount = 15
	# 	2:
	# 		animated_sprite.modulate = Color.DARK_SLATE_GRAY
	# 		damage_amount = 20
	# 		# Magari scala più grande?
	# 		scale = Vector2(1.2, 1.2)
	# 	3:
	# 		animated_sprite.modulate = Color.BLACK
	# 		damage_amount = 25
	# 		# Magari un'animazione diversa?
	# 		if animated_sprite: animated_sprite.play("special_spawn")


# Se vuoi che le spine facciano qualcosa ogni frame (es. seguire lentamente il player)
# func _physics_process(delta: float) -> void:
#   if not is_on_floor(): # Esempio: se è un CharacterBody2D e vuoi la gravità
#       velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
#   move_and_slide()


# Funzione chiamata quando il DespawnTimer scade
func _on_despawn_timer_timeout() -> void:
	# print("Spine ", name, " stanno scomparendo per timeout.")
	# Potresti voler riprodurre un'animazione di "despawn" prima di liberare
	# if animated_sprite and animated_sprite.has_animation("despawn"):
	#     animated_sprite.play("despawn")
	#     await animated_sprite.animation_finished
	queue_free()

# Funzione chiamata quando un corpo (es. il player) entra nella HitboxArea
func _on_hitbox_area_body_entered(body: Node2D) -> void:
	if has_hit_target: # Se ha già colpito, non fare altro
		return

	# 'body' è il nodo che è entrato nell'area (es. il Player, che è un CharacterBody2D)
	# print("Spina: ", body.name, " è entrato nella hitbox.")

	# Controlla se il corpo appartiene al gruppo del giocatore e ha un metodo per ricevere danno.
	if body.is_in_group("giocatore") and body.has_method("take_damage"):
		# print(body.name, " è un giocatore e ha take_damage. Infliggo danno: ", damage_amount)
		body.call("take_damage", damage_amount)
		has_hit_target = true # Segna che ha colpito

		# OPZIONALE: Fai scomparire le spine subito dopo aver colpito.
		# Questo previene che una singola spina colpisca più volte se il giocatore rimane nell'area.
		# È anche gestito da has_hit_target, ma questo le rimuove visivamente.
		if despawn_timer and not despawn_timer.is_stopped():
			despawn_timer.stop() # Ferma il timer normale
		_on_despawn_timer_timeout() # Chiama la funzione di despawn (che farà queue_free)
	# else:
		# print(body.name, " non è un giocatore target o non ha take_damage.")

# Se l'hurtbox del player è un'Area2D figlia del player (CharacterBody2D)
# func _on_hitbox_area_area_entered(area: Area2D) -> void:
# 	if has_hit_target:
# 		return
#
# 	# print("Spina: Area ", area.name, " è entrata nella hitbox. Parent: ", area.get_parent().name)
# 	if area.is_in_group("player_hurtbox"): # Assumendo che l'hurtbox del player sia in questo gruppo
# 		var player_body = area.get_parent() # L'Area2D è figlia del CharacterBody2D del player
# 		if player_body and player_body.has_method("take_damage"):
# 			print(player_body.name, " (da area) ha take_damage. Infliggo danno: ", damage_amount)
# 			player_body.call("take_damage", damage_amount)
# 			has_hit_target = true
#
# 			if despawn_timer and not despawn_timer.is_stopped():
# 				despawn_timer.stop()
# 			_on_despawn_timer_timeout()
# 		# else:
# 			# print(player_body.name, " (da area) non ha take_damage.")
# 	# else:
# 		# print("Area ", area.name, " non è un player_hurtbox.")


# Questa funzione sarà chiamata dal Golem dopo l'instanziazione
# per impostare la variazione specifica
func set_variation(type: int) -> void:
	variation = type
	# Applica qui la logica che dipende dalla variazione,
	# dato che _ready() potrebbe essere già stato chiamato quando il Golem imposta 'variation'.
	# Questa è una ridondanza sicura o un modo per aggiornare se _ready() non lo gestisce
	# abbastanza presto.
	# print("Spina - set_variation chiamata con: ", type)
	match variation:
		1:
			if animated_sprite: animated_sprite.modulate = Color.WHITE
			damage_amount = 15 # Danno base per variazione 1
		2:
			if animated_sprite: animated_sprite.modulate = Color.LIGHT_CORAL # Colore diverso
			damage_amount = 20 # Danno per variazione 2
			# Potrebbe avere un lifetime diverso o altre proprietà
			# lifetime = 1.5
			# if despawn_timer: despawn_timer.wait_time = lifetime # Aggiorna il timer se necessario
		3:
			if animated_sprite: animated_sprite.modulate = Color.DARK_RED # Altro colore
			damage_amount = 25 # Danno per variazione 3
			if animated_sprite and animated_sprite.has_animation("powerful_spawn"):
				animated_sprite.play("powerful_spawn")
			# Potrebbe avere una scala diversa
			# scale = Vector2(1.1, 1.1)

	# Se hai modificato lifetime qui, e il timer è già partito in _ready(),
	# potresti doverlo riavviare o aggiornare il suo wait_time qui se necessario.
	# Ma è più semplice se le variazioni non cambiano il lifetime dopo _ready().
