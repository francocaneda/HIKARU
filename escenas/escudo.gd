extends Area2D

# Exporta la textura del icono para que se pueda asignar en el Inspector.
@export var icono: Texture2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# Usamos is_in_group para una comprobación más robusta.
	if body.is_in_group("Jugador") or body.name == "Jugador": 
		
		# Agrega el item y ejecuta cualquier lógica de spawn asociada (en Jugador.gd).
		body.agregar_item("Escudo")
		
		# Llamamos a la función del HUD para que muestre el ícono.
		HUD.mostrar_item(icono)
		
		# El escudo desaparece de la escena.
		queue_free()
