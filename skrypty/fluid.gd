extends Node2D
@export var k : float = 0.015
@export var d : float = 0.03
@export var spread : float = 0.0002
@onready var springs_node = $Springs
var springs = []

var passes = 8

@export var distance_between_springs = 32 
@export var spring_number = 6
@export var depth = 1000
var target_height = global_position.y
var bottom = target_height + depth

@onready var water_spring = preload("res://sceny/water_spring.tscn")
@onready var water_polygon = $water_polygon

@export var bordert_thickness = 1.1
@onready var water_border = $Line2D
func _ready() -> void:
	for i in range(spring_number):
		var x_position = distance_between_springs * i
		var w = water_spring.instantiate()
		
		springs_node.add_child(w)
		springs.append(w)
		w.initialize(x_position)

func PhysicsUpdate(_delta: float) -> void:
	for i in springs:
		i.water_update(k,d)
	var left_deltas = []
	var right_deltas = []

	for i in range(springs.size()):
		left_deltas.append(0)
		right_deltas.append(0)
		pass
	for j in range(passes):
		for i in range(springs.size()):
			if i > 0:
				left_deltas[i] = spread*(springs[i].height - springs[i-1].height)
				springs[i-1].velocity += left_deltas[i]
			if i < springs.size()-1:
				right_deltas[i] = spread * (springs[i].height - springs[i+1].height)
				springs[i+1].velocity += right_deltas[i]
	
	draw_water_body()
func splash(index, speed):
	if index >=0 and index < springs.size():
		springs[index].velocity += speed
func draw_water_body():
	var surface_points = []
	
	for i in range(springs.size()):
		surface_points.append(springs[i].position)
	# --- Wygładzanie powierzchni ---
	var smoothed_points = []
	for i in range(surface_points.size()):
		var prev = surface_points[clamp(i - 1, 0, surface_points.size() - 1)]
		var curr = surface_points[i]
		var next = surface_points[clamp(i + 1, 0, surface_points.size() - 1)]
		
		# Prosty smoothing: punkt przesunięty w stronę średniej z sąsiadów
		var smooth_point = (prev + curr * 2 + next) / 4.0
		smoothed_points.append(smooth_point)
	
	var first_index = 0
	var last_index = smoothed_points.size() - 1
	
	var water_polygon_points = smoothed_points.duplicate()
	
	# Dodaj dolne punkty, by zamknąć kształt
	water_polygon_points.append(Vector2(smoothed_points[last_index].x, bottom))
	water_polygon_points.append(Vector2(smoothed_points[first_index].x, bottom))
	
	water_polygon_points = PackedVector2Array(water_polygon_points)
	
	water_polygon.set_polygon(water_polygon_points)
	new_border(smoothed_points)
func new_border(points):
	var line = PackedVector2Array()
	
	var surface_points = []
	for i in range(springs.size()):
		surface_points.append(points[i])
	for i in range(surface_points.size()):
		line.append(surface_points[i])
	
	water_border.points = line


func _on_line_took_sip(value) -> void:
	var tween_down = get_tree().create_tween().set_parallel(true).set_ease(Tween.EASE_IN)
	
	tween_down.tween_property(self, "position:y",position.y+value,0.3)
	var spring_half = spring_number/2
	splash(spring_half,10)
	splash(spring_half-2, 5)
	splash(spring_half-1, 8)
	splash(spring_half+1, 8)
	splash(spring_half+2, 5)
	for i in range(3):
		splash(randi()%(springs.size()-1), randi_range(0, 10))
	await tween_down.finished
	tween_down.kill()
