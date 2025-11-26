extends Node2D

# Referencias a nodos de la escena
@onready var boss_node: BossFinal = $BossFinal 
@onready var vida_boss_label: Label = $CanvasLayer/VidaBossLabel 


@export var escena_enemigo_volador: PackedScene
@export var escena_enemigo: PackedScene 
@export var escena_enemigo_toro: PackedScene

# VARIABLES DE CONTROL DE SPAWN
var spawn_timer: Timer = null 

# VARIABLES DE CONTROL DE VICTORIA
const GAME_OVER_SCENE: String = "res://escenas/GameOver.tscn"
var is_game_over_sequence_active: bool = false
var victory_monitor_timer: Timer = null
# Ruta de la fuente Morpheus (para mantener consistencia)
const VICTORY_FONT_PATH: String = "res://fonts/morpheus.ttf"

func _ready():
	# Inicialización de la vida del Boss
	if is_instance_valid(boss_node):
		boss_node.vida_cambiada.connect(_actualizar_contador_vida)
		_actualizar_contador_vida(boss_node.vida_actual, boss_node.vida_maxima)
	else:
		print("ERROR: No se encontró el BossFinal con el nombre 'BossFinal'.")
		
	# INICIAMOS EL SPAWN DE MINIONS AL COMENZAR LA PELEA
	_iniciar_spawneo_minions()

func _actualizar_contador_vida(actual: int, maximo: int):
	# Función que se ejecuta cada vez que el boss recibe daño.
	if actual > 0:
		vida_boss_label.text = "BOSS HP: " + str(actual) + " / " + str(maximo)
	else:
		vida_boss_label.text = "¡JEFE DERROTADO!"
		
		# Detenemos el spawn si el boss muere
		if is_instance_valid(spawn_timer):
			spawn_timer.stop()
		

		if not is_game_over_sequence_active:
			_check_victory()


func _iniciar_spawneo_minions():
	# Creamos un Timer en código para mayor flexibilidad en el tiempo de espera
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	
	# Conectamos la señal de timeout a la función de spawn
	spawn_timer.timeout.connect(_spawnear_enemigo_aleatorio)
	
	# Establecemos el primer timeout aleatorio y lo iniciamos
	_establecer_siguiente_spawn_aleatorio()

func _establecer_siguiente_spawn_aleatorio():
	
	var tiempo_spawn = randf_range(2.0, 3.0) 
	
	spawn_timer.set_wait_time(tiempo_spawn)
	spawn_timer.set_one_shot(true) # Se reinicia en la función de spawn
	spawn_timer.start()

func _spawnear_enemigo_aleatorio():
	# Verificación de que el boss siga vivo
	if not is_instance_valid(boss_node) or boss_node.vida_actual <= 0:
		# Si el boss está muerto, ya no spawneamos y detenemos el timer.
		if is_instance_valid(spawn_timer):
			spawn_timer.stop()
		return

	# Seleccionar el enemigo aleatoriamente
	var enemigos = [escena_enemigo_volador, escena_enemigo, escena_enemigo_toro]
	var indice_aleatorio = randi() % enemigos.size()
	var escena_enemigo_a_spawnear = enemigos[indice_aleatorio]
	
	if not escena_enemigo_a_spawnear:
		print("ADVERTENCIA: Falta una escena de enemigo exportada.")
		_establecer_siguiente_spawn_aleatorio()
		return

	var nuevo_enemigo = escena_enemigo_a_spawnear.instantiate()
	
	# Determinar posición aleatoria
	var spawn_min_x = 200 
	var spawn_max_x = 800
	var spawn_min_y = 200
	var spawn_max_y = 200
	
	var pos_x = randf_range(spawn_min_x, spawn_max_x)
	var pos_y = randf_range(spawn_min_y, spawn_max_y)
	
	nuevo_enemigo.global_position = Vector2(pos_x, pos_y)
	
	# Añadir al árbol de la escena
	add_child(nuevo_enemigo)
	
	# Establecer el siguiente spawn
	_establecer_siguiente_spawn_aleatorio()


