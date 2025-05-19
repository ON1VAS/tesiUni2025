# spine.gd
extends CharacterBody2D

# --- Variabili Esportabili (modificabili dall'Inspector) ---
# Durata in secondi prima che le spine scompaiano
@export var lifetime: float = 3.0
# Nome dell'animazione da riprodurre (es. "default", "spawn", "active")
@export var animation_name: String = "default"
# Danno che queste spine infliggono (se vuoi gestirlo qui)
@export var damage_amount: int = 20


# --- Riferimenti ai Nodi Figlio (impostali nell'Inspector o assicurati che i nomi corrispondano) ---
# Assicurati che i nomi '$AnimatedSprite2D', '$HitboxArea', '$DespawnTimer'
# corrispondano ai nomi dei tuoi nodi nella scena Spine.

# Riferimento all'AnimatedSprite2D per controllare le animazioni
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# Riferimento all'Area2D che funge da hitbox per il danno
@onready var hitbox_area: Area2D = $HitboxArea
# Riferimento al Timer per la scomparsa
@onready var despawn_timer: Timer = $DespawnTimer


func _ready() -> void:
	$HitboxArea.set_collision_layer_value(2, true)  # Abilita layer 2 (player_weapon)
	$HitboxArea.set_collision_mask_value(6, true) #abilita la maschera per colpire i nemici
	# 1. Avvia l'animazione delle spine
	if animated_sprite and animation_name != "":
		animated_sprite.play(animation_name)
	else:
		print_rich("[color=yellow]Spine Warning:[/color] AnimatedSprite2D non trovato o nome animazione non specificato per ", name)

	# 2. Configura e avvia il timer per la scomparsa
	if despawn_timer:
		despawn_timer.wait_time = lifetime
		despawn_timer.one_shot = true # Il timer si attiverà solo una volta
		# Connetti il segnale 'timeout' del timer alla funzione che rimuove le spine
		# Puoi anche connetterlo dall'editor: seleziona il Timer, vai su "Node" -> "Signals" -> "timeout()" -> Connetti -> scegli questo script e la funzione _on_despawn_timer_timeout
		despawn_timer.timeout.connect(_on_despawn_timer_timeout)
		despawn_timer.start()
	else:
		print_rich("[color=yellow]Spine Warning:[/color] DespawnTimer non trovato per ", name, ". Le spine non scompariranno automaticamente.")
		# Fallback se non hai un Timer node, ma è meno pulito:
		# await get_tree().create_timer(lifetime).timeout
		# queue_free()

	# 3. Prepara la hitbox per rilevare il contatto
	if hitbox_area:
		# Connetti il segnale 'body_entered' dell'Area2D.
		# Questo segnale si attiva quando un PhysicsBody2D (come un Player) entra nell'area.
		# Puoi anche connetterlo dall'editor: seleziona HitboxArea, vai su "Node" -> "Signals" -> "body_entered(body: Node2D)" -> Connetti -> scegli questo script e la funzione _on_hitbox_area_body_entered
		hitbox_area.body_entered.connect(_on_hitbox_area_body_entered)
	else:
		print_rich("[color=yellow]Spine Warning:[/color] HitboxArea (Area2D) non trovata per ", name, ". Nessun danno da contatto verrà gestito da questo script.")

# Funzione chiamata quando il DespawnTimer scade
func _on_despawn_timer_timeout() -> void:
	print("Spine ", name, " stanno scomparendo.")
	queue_free() # Rimuove il nodo Spine (e tutti i suoi figli) dalla scena

# Funzione chiamata quando un corpo (es. il player) entra nella HitboxArea
func _on_hitbox_area_body_entered(body: Node2D) -> void:
	# 'body' è il nodo che è entrato nell'area (es. il Player)
	print("Qualcosa è entrato nella hitbox delle spine: ", body.name)

	# Controlla se il corpo che è entrato ha un metodo per ricevere danno.
	# È una pratica comune avere un metodo tipo "take_damage" sul Player o sui nemici.
	if body.has_method("take_damage"):
		print(body.name, " ha un metodo take_damage. Provo a infliggere danno.")
		# Chiama il metodo 'take_damage' del corpo, passandogli l'ammontare del danno
		body.call("take_damage", damage_amount) # Assicurati che il tuo player/nemico abbia: func take_damage(amount: int): ...

		# OPZIONALE: Se vuoi che le spine scompaiano subito dopo aver colpito qualcosa,
		# decommenta la riga seguente e magari ferma il despawn_timer.
		# if despawn_timer and not despawn_timer.is_stopped():
		#     despawn_timer.stop()
		# queue_free()
	else:
		print(body.name, " è entrato nella hitbox ma non ha un metodo 'take_damage'.")
