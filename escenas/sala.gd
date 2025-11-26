extends Node2D

# Referencias a los nodos
@onready var jugador := $Jugador
@onready var pared_secreta: Node2D = $ParedSecreta
@onready var detector_sala_2: Area2D = $DetectorSala2
@onready var musica_sala: AudioStreamPlayer = $MusicaSala

@export var escena_enemigo_volador: PackedScene
@export var escena_pared_secreta: PackedScene

func _ready():
	jugador.position = Vector2(-400, 0)
	
	# Registra la musica de la sala con el sistema de audio global.
	Audio.registrar_musica(musica_sala)
	
	# Inicia la musica de la sala si el sonido esta activado.
	Audio.iniciar_musica_de_escena(musica_sala)

# El resto de tu código...
func _physics_process(delta):
	Global.posicion_jugador = jugador.position

	var enemigos_restantes = get_tree().get_nodes_in_group("Enemigo")
	if enemigos_restantes.size() == 0:
		abrir_puerta()

func spawn_enemigo_volador():
	call_deferred("instanciar_enemigo_de_forma_segura")

func instanciar_enemigo_de_forma_segura():
	if escena_enemigo_volador:
		if not is_instance_valid(pared_secreta):
			if escena_pared_secreta:
				var nueva_pared = escena_pared_secreta.instantiate()
				add_child(nueva_pared)
				pared_secreta = nueva_pared
			
		var enemigo_volador = escena_enemigo_volador.instantiate()
		add_child(enemigo_volador)
		enemigo_volador.global_position = Vector2(500, 400)
		print("¡Enemigo volador instanciado!")

func abrir_puerta():
	if is_instance_valid(pared_secreta):
		pared_secreta.queue_free()

func _on_detector_sala_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador"):
		print("¡El jugador ha pasado a la siguiente sala!")
		call_deferred("cambiar_a_siguiente_escena")

func cambiar_a_siguiente_escena():
	# Mueve el nodo de música a la raíz antes de cambiar de escena.
	musica_sala.get_parent().remove_child(musica_sala)
	get_tree().root.add_child(musica_sala)

	get_tree().change_scene_to_file("res://escenas/Sala2.tscn")
