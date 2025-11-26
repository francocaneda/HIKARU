extends Area2D

@export var velocidad: float = 600.0
@export var distancia_max: float = 250.0
@export var distancia_minima: float = 80.0
@export var offset: float = 90.0

var jugador: Node2D = null
var direccion: Vector2 = Vector2.ZERO
var lanzada: bool = false
var regresando: bool = false
var distancia_recorrida: float = 0.0

@onready var sonido_lanzar: AudioStreamPlayer = $SonidoLanzar

func _ready():
	self.body_entered.connect(_on_Espada_body_entered)

	show() 

func lanzar(pos_inicial: Vector2, dir: Vector2, jugador_ref: Node2D) -> void:
	global_position = pos_inicial
	direccion = dir.normalized()
	jugador = jugador_ref
	lanzada = true
	regresando = false
	distancia_recorrida = 0.0
	set_physics_process(true)
	rotation = direccion.angle()
	

	show() 
	
	# Reproduce el sonido cuando la espada es lanzada
	sonido_lanzar.play()
	
func _physics_process(delta: float) -> void:
	if not is_instance_valid(jugador):
		_finish()
		return

	if not lanzada:
		# Lógica para pegar la espada al jugador
		var dir_jugador: Vector2 = jugador.direccion_mirada
		var pos_offset = dir_jugador * offset
		global_position = jugador.global_position + pos_offset
		rotation = dir_jugador.angle()
	else:
		if not regresando:
			var movimiento = direccion * velocidad * delta
			global_position += movimiento
			distancia_recorrida += movimiento.length()
			
			if distancia_recorrida >= distancia_max:
				regresando = true
		else:
			var hacia_jugador = jugador.global_position - global_position
			var dist = hacia_jugador.length()
			
			if dist > distancia_minima:
				global_position += hacia_jugador.normalized() * velocidad * delta
			else:
				_finish()

func _finish() -> void:
	lanzada = false
	regresando = false

	
func _on_Espada_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemigo"):
		
		# LÓGICA DE DAÑO CONDICIONAL
		if body is BossFinal:
			body.recibir_danio(1) 
			regresando = true
			
		else:
			body.morir()
