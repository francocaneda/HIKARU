extends CharacterBody2D

@export var velocidad := 150.0
@export var tiempo_cooldown_danio: float = 0.5 # Cooldown para evitar que se pegue
var jugador

# Control para evitar el spam de daño
var puede_danar: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sonido_muerte: AudioStreamPlayer = $SonidoMuerte

func _ready():
	# Referencia al jugador (con validacion)
	if get_parent().has_node("Jugador"):
		jugador = get_parent().get_node("Jugador")
		
	# Conecta la senal de colision del detector
	$Detector.body_entered.connect(_on_Detector_body_entered)
	
	pass 

func _physics_process(delta):
	# Evita errores si el jugador es eliminado de la escena
	if is_instance_valid(jugador):
		var direccion = (jugador.position - position).normalized()
		velocity = direccion * velocidad
		move_and_slide()
		_actualizar_animacion(direccion)
	else:
		velocity = Vector2.ZERO # Detiene al enemigo si no hay jugador

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
			
			print("¡Game Over activado por Enemigo!")

# Lógica de Cooldown y Separación
func _aplicar_separacion(body: Node2D):
	# 1. Empujar al Enemigo lejos del jugador (Knockback al Enemigo)
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
		# Permitir que el Enemigo vuelva a dañar
		puede_danar = true
	)


func morir():
	# Reproduce el sonido de muerte inmediatamente.
	sonido_muerte.play()
	
	# Conexión segura para eliminar el nodo de sonido después de reproducirse.
	if is_instance_valid(sonido_muerte):
		
		# Desacopla el sonido antes de que el enemigo muera:
		sonido_muerte.get_parent().remove_child(sonido_muerte)
		get_tree().root.add_child(sonido_muerte)


		sonido_muerte.finished.connect(sonido_muerte.queue_free, CONNECT_ONE_SHOT)
	
	# Oculta el enemigo y detiene su movimiento.
	set_physics_process(false)
	anim.hide()
	
	# Elimina el nodo del enemigo (ahora es seguro, el sonido ya no es su hijo).
	queue_free()