# --- LÓGICA DE VICTORIA ---

func _check_victory():
	# Evitar que se ejecute la secuencia dos veces
	if is_game_over_sequence_active:
		return
		
	# Damos un frame de gracia para que el BossFinal.gd haga queue_free()
	await get_tree().process_frame 
	
	# Contar enemigos restantes (minions y cualquier otro nodo "Enemigo")
	var enemigos_restantes = get_tree().get_nodes_in_group("Enemigo")
	
	if enemigos_restantes.is_empty():
		# ¡VICTORIA! Iniciar la secuencia final
		is_game_over_sequence_active = true
		_mostrar_mensaje_victoria()
		
		# Detenemos el monitor si estaba activo
		if is_instance_valid(victory_monitor_timer):
			victory_monitor_timer.queue_free()
			
	else:
		# Aún quedan minions: Configuramos un monitor para re-chequear
		if not is_instance_valid(victory_monitor_timer):
			victory_monitor_timer = Timer.new()
			add_child(victory_monitor_timer)
			victory_monitor_timer.set_wait_time(0.5)
			victory_monitor_timer.set_one_shot(false)
			victory_monitor_timer.timeout.connect(_check_victory)
			victory_monitor_timer.start()
		
		


func _mostrar_mensaje_victoria():
	# Crear el Label de Victoria
	var label = Label.new()
	label.text = "¡VICTORIA!"
	label.name = "VictoriaLabel"
	
	# Configuración de estilo
	var font_size = 80
	
	
	var font_resource = load(VICTORY_FONT_PATH)
	if font_resource is Font:
		var custom_font = FontVariation.new()
		custom_font.base_font = font_resource
		label.add_theme_font_override("font", custom_font)
	else:
		print("ADVERTENCIA: No se pudo cargar la fuente Morpheus en:", VICTORY_FONT_PATH)
		
	label.add_theme_font_size_override("font_size", font_size)
	
	
	label.add_theme_color_override("font_color", Color.WHITE) 
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	
	# Centrado en el Viewport
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Añadir a la capa de UI
	$CanvasLayer.add_child(label)
	
	# Timer de 3 segundos para la redirección
	var timer_redireccion = get_tree().create_timer(2.0)
	timer_redireccion.timeout.connect(_iniciar_fade_out)


# Inicia el efecto de desvanecimiento
func _iniciar_fade_out():
	# Crear el ColorRect (caja de color negro) para cubrir la pantalla.
	var fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Añadirlo al CanvasLayer, asegurando que esté por encima de todo.
	$CanvasLayer.add_child(fade_rect)
	
	var fade_duration = 3.0 # Duración del desvanecimiento a negro
	var tween = create_tween()
	

	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), fade_duration)
	
	# 5. Una vez que el fade termine, redirigir a Game Over.
	tween.tween_callback(_redirigir_a_game_over)
	
	
	var label = find_child("VictoriaLabel")
	if is_instance_valid(label):
		label.queue_free()


func _redirigir_a_game_over():
	# Aseguramos que la caja de fade se borre si aún existe
	var fade_rect = find_child("FadeRect")
	if is_instance_valid(fade_rect):
		fade_rect.queue_free()

	# Detención de la música
	if is_instance_valid(Audio):
		Audio.detener_musica() 

	# Si se ganó y el escudo estaba en el inventario, se elimina
	if Global.inventario.has("Escudo"):
		Global.inventario.erase("Escudo")
		# Notificar al HUD que remueva el ícono
		if is_instance_valid(HUD):
			HUD.remover_item() 
		print("Escudo eliminado del inventario global al ir a Game Over (Victoria).")
		
	# Redirigir a Game Over
	get_tree().paused = true
	get_tree().change_scene_to_file(GAME_OVER_SCENE)
