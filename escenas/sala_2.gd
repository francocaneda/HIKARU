extends Node2D

# Referencias a los nodos
@onready var jugador := $Jugador
@onready var pared_secreta: Node2D = $ParedSecreta # Pared que bloquea la Sala 3
@onready var pared_secreta_2: Node2D = $ParedSecreta2 # Pared que bloquea la Sala 4
@onready var detector_sala_3: Area2D = $DetectorSala3
@onready var musica_sala: AudioStreamPlayer = $MusicaSala

@export var escena_enemigo_volador: PackedScene
@export var escena_pared_secreta: PackedScene
@export var escena_enemigo_techo: PackedScene 

# Previene llamadas múltiples a cambiar_a_escena durante la transición.
var transicion_en_curso: bool = false

func _ready():
	# El jugador comienza en una posicion adecuada para la entrada de Sala 2
	jugador.position = Vector2(-400, 0)
	
	# Inicia el spawn de enemigos (siempre al entrar)
	spawn_enemigos_sala2()



func _physics_process(delta):
	Global.posicion_jugador = jugador.position

	# Logica para abrir la puerta/pared cuando todos los enemigos mueren
	var enemigos_restantes = get_tree().get_nodes_in_group("Enemigo")
	if enemigos_restantes.size() == 0:
		abrir_puerta()

# Define dónde y qué enemigos aparecen
func spawn_enemigos_sala2():
	# Instancia 2 Enemigos Voladores en posiciones variadas
	instanciar_enemigo_volador(Vector2(900, 500))
	instanciar_enemigo_volador(Vector2(900, 500))

	# Instancia 2 Enemigo Techo
	instanciar_enemigo_techo(Vector2(800, 50))
	instanciar_enemigo_techo(Vector2(490, 50))
	print("Encuentro de Sala 2 iniciado. Los enemigos siempre respawnearán al entrar.")

# --- Funciones de Instanciación ---

func instanciar_enemigo_volador(posicion_spawn: Vector2):
	call_deferred("instanciar_enemigo_volador_de_forma_segura", posicion_spawn)

func instanciar_enemigo_volador_de_forma_segura(posicion_spawn: Vector2):
	if escena_enemigo_volador:
		# Instancia la pared secreta si aun no existe (solo si es necesario)
		if not is_instance_valid(pared_secreta):
			if escena_pared_secreta:
				var nueva_pared = escena_pared_secreta.instantiate()
				add_child(nueva_pared)
				pared_secreta = nueva_pared
			
		var enemigo_volador = escena_enemigo_volador.instantiate()
		add_child(enemigo_volador)
		
		# Usa la posición de spawn
		enemigo_volador.global_position = posicion_spawn
		print("¡Enemigo volador instanciado en:", posicion_spawn, "!")

func instanciar_enemigo_techo(posicion_spawn: Vector2):
	call_deferred("instanciar_enemigo_techo_de_forma_segura", posicion_spawn)

func instanciar_enemigo_techo_de_forma_segura(posicion_spawn: Vector2):
	if escena_enemigo_techo:
		var enemigo_techo = escena_enemigo_techo.instantiate()
		add_child(enemigo_techo)
		enemigo_techo.global_position = posicion_spawn
		print("¡Enemigo Techo instanciado en:", posicion_spawn, "!")


func abrir_puerta():
	# ELIMINA AMBAS PAREDES SECRETAS (Sala 3 y Sala 4) SI SON VÁLIDAS

	if is_instance_valid(pared_secreta):
		pared_secreta.queue_free()
	
	if is_instance_valid(pared_secreta_2):
		pared_secreta_2.queue_free()

# --- Transición a la Siguiente Escena (Sala 3) ---

func _on_detector_sala_3_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador") and not transicion_en_curso:
		
		# 💥 RESTRICCIÓN: Solo permite el paso si la pared secreta a Sala 3 ya no es válida.
		if not is_instance_valid(pared_secreta):
			transicion_en_curso = true
			print("¡El jugador ha pasado a la Sala 3!")
			call_deferred("cambiar_a_siguiente_escena")
		else:
			print("Transición bloqueada: La pared secreta a Sala 3 aún bloquea la salida (enemigos restantes).")


func cambiar_a_siguiente_escena():
	var root = get_tree().root
	
	# MOVER LA MÚSICA DESPUÉS: Sigue la misma lógica (solo si la quieres persistente).
	if is_instance_valid(musica_sala) and musica_sala.get_parent():
		musica_sala.get_parent().remove_child(musica_sala)
		root.add_child(musica_sala)

	get_tree().change_scene_to_file("res://escenas/Sala3.tscn")

# --- Transición a Sala 4 ---

func _on_detector_sala_4_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador") and not transicion_en_curso:
		

		if not is_instance_valid(pared_secreta_2):
			transicion_en_curso = true
			print("¡El jugador ha pasado a la Sala 4!")

			call_deferred("cambiar_a_sala_4")
		else:
			print("Transición bloqueada: La pared secreta a Sala 4 aún bloquea la salida (enemigos restantes).")


func cambiar_a_sala_4():
	var root = get_tree().root
	

	
	# MOVER LA MÚSICA DESPUÉS: Sigue la misma lógica.
	if is_instance_valid(musica_sala) and musica_sala.get_parent():
		musica_sala.get_parent().remove_child(musica_sala)
		root.add_child(musica_sala)
	
	# Cambia a la nueva escena de la Sala 4
	get_tree().change_scene_to_file("res://escenas/Sala4.tscn")
