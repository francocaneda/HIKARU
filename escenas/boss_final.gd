extends CharacterBody2D
class_name BossFinal 

# Señal para notificar el cambio de vida
signal vida_cambiada(vida_actual: int, vida_maxima: int)

# 🛡Propiedades del Boss
@export var velocidad: float = 350.0 
@export var vida_maxima: int = 7 
@export var tiempo_cooldown_danio: float = 0.5 # Tiempo en segundos para evitar que se pegue

var vida_actual: int
var jugador: CharacterBody2D = null

# Vector que define la dirección actual del movimiento.
var current_movement_direction: Vector2 = Vector2.ZERO 

# Control para evitar el "pegado" y spam de daño
var puede_danar: bool = true 

# Referencias a nodos hijos
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D 
@onready var sonido_muerte: AudioStreamPlayer = $SonidoMuerte 
@onready var detector: Area2D = $Detector 

func _ready():
	vida_actual = vida_maxima
	add_to_group("Enemigo")
	
	var root = get_tree().get_root()
	if root.find_child("Jugador", true, false):
		jugador = root.find_child("Jugador", true, false)

	# Inicializa la dirección de movimiento aleatoria
	_set_random_direction()
	
	# Al inicio, emitimos la señal para que el contador se inicialice
	vida_cambiada.emit(vida_actual, vida_maxima) 

# Establece una dirección de movimiento inicial aleatoria
func _set_random_direction():
	# Genera un ángulo aleatorio y lo convierte en un vector normalizado
	var random_angle = randf_range(0, 2 * PI)
	current_movement_direction = Vector2.RIGHT.rotated(random_angle)
	velocity = current_movement_direction * velocidad
	_actualizar_animacion(current_movement_direction)


func _physics_process(delta):
	if vida_actual > 0:
		# Mueve el Boss en su dirección actual
		velocity = current_movement_direction * velocidad
		var collision = move_and_slide()
		
		# Itera sobre las colisiones para verificar si chocó con una "Pared"
		for i in range(get_slide_collision_count()):
			var collision_info = get_slide_collision(i)
			# Verificamos si es una pared.
			if collision_info.get_collider() is Node and (
				collision_info.get_collider().name.begins_with("Pared")
				
			):
				# Refleja el vector de movimiento (rebote)
				current_movement_direction = current_movement_direction.bounce(collision_info.get_normal())
				# Actualizamos la velocidad reflejada
				velocity = current_movement_direction * velocidad
				
				# Actualiza la animación con la nueva dirección
				_actualizar_animacion(current_movement_direction)
				# Esto asegura que el boss se mueva inmediatamente en la nueva dirección
				move_and_slide() 
				break

	else:
		# Si está muerto
		velocity = Vector2.ZERO
		move_and_slide()
		anim.stop()

# FUNCIÓN DE ANIMACIÓN
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

# FUNCIÓN DE COLISIÓN MORTAL
func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador"):
		
		# Solo causa daño si no está en cooldown
		if puede_danar:
			puede_danar = false
			
			if body.has_method("go_to_game_over"):
				body.go_to_game_over()
			
			# Lógica de separación (Knockback visual y Cooldown)
			_aplicar_separacion(body)

func _aplicar_separacion(body: Node2D):
	# Empujar al Boss lejos del jugador (Knockback al Boss)
	var direccion_separacion = (position - body.position).normalized()
	velocity = direccion_separacion * velocidad 
	
	# Detener el movimiento normal por un instante
	set_physics_process(false)
	
	# Iniciar el cooldown de daño
	var timer_cooldown = get_tree().create_timer(tiempo_cooldown_danio)
	timer_cooldown.timeout.connect(func():
		# Reanudar movimiento normal
		set_physics_process(true) 
		# Permitir que el Boss vuelva a dañar
		puede_danar = true 
	)

# Función de daño
func recibir_danio(cantidad: int = 1):
	vida_actual -= cantidad
	print("Boss recibió daño. Vida restante:", vida_actual)
	
	# Emitimos la señal DESPUÉS de cambiar la vida
	vida_cambiada.emit(vida_actual, vida_maxima)
	
	if vida_actual <= 0:
		morir()

func morir():
	print("¡BOSS FINAL DERROTADO!")
	set_physics_process(false)
	
	if is_instance_valid(sonido_muerte):
		sonido_muerte.play()
		sonido_muerte.get_parent().remove_child(sonido_muerte)
		get_tree().get_root().add_child(sonido_muerte)
		sonido_muerte.finished.connect(sonido_muerte.queue_free, CONNECT_ONE_SHOT)
	
	await get_tree().create_timer(0.5).timeout
	
	queue_free()
	
func iniciar_pelea():
	pass
