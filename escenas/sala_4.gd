extends Node2D

# Referencias a los nodos de la Sala 4
@onready var jugador: CharacterBody2D # La referencia se asignará en _ready
@onready var pared_secreta: Node2D = $ParedSecreta # Solo una pared aquí
@onready var detector_sala_2: Area2D = $DetectorSala2 # Detector para volver a Sala 2
@onready var musica_sala: AudioStreamPlayer = $MusicaSala

@export var escena_enemigo_volador: PackedScene
@export var escena_pared_secreta: PackedScene
@export var escena_enemigo_toro: PackedScene 
@export var escena_enemigo_techo: PackedScene 

# Constante para la escena de retorno
# Apunta a Sala 3 para avanzar
const SCENE_TO_RETURN_TO: String = "res://escenas/Sala3.tscn"

# BANDERA DE SINCRONIZACIÓN: Previene que la transición se dispare dos veces.
var transicion_en_curso: bool = false 

func _ready():

	var jugadores_presentes = get_tree().get_nodes_in_group("Jugador")
	
	if jugadores_presentes.size() > 0:

		jugador = jugadores_presentes[0]
	else:
		print("ADVERTENCIA: El Jugador no se encontró en el árbol de escena. La lógica de movimiento y posición puede fallar.")

	spawn_enemigos_sala4()
	

func _physics_process(delta):
	# Si el jugador es válido, actualizamos su posición global.
	if is_instance_valid(jugador):
		Global.posicion_jugador = jugador.position

	# Logica para abrir la puerta/pared cuando todos los enemigos mueren
	var enemigos_restantes = get_tree().get_nodes_in_group("Enemigo")
	if enemigos_restantes.size() == 0:
		abrir_puerta()

func spawn_enemigos_sala4():

	
	instanciar_enemigo_toro(Vector2(200, 600))
	instanciar_enemigo_toro(Vector2(800, 600))
	
	instanciar_enemigo_techo(Vector2(350, 50))
	instanciar_enemigo_techo(Vector2(1200, 400), deg_to_rad(90))
	instanciar_enemigo_techo(Vector2(900, 600), deg_to_rad(180))
	
	print("Encuentro de Sala 4 iniciado por código (2 Toros, 3 Techo).")


# --- Funciones de Instanciación (Sin cambios) ---

func instanciar_enemigo_volador(posicion_spawn: Vector2):
	call_deferred("instanciar_enemigo_volador_de_forma_segura", posicion_spawn)

func instanciar_enemigo_volador_de_forma_segura(posicion_spawn: Vector2):
	# VERIFICACIÓN DE DEBUG: Comprueba si la escena está asignada
	if escena_enemigo_volador:
		var enemigo_volador = escena_enemigo_volador.instantiate()
		add_child(enemigo_volador)
		enemigo_volador.global_position = posicion_spawn
	else:
		print("ADVERTENCIA CRÍTICA: 'escena_enemigo_volador' no está asignada en el Inspector de Sala4.tscn.")

func instanciar_enemigo_toro(posicion_spawn: Vector2):
	call_deferred("instanciar_enemigo_toro_de_forma_segura", posicion_spawn)

func instanciar_enemigo_toro_de_forma_segura(posicion_spawn: Vector2):
	# VERIFICACIÓN DE DEBUG: Comprueba si la escena está asignada
	if escena_enemigo_toro:
		var enemigo_toro = escena_enemigo_toro.instantiate()
		add_child(enemigo_toro)
		enemigo_toro.global_position = posicion_spawn
	else:
		print("ADVERTENCIA CRÍTICA: 'escena_enemigo_toro' no está asignada en el Inspector de Sala4.tscn.")

# NUEVAS FUNCIONES: Instanciación del Enemigo Techo (ahora con rotación)
func instanciar_enemigo_techo(posicion_spawn: Vector2, rotation_angle: float = 0): # 👈 Añadido rotation_angle
	# Pasamos todos los argumentos a call_deferred
	call_deferred("instanciar_enemigo_techo_de_forma_segura", posicion_spawn, rotation_angle)

func instanciar_enemigo_techo_de_forma_segura(posicion_spawn: Vector2, rotation_angle: float = 0): # 👈 Añadido rotation_angle
	# VERIFICACIÓN DE DEBUG: Comprueba si la escena está asignada
	if escena_enemigo_techo:
		var enemigo_techo = escena_enemigo_techo.instantiate()
		add_child(enemigo_techo)
		enemigo_techo.global_position = posicion_spawn
		enemigo_techo.rotation = rotation_angle # 👈 Aplicamos la rotación
	else:
		print("ADVERTENCIA CRÍTICA: 'escena_enemigo_techo' no está asignada en el Inspector de Sala4.tscn.")
		
# --- Fin de Funciones de Instanciación ---


func abrir_puerta():
	# ELIMINA LA ÚNICA PARED SECRETA

	if is_instance_valid(pared_secreta):
		pared_secreta.queue_free()

# --- Transición para ir a la Sala 3 ---

func _on_detector_sala_2_body_entered(body: Node2D) -> void:

	if body.is_in_group("Jugador") and not transicion_en_curso:
		

		if not is_instance_valid(pared_secreta):
			transicion_en_curso = true # Activamos la bandera
			
			# Mensaje de avance a Sala 3
			print("¡El jugador está avanzando a la Sala 3!")
			
			call_deferred("cambiar_a_sala_2")
		else:
			print("Transición bloqueada: La pared secreta aún bloquea la salida (enemigos restantes).")

func cambiar_a_sala_2():
	var root = get_tree().root

	# Mueve el nodo de música a la raíz antes de cambiar de escena
	if is_instance_valid(musica_sala) and musica_sala.get_parent():
		musica_sala.get_parent().remove_child(musica_sala)
		root.add_child(musica_sala)
	

	
	# Regresa a la escena de la Sala 3 (Nueva Sala de Destino)
	get_tree().change_scene_to_file(SCENE_TO_RETURN_TO)
