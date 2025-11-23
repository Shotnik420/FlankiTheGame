extends Module

#Scena petardy
var petarda=preload("res://sceny/mesh_instances/kamien.tscn")
#Timer, opóźnienia
@onready var throw_timer: Timer = $"../../ThrowTimer"

@export var eyes : Node3D
@export var camera : Camera3D

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

var trauma_reduction_rate = 0.005
var noise : FastNoiseLite = FastNoiseLite.new()
var noise_speed = 3.0

var trauma = 0.0

var time = 0.0

var max_x : float = 5.0
var max_y : float = 5.0
var max_z : float = 5.0

var initial_rotation : Vector3 = Vector3.ZERO
var og_fov

@export var PB :ProgressBar 
@onready var znacznik_scene = preload("res://sceny/hud/znacznik.tscn")
var throw_strength : float = 0.0
@export var throw_strength_pb : ProgressBar

var mouse_pos : Vector2 = Vector2.ZERO

var failure_timer : int = 220
var thrown : bool = false

@export var random_throw : bool = false
func Enter():
	Global.throw_tried = false
	player = get_parent().player
	player.mouse_block = false
	player.movement_block = true
	initial_rotation = camera.rotation_degrees
	og_fov = camera.fov
	PB.value = 100.0
	cross.get_node("Holder").scale = Vector2(1.0,1.0)
	trauma=0.0
	trauma_reduction_rate = 0.005
	cursor_velocity = Vector2(0.0,0.0)
	cross.position = Vector2(400,180)
	throw_strength_pb.value = 0.0
	konc_value = 0.0
	mouse_pos = Vector2(get_viewport().get_visible_rect().size.x/2,get_viewport().get_visible_rect().size.y/2)
	print("MOUSE POS ", mouse_pos, "  VIEWPORT:   ", get_viewport().get_visible_rect().size)
	failure_timer = 220
	thrown = false

func handle_mouse(x,y):
	mouse_pos += Vector2(x*0.3,y*0.3)

func PhysicsUpdate(delta):
	time += delta
	if aiming_active:
		update_cursor_pos(delta)
		check_if_pucha_is_in_cursor()
		update_screen_shake(delta)
		PB.value -= 0.20
		throw_strength_handling()
		if PB.value <= 0.0:
			aiming_active = false
			
			player.mouse_block = false
			player.camera_update_block = false
			select_target()
			await get_tree().create_timer(0.4,false).timeout
			player.eyes.rotation = Vector3(0,0,0)
			player.camera.rotation = Vector3.ZERO
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			cross.get_parent().hide()
			
			
	if Input.is_action_just_pressed("throw") and !aiming_active:
		add_trauma(3.0)
		cross.get_parent().show()
		aiming_active = true
		player.mouse_block = true
		player.camera_update_block = true
		
		var rand_x = randf_range(300.0,600.0) *  sign(randi_range(-1,1))
		var rand_y = randf_range(300.0,600.0) *  sign(randi_range(-1,1))
		
		mouse_pos = Vector2(randf_range(200.0,900.0), randf_range(100.0,430.0))
		
		cursor_velocity = Vector2(rand_x,rand_y)
		print(rand_x, rand_y)
	if thrown:
		if failure_timer >0:
			failure_timer -= 1
		else:
			Global.get_next_step()
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
	if trauma > 0.005:
		trauma -= 0.005
	
func update_screen_shake(delta: float)-> void:
	var noise_x = get_noise_from_seed(0) * 10
	var noise_y = get_noise_from_seed(1)* 10
	trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	camera.rotation_degrees.x = lerp(camera.rotation_degrees.x, initial_rotation.x + max_x * get_shake_intensity() * noise_x, delta)
	camera.rotation_degrees.y = lerp(camera.rotation_degrees.y, initial_rotation.y + max_y * get_shake_intensity() * noise_y, delta)

func add_trauma(trauma_amount : float):
	trauma = clamp(trauma + trauma_amount, 0.0, 1.5)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(_seed : int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noise_speed)

