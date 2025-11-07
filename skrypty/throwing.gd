extends Module

var can_throw : bool = true
#Scena petardy
var petarda=preload("res://sceny/petarda.tscn")
#Timer, opóźnienia
@onready var throw_timer: Timer = $"../../ThrowTimer"

@export var eyes : Node3D
@export var camera : Camera3D

@export var MAX_PETARDS : int = 3

@export var cross :Control
@export var ray_check: bool = true    # czy dodatkowo sprawdzać widoczność raycastem
@export var ray_padding: float = 0.0  # jeśli chcesz "wewnętrzny" margines
#Lista wyrzuconych petard
var thrown_petards: Array = [] 

var aiming_active : bool = false
var delta_mock :float = 0.016
@export var cursor_follow_speed : float
@export var cursor_mass: float = 0.25
@export var cursor_damping: float = 6.0 
var konc_value : float = 0.000
var cursor_velocity: Vector2 = Vector2.ZERO

@export var look_speed: float = 4.0         # im większe, tym szybciej dogania (np. 2..8)
@export var overshoot_distance: float = 0.8 # jak bardzo "wychodzi za" target (jednostki świata)
@export var up_vector: Vector3 = Vector3.UP

var trauma_reduction_rate = 0.02
var noise : FastNoiseLite = FastNoiseLite.new()
var noise_speed = 3.0

var trauma = 0.0

var time = 0.0

var max_x : float = 10.0
var max_y : float = 10.0
var max_z : float = 5.0

var initial_rotation : Vector3 = Vector3.ZERO
var og_fov

@export var PB :ProgressBar 
@onready var znacznik_scene = preload("res://sceny/znacznik.tscn")
var throw_ray
func Enter():
	player = get_parent().player
	player.mouse_block = false
	player.movement_block = true
	initial_rotation = camera.rotation_degrees
	og_fov = camera.fov
	PB.value = 100.0
	cross.get_node("Holder").scale = Vector2(1.0,1.0)
	trauma=0.0
	trauma_reduction_rate = 0.02
	cursor_velocity = Vector2(0.0,0.0)
func PhysicsUpdate(delta):
	time += delta
	if aiming_active:
		update_cursor_pos(delta)
		check_if_pucha_is_in_cursor()
		update_screen_shake(delta)
		PB.value -= 0.25
		if PB.value <= 0.0:
			aiming_active = false
			player.mouse_block = false
			player.camera_update_block = false
			select_target()
			player.eyes.rotation = Vector3(0,0,0)
			player.camera.rotation = Vector3.ZERO
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			cross.get_parent().hide()
			
	if Input.is_action_just_pressed("throw") and !aiming_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		add_trauma(2.0)
		cross.get_parent().show()
		aiming_active = true
		player.mouse_block = true
		player.camera_update_block = true
		cursor_velocity = Vector2(randf_range(1000,1500.0)*randf_range(-1.0,1.0),randf_range(1000,1500.0)*randf_range(-1.0,1.0))
	
	
func check_if_pucha_is_in_cursor():
	if not camera or not cross or not Global.pucha:
		return
	var world_pos : Vector3 = Global.pucha.global_position
	var screen_pos : Vector2 = camera.unproject_position(world_pos)
	
	var cursor_rect : Rect2
	if cross.has_method("get_global_rect"):
		cursor_rect = cross.get_node("Holder").get_global_rect()
	else:
		cursor_rect = Rect2(cross.get_global_position(), cross.rect_size) 

	if ray_padding != 0.0:
		cursor_rect = Rect2(
			cursor_rect.position + Vector2(ray_padding, ray_padding),
			cursor_rect.size - Vector2(ray_padding * 2.0, ray_padding * 2.0)
		)
	
	var in_cursor = cursor_rect.has_point(screen_pos)
	if in_cursor:
		# dodatkowy check: obiekt może być za kamerą (zwróć uwagę: y < 0 itp.)
		# Warto sprawdzić, czy screen_pos leży wewnątrz viewportu
		var vp_size = get_viewport().get_visible_rect().size
		if screen_pos.x < 0 or screen_pos.y < 0 or screen_pos.x > vp_size.x or screen_pos.y > vp_size.y:
			in_cursor = false
	if in_cursor:
		update_cursor_scale()
		point_to_pucha()
		konc_value += 0.0002
	
	
