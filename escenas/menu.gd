extends Control

@onready var boton_jugar: Button = $VBoxContainer/Jugar
@onready var boton_sonido: Button = $VBoxContainer/Sonido
@onready var boton_salir: Button = $VBoxContainer/Salir
@onready var musica_menu: AudioStreamPlayer = $MusicaMenu
@onready var sonido_seleccion: AudioStreamPlayer = $VBoxContainer/SonidoSeleccion

func _ready():
	# Registra la musica del menu en el sistema de audio global.
	Audio.registrar_musica(musica_menu)
	
	boton_jugar.focus_entered.connect(_on_boton_focused)
	boton_sonido.focus_entered.connect(_on_boton_focused)
	boton_salir.focus_entered.connect(_on_boton_focused)
	
	boton_jugar.grab_focus()

func _on_jugar_pressed():
	get_tree().change_scene_to_file("res://escenas/Sala.tscn")

func _on_sonido_pressed():
	# El boton solo llama a la funcion de audio global.
	Audio.toggle_musica()

func _on_salir_pressed():
	get_tree().quit()

func _on_boton_focused():
	sonido_seleccion.play()