func update_cursor_scale() -> void:
	if not cross:
		return
	var target_scale = cross.get_node("Holder").scale - Vector2(0.0023,0.0023)
	cross.get_node("Holder").get_node("TextureRect").rotation += 0.006 + konc_value
	# jeśli już jesteśmy w tej skali — nic nie rób
	if cross.get_node("Holder").scale == target_scale or target_scale < Vector2(0.2,0.2):
		return
	
	cross.get_node("Holder").scale = target_scale

func update_cursor_pos(delta: float) ->	 void:
	if not cross:
		return

	# pozycja myszy względem viewportu (piksele)
	

	# bieżąca globalna pozycja kontrolki (CanvasItem/Control)
	var cur_pos: Vector2 = cross.global_position

	# exponential smoothing: factor zależny od delta i speed (frame-rate niezależne)
	var force: Vector2  = (mouse_pos - cur_pos) / max(cursor_mass, 0.001)
	#print("FUH   ",mouse_pos, "   ", cur_pos )
	# aktualizacja prędkości (ruch + tłumienie)
	cursor_velocity += force * delta
	cursor_velocity -= cursor_velocity * cursor_damping * delta
	#print(cursor_velocity, "  ", force)
	# aktualizacja pozycji
	cross.position += cursor_velocity * delta


func select_target():
	var texture_rect = cross.get_node("Holder")
	var exact_point = texture_rect.get_screen_position() + (texture_rect.size / 2) * texture_rect.scale
	if random_throw:
		var rand_x = randf_range((-1)*(texture_rect.size.x / 2) * (texture_rect.scale.x-0.19), (texture_rect.size.x / 2) * (texture_rect.scale.x -0.19))
		var rand_y = randf_range((-1)*(texture_rect.size.y / 2) * (texture_rect.scale.y-0.19), (texture_rect.size.y / 2) * (texture_rect.scale.y -0.19))
		
		exact_point.x += rand_x
		exact_point.y += rand_y
	var znacznik_ins = znacznik_scene.instantiate()
	cross.get_parent().get_parent().add_child(znacznik_ins)
	znacznik_ins.global_position = exact_point
	
	# teraz przekształcamy punkt ekranowy -> promień w świecie 3D
	var from = camera.project_ray_origin(exact_point)
	var dir = camera.project_ray_normal(exact_point)

	# przykładowa długość promienia
	var to: Vector3 = from + dir * 1000.0
	# jeśli chcesz natychmiast wykonać raycast (np. sprawdzić co trafia):
	var space_state = camera.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	var target_pos: Vector3
	if result:
		target_pos = result.position
	else:
		target_pos = to # w razie braku trafienia — daleko w przód

	# Teraz policz dokładny kierunek od miejsca rzutu (ręki) do celu
	var throw_origin = player.throw_point.global_position
	var throw_dir = (target_pos - throw_origin).normalized()
	throw(throw_dir)


func throw(dir: Vector3):
	Global.throw_tried = true
	var throw_instance : RigidBody3D = petarda.instantiate()
	throw_instance.position = player.throw_point.global_position
	get_tree().current_scene.add_child(throw_instance)

	# siła rzutu i kierunek
	var force: float = throw_strength_pb.value/4
	if force == 0.0:
		force = 1.0
	var up_direction: float = 2.5
	
	# dodaj trochę "podrzutu" w osi Y
	var final_dir = dir.normalized() * force + Vector3(0, up_direction, 0)

	# nadaj impuls (zakładam, że petarda to RigidBody3D)
	throw_instance.apply_central_impulse(final_dir)
	throw_instance.angular_velocity = Vector3(randf_range(-10.0,10.0),randf_range(-10.0,10.0),randf_range(-10.0,10.0))
	
	thrown = true


func throw_strength_handling():
	if Input.is_action_pressed("mouseone"):
		throw_strength_pb.value += 1.0
	if Input.is_action_just_released("mouseone"):
		PB.value = 0.0