func point_to_pucha():
	# 1) kierunek do celu
	var dir: Vector3 = (Global.pucha.global_position - eyes.global_position)
	if dir.length() == 0:
		return
	dir = dir.normalized()

	# 2) policz docelową orientację jako Euler z looking_at (tymczasowy Basis tylko do obliczeń)
	var tmp_basis: Basis = Basis().looking_at(dir, Vector3.UP)
	var target_euler: Vector3 = tmp_basis.get_euler()  # Vector3 w radianach

	# 3) obecne kąty (global_rotation)
	var current_euler: Vector3 = eyes.global_rotation

	# 4) interpolacja kątów z uwzględnieniem zawijania (lerp_angle)
	var t = clamp(delta_mock * 0.5, 0.0, 1.0)
	var new_euler := Vector3()
	new_euler.x = lerp_angle(current_euler.x, target_euler.x, t)
	new_euler.y = lerp_angle(current_euler.y, target_euler.y, t)
	new_euler.z = lerp_angle(current_euler.z, target_euler.z, t)

	# 5) ustaw wynik (tylko rotation)
	eyes.global_rotation = new_euler

	# 6) fov
	if camera.fov > 20.0:
		camera.fov -= 0.1
	
func update_screen_shake(delta: float)-> void:
	var noise_x = get_noise_from_seed(0) * 10
	var noise_y = get_noise_from_seed(1)* 10
	trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	camera.rotation_degrees.x = lerp(camera.rotation_degrees.x, initial_rotation.x + max_x * get_shake_intensity() * noise_x, delta)
	camera.rotation_degrees.y = lerp(camera.rotation_degrees.y, initial_rotation.y + max_y * get_shake_intensity() * noise_y, delta)

func add_trauma(trauma_amount : float):
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(_seed : int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noise_speed)

func update_cursor_scale() -> void:
	if not cross:
		return
	var target_scale = cross.get_node("Holder").scale - Vector2(0.002,0.002)
	cross.get_node("Holder").get_node("TextureRect").rotation += 0.005 + konc_value
	# jeśli już jesteśmy w tej skali — nic nie rób
	if cross.get_node("Holder").scale == target_scale or target_scale < Vector2(0.2,0.2):
		return
	
	cross.get_node("Holder").scale = target_scale
func _on_throw_timer_timeout() -> void:
	if camera.fov>40.0:
		add_trauma(camera.fov/og_fov *1.6)
		trauma_reduction_rate = 0.9-camera.fov/og_fov

func update_cursor_pos(delta: float) ->	 void:
	if not cross:
		return

	# pozycja myszy względem viewportu (piksele)
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	# bieżąca globalna pozycja kontrolki (CanvasItem/Control)
	var cur_pos: Vector2 = cross.global_position

	# exponential smoothing: factor zależny od delta i speed (frame-rate niezależne)
	var force: Vector2  = (mouse_pos - cur_pos) / max(cursor_mass, 0.001)

	# aktualizacja prędkości (ruch + tłumienie)
	cursor_velocity += force * delta
	cursor_velocity -= cursor_velocity * cursor_damping * delta

	# aktualizacja pozycji
	cross.position += cursor_velocity * delta


func select_target():

	var random_point = cross.get_node("Holder").global_position
	
	print(random_point)
	# teraz przekształcamy punkt ekranowy -> promień w świecie 3D
	var from: Vector3 = camera.project_ray_origin(random_point)
	var dir: Vector3 = camera.project_ray_normal(random_point)

	# przykładowa długość promienia
	var to: Vector3 = from + dir * 1000.0

	
	# jeśli chcesz natychmiast wykonać raycast (np. sprawdzić co trafia):
	var space_state = camera.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

	if result:
		throw(dir)
		print("Hit object:", result.collider, " at ", result.position)
		var debug_znacznik_instance = znacznik_scene.instantiate()
		cross.get_parent().add_child(debug_znacznik_instance)
		debug_znacznik_instance.global_position = random_point
	else:
		print("No hit, ray went into empty space")
	

func throw(dir: Vector3):
	var throw_instance = petarda.instantiate()
	throw_instance.position = player.throw_point.global_position
	get_tree().current_scene.add_child(throw_instance)

	# siła rzutu i kierunek
	var force: float = 18.0   # dodatni, bo dir już wskazuje "do przodu" od kamery
	var up_direction: float = 2.5

	# dodaj trochę "podrzutu" w osi Y
	var final_dir = dir.normalized() * force + Vector3(0, up_direction, 0)

	# nadaj impuls (zakładam, że petarda to RigidBody3D)
	throw_instance.apply_central_impulse(final_dir)
	
	
