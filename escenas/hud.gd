# HUD.gd
extends CanvasLayer

@onready var icono_objeto_1: TextureRect = $IconoObjeto1
@onready var icono_objeto_2: TextureRect = $IconoObjeto2
@onready var icono_objeto_3: TextureRect = $IconoObjeto3
@onready var icono_objeto_4: TextureRect = $IconoObjeto4

var iconos_del_inventario = []
var contador_objetos: int = 0

func _ready():
	iconos_del_inventario = [icono_objeto_1, icono_objeto_2, icono_objeto_3, icono_objeto_4]
	esconder_todos_los_iconos()
	
func esconder_todos_los_iconos():
	for icono in iconos_del_inventario:
		icono.hide()

func mostrar_item(textura_del_objeto: Texture2D):
	if contador_objetos < iconos_del_inventario.size():
		var icono_a_mostrar = iconos_del_inventario[contador_objetos]
		icono_a_mostrar.texture = textura_del_objeto
		icono_a_mostrar.show()
		contador_objetos += 1

func resetear_inventario():
	esconder_todos_los_iconos()
	contador_objetos = 0

func remover_item():
	
	if contador_objetos > 0:
		# Retrocede el contador y oculta el último slot utilizado (el escudo)
		contador_objetos -= 1
		iconos_del_inventario[contador_objetos].hide()
		iconos_del_inventario[contador_objetos].texture = null 
		
		print("Escudo removido del HUD.")
	else:
		print("Error: No hay objetos para remover del HUD.")
