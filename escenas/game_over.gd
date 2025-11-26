# GameOver.gd
extends ColorRect

@onready var volver_a_jugar_boton: Button = $VBoxContainer/VolverAJugar
@onready var salir_boton: Button = $VBoxContainer/Salir
@onready var musica_game_over: AudioStreamPlayer = $MusicaGameOver
@onready var sonido_seleccion: AudioStreamPlayer = $VBoxContainer/SonidoSeleccion


func _ready():
	# Registra la musica de la escena con el sistema de audio global.
	Audio.registrar_musica(musica_game_over)

	volver_a_jugar_boton.focus_entered.connect(_on_boton_focused)
	salir_boton.focus_entered.connect(_on_boton_focused)
	
	# Aseguramos que el juego no este pausado
	get_tree().paused = false
	
	# Accion para volver a jugar
	volver_a_jugar_boton.grab_focus()
	
	Audio.iniciar_musica_de_escena(musica_game_over)

func _on_volver_a_jugar_pressed():
	# Cambia a la escena principal del juego (el nivel o la Sala)
	get_tree().change_scene_to_file("res://escenas/Sala.tscn")
	
func _on_salir_pressed():
	# Cierra el juego
	get_tree().quit()

func _on_boton_focused():
	sonido_seleccion.play()
