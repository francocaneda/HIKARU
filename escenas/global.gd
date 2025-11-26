extends Node

var puntuacion_actual := 0
var posicion_jugador: Vector2 = Vector2.ZERO
# Inventario persistente (Array para guardar strings de items)
var inventario: Array = []

func guardar_juego():
	var datos = {
		"posicion_jugador": posicion_jugador,
		"puntuacion": puntuacion_actual,
		# Guardamos el inventario
		"inventario": inventario
	}
	
	var file = FileAccess.open("user://guardado.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(datos))
		file.close()
		print("Juego guardado!")

func cargar_juego():
	if FileAccess.file_exists("user://guardado.json"):
		var file = FileAccess.open("user://guardado.json", FileAccess.READ)
		if file:
			# Parsear con seguridad
			var result = JSON.parse_string(file.get_as_text())
			file.close()
			
			if result.error == OK:
				var datos = result.result
				
				posicion_jugador = datos.get("posicion_jugador", Vector2.ZERO)
				puntuacion_actual = datos.get("puntuacion", 0)
				# Cargamos el inventario, con fallback a Array vacío
				inventario = datos.get("inventario", [])
				
				print("Juego cargado:", datos)
			else:
				print("ERROR: Fallo al parsear el archivo de guardado.")
