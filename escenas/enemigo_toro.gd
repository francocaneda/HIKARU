extends CharacterBody2D

@export var velocidad := 250.0
@export var tiempo_cooldown_danio: float = 0.5 # Cooldown para evitar que se pegue
var jugador

# Control para evitar el spam de daño
var puede_danar: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sonido_muerte: AudioStreamPlayer = $SonidoMuerte

func _ready():
	# Referencia al jugador, verificando que exista.
	if get_parent().has_node("Jugador"):
		jugador = get_parent().get_node("Jugador")
	
	$Detector.body_entered.connect(_on_Detector_body_entered)
	
	pass

func _physics_process(delta):
	# Verifica que la referencia a jugador sea valida antes de usarla.
	if is_instance_valid(jugador):
		var direccion = (jugador.position - position).normalized()
		velocity = direccion * velocidad
		move_and_slide()
		_actualizar_animacion(direccion)
	else:
		velocity = Vector2.ZERO

func _actualizar_animacion(direccion: Vector2):
	if direccion == Vector2.ZERO:
		anim.stop()
		return

	if abs(direccion.x) > abs(direccion.y):
		if direccion.x > 0:
			anim.play("enemigoderecha")
		else:
			anim.play("enemigoizquierda")
	else:
		if direccion.y > 0:
			anim.play("enemigoabajo")
		else:
			anim.play("enemigoarriba")

func _on_Detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador"):
		
		# Solo causa daño si no está en cooldown
		if puede_danar:
			puede_danar = false
			
			if body.has_method("go_to_game_over"):
				body.go_to_game_over()
			
			# Lógica de separación (Knockback visual y Cooldown)
			_aplicar_separacion(body)
			
			print("¡Game Over activado por Enemigo Toro!")

# Lógica de Cooldown y Separación
func _aplicar_separacion(body: Node2D):
	# 1. Empujar al Toro lejos del jugador (Knockback al Toro)
	var direccion_separacion = (position - body.position).normalized()
	# Lo separamos usando una fuerza temporal
	velocity = direccion_separacion * velocidad * 1.5
	
	# 2. Detener el movimiento normal por un instante
	set_physics_process(false)
	
	# 3. Iniciar el cooldown de daño
	var timer_cooldown = get_tree().create_timer(tiempo_cooldown_danio)
	timer_cooldown.timeout.connect(func():
		# Reanudar movimiento normal
		set_physics_process(true)
		# Permitir que el Toro vuelva a dañar
		puede_danar = true
	)

func morir():
	# Reproduce el sonido de muerte y lo desacopla para que persista.
	if is_instance_valid(sonido_muerte):
		
		sonido_muerte.get_parent().remove_child(sonido_muerte)
		get_tree().root.add_child(sonido_muerte)

		
		sonido_muerte.finished.connect(sonido_muerte.queue_free, CONNECT_ONE_SHOT)
		
		# Inicia la reproducción.
		sonido_muerte.play()
	
	# Detiene el enemigo visualmente.
	set_physics_process(false)
	anim.hide()
	
	# Elimina el nodo del enemigo, lo cual es seguro porque el sonido ya no es un hijo.
	queue_free()
