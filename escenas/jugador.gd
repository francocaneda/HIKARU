extends CharacterBody2D

@export var velocidad := 450.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var espada = $Espada    
@onready var sonido_muerte: AudioStreamPlayer = $SonidoMuerte 

var direccion_mirada: Vector2 = Vector2.RIGHT 
# Flag para evitar llamadas dobles a Game Over
var is_dead: bool = false
# Flag de invulnerabilidad tras perder el escudo
var is_invulnerable: bool = false


const DEATH_DELAY_BEFORE_GAME_OVER: float = 2.5 

# ----------------- Funciones de Movimiento y Combate -----------------

func _physics_process(delta: float) -> void:
	var direccion = Vector2.ZERO
	direccion.x = Input.get_action_strength("ui_derecha") - Input.get_action_strength("ui_izquierda")
	direccion.y = Input.get_action_strength("ui_abajo") - Input.get_action_strength("ui_arriba")

	if direccion != Vector2.ZERO:
		direccion = direccion.normalized() * velocidad
		_actualizar_animacion(direccion)
		direccion_mirada = direccion.normalized() 
	else:
		anim.stop()

	velocity = direccion
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"): 
		_lanzar_espada()

func _actualizar_animacion(direccion: Vector2) -> void:
	if abs(direccion.x) > abs(direccion.y):
		if direccion.x > 0:
			anim.play("personajederecha")
		else:
			anim.play("personajeizquierda")
	else:
		if direccion.y > 0:
			anim.play("personajeabajo")
		else:
			anim.play("personajearriba")

func agregar_item(item_name: String):
	# Usa el inventario GLOBAL
	Global.inventario.append(item_name)
	print("Inventario:", Global.inventario)
	
	if item_name == "Escudo":
		if get_parent() and get_parent().has_method("spawn_enemigo_volador"):
			get_parent().spawn_enemigo_volador()

func _lanzar_espada() -> void:
	if espada.lanzada:
		return

	var dir = direccion_mirada
	if dir != Vector2.ZERO:
		espada.show()
		espada.lanzar(espada.global_position, dir, self)

# ----------------- Lógica de Muerte y Escudo -----------------

# FUNCIÓN PRINCIPAL DE MUERTE/GAME OVER
func go_to_game_over():
	
	# Ignorar el golpe si es invulnerable
	if is_invulnerable:
		print("Golpe ignorado: El jugador es invulnerable temporalmente.")
		return
		
	# Evita que se ejecute dos veces
	if is_dead:
		return
	
	# VERIFICACIÓN DEL ESCUDO
	if Global.inventario.has("Escudo"):
		_activar_escudo()
		return
	
	is_dead = true
	
	# Si no tiene escudo, ejecuta la lógica de Game Over
	print("El jugador ha muerto. Iniciando secuencia de congelamiento y Game Over.")
	
	_iniciar_congelamiento_y_desaparicion()


func _activar_escudo():
	print("¡El escudo ha sido consumido y te ha salvado del golpe letal!")
	
	# Quitar el Escudo del inventario (Usa Global.inventario)
	Global.inventario.erase("Escudo")
	
	# Notificar al HUD para que remueva el ícono
	if is_instance_valid(HUD):
		HUD.remover_item() 
		
	# Reemplazamos el teletransport por la invulnerabilidad
	_activar_invulnerabilidad(2.0)
	
# FUNCIÓN: Implementa el parpadeo y la invulnerabilidad
func _activar_invulnerabilidad(duracion: float):
	if is_invulnerable: return # Evitar activar dos invulnerabilidades a la vez
	
	is_invulnerable = true
	print("¡Jugador activó invulnerabilidad por ", duracion, "!")
	
	# Crear el Tween para el parpadeo (titileo)
	var tween = create_tween()
	
	# Configurar el ciclo de parpadeo (visible -> transparente -> visible)
	tween.set_loops() # Loop infinito hasta que lo paremos
	tween.tween_property(anim, "modulate", Color(1, 1, 1, 0.3), 0.05)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.05)
	
	# Iniciar el temporizador de duración
	var timer = get_tree().create_timer(duracion)
	timer.timeout.connect(func():
		# Terminar la invulnerabilidad
		is_invulnerable = false
		print("Invulnerabilidad terminada.")
		
		# Detener y limpiar el Tween, asegurando que el color sea blanco (sin parpadeo)
		tween.kill()
		# CORRECCIÓN: Usamos la variable 'anim' en lugar del path '$anim'
		anim.modulate = Color.WHITE
		
	, CONNECT_ONE_SHOT)

# 💥 RESTAURADO: Congelamiento, desaparición y espera
func _iniciar_congelamiento_y_desaparicion():
	
	# Congelamos todo el juego inmediatamente (incluye enemigos).
	get_tree().paused = true
	
	# 💥 NUEVO: Reproducir sonido de muerte
	if is_instance_valid(sonido_muerte):
		sonido_muerte.play()
	
	# Ocultamos al jugador
	hide() 
	
	# Creamos un temporizador para esperar el delay
	var timer = get_tree().create_timer(DEATH_DELAY_BEFORE_GAME_OVER)
	
	# Cuando el tiempo termine, ejecutamos las acciones finales
	timer.timeout.connect(_execute_game_over_actions)


# FUNCIÓN QUE EJECUTA LAS ACCIONES PELIGROSAS (cambio de escena)
func _execute_game_over_actions():
	# Verificar si el SceneTree es válido antes de usarlo.
	if not is_instance_valid(get_tree()):
		print("ERROR FIX: SceneTree no válido. Evitando crash.")
		return
	
	# Detención de la música
	if is_instance_valid(Audio):
		Audio.detener_musica() 
	
	# Aseguramos que el escudo no persista en el HUD al ir a Game Over
	if Global.inventario.has("Escudo"):
		Global.inventario.erase("Escudo")
		# Notificar al HUD que remueva el ícono
		if is_instance_valid(HUD):
			HUD.remover_item()
		print("Escudo eliminado del inventario global al ir a Game Over.")
	

	
	# Cambiamos de escena
	get_tree().change_scene_to_file("res://escenas/GameOver.tscn")

func morir():
	go_to_game_over()
