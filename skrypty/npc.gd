extends CharacterBody3D
class_name Npc

const SPEED : float = 4.0

@export var pucha : Node3D
@export var puszka_point : Node3D

@onready var nav_agent = $NavigationAgent3D
@onready var state_machine = $StateMachine

@onready var anim_tree = $AnimationTree

@onready var throw_point = $ThrowPoint

@onready var kamien_scene = preload("res://sceny/kamien.tscn")

enum NpcStates{
	WAIT,
	CHASE,
	DRINK,
	THROW
}

signal stop

var can_walk : bool = false
var goforpucha : bool = true
var spawn_point : Vector3 = Vector3.ZERO
var has_puszka : bool = false

var current_item : Item

func _ready() -> void:
	spawn_point = global_position
func walk():
	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	var new_vel = direction * SPEED
	
	var target_rotation = Vector3(0, atan2(direction.x, direction.z), 0)
	rotate_to_target(target_rotation)
	
	if nav_agent.avoidance_enabled:
		can_walk = true
		nav_agent.velocity = new_vel
	else:
		velocity = velocity.move_toward(new_vel, 100)
		if !nav_agent.is_target_reached():
			move_and_slide()

func set_target_pos(pos : Vector3):
	nav_agent.target_position = pos
	if !nav_agent.is_target_reachable():
		nav_agent.target_position = nav_agent.get_final_position()

func rotate_to_target(target):
	rotation = rotation.lerp(target, 0.1)


func _on_interact_spawned_pucha(prop) -> void:
	assign_pucha(prop)


func _on_puszka_puszka_przewrocona() -> void:
	if pucha and Global.current_game_state==Global.Game_State.PlayerThrow:
		can_walk = true

func change_anim_branch(bname: String) -> void:
	anim_tree.set("parameters/Transition/transition_request", bname)
	anim_tree.set("parameters/TimeSeek/seek_request", 0.0)
func change_state_machine_condition(condition : String, value : bool):
	anim_tree.set("parameters/StateMachine/conditions/"+condition, value)

func spawn_n_throw():
	var kamien = kamien_scene.instantiate()
	get_tree().root.add_child(kamien)
	kamien.global_position = throw_point.global_position
	throw_at_target(kamien, pucha.global_position, 16.0, true,0.0,30.0)

# DODAJ to do swojego skryptu (Godot 4.5)
# Funkcja pomocnicza: oblicza wymagane v (szybkość) dla zadanego kąta (w radianach).
# Zwraca: v_required (float) lub -1.0 jeśli nierozwiązywalne (np. denom <= 0).
func _required_speed_for_angle(x: float, y: float, angle_rad: float, g: float) -> float:
	var tan_theta = tan(angle_rad)
	var cos_theta = cos(angle_rad)
	var cos2 = cos_theta * cos_theta
	var denom = 2.0 * cos2 * (x * tan_theta - y)
	if denom <= 0.0:
		return -1.0
	var v2 = g * x * x / denom
	if v2 <= 0.0:
		return -1.0
	return sqrt(v2)

# Funkcja: rzuca rigidbody tak, żeby trafić target, ale ogranicza kąt wyrzutu.
# rigidbody - RigidBody3D, target_pos - Vector3, max_speed - float
# prefer_high_arc - ignorujemy (zawsze preferujemy niską trajektorię), use_impulse zgodnie z wcześniejszym kodem
# max_angle_deg - maksymalny kąt elewacji (np. 45.0) — jeżeli obliczony kąt będzie większy, spróbujemy zwiększyć speed
func throw_at_target(rigidbody: RigidBody3D, target_pos: Vector3, max_speed: float, use_impulse: bool = false, spin_strength: float = 0.0, max_angle_deg: float = 45.0, gravity_mag_override: float = 0.0) -> bool:
	if not rigidbody or max_speed <= 0.0:
		return false

	var origin = rigidbody.global_transform.origin
	var to_target = target_pos - origin
	var to_target_xz = Vector3(to_target.x, 0.0, to_target.z)
	var x = to_target_xz.length()
	var y = to_target.y

	# grawitacja (dodatnia)
	var g: float = gravity_mag_override if gravity_mag_override > 0.0 else (ProjectSettings.get_setting("physics/3d/default_gravity") if ProjectSettings.has_setting("physics/3d/default_gravity") else 9.8)

	var EPS := 0.000001
	if x <= EPS:
		# pionowy rzut - prosty fallback
		var dir_y := 1.0 if y >= 0.0 else -1.0
		var vel := Vector3(0, dir_y * max_speed, 0)
		_apply_velocity_or_impulse_correct(rigidbody, vel, use_impulse, Vector3.ZERO, spin_strength)
		return true

	# --- 1) Spróbuj policzyć klasycznie DWA rozwiązania kąta dla podanej prędkości (low i high) ---
	var v2 = max_speed * max_speed
	var v4 = v2 * v2
	var under_sqrt = v4 - g * (g * x * x + 2.0 * y * v2)
	if under_sqrt < 0.0:
		# nawet przy podanym max_speed nie da się trafić
		return false

	var sqrt_val = sqrt(under_sqrt)
	var denom = g * x
	# tan dla dwóch rozwiązań:
	var tan_low = (v2 - sqrt_val) / denom
	var tan_high = (v2 + sqrt_val) / denom

	# zabezpieczenie: wybieramy niską trajektorię jeśli sensowna (tan_low >= 0) inaczej high
	var chosen_tan = tan_low if tan_low >= 0.0 else tan_high
	var angle_rad = atan(chosen_tan)

	# --- 2) Jeśli kąt jest za duży, zastosuj limit kąta ---
	var max_angle_rad = deg_to_rad(max_angle_deg)
	if angle_rad > max_angle_rad:
		# oblicz wymaganą prędkość dla kąta = max_angle_rad
		var req_speed = _required_speed_for_angle(x, y, max_angle_rad, g)
		if req_speed < 0.0:
			# nie da się trafić pod tym kątem (np. y zbyt duże) -> zwróć false
			return false
		# jeżeli wymagana prędkość jest większa niż max_speed -> nie spełnisz ograniczenia
		# (użytkownik podał max_speed, a żeby trafic z małym kątem potrzeba większej prędkości)
		# Możesz tu wybrać: użyć max_speed i zaakceptować wysoki łuk, albo zwrócić false.
		# Tutaj wybieramy: jeśli req_speed <= max_speed użyjemy req_speed, inaczej zwrócimy false (bez wysokiego łuku).
		if req_speed > max_speed:
			return false
		# Użyj obliczonej prędkości i kąta = max_angle_rad
		var used_speed = req_speed
		var cos_t = cos(max_angle_rad)
		var sin_t = sin(max_angle_rad)
		var dir_xz = to_target_xz.normalized()
		var vel_h = used_speed * cos_t
		var vel_v = used_speed * sin_t
		var vel = dir_xz * vel_h
		vel.y = vel_v
		_apply_velocity_or_impulse_correct(rigidbody, vel, use_impulse, Vector3.ZERO if spin_strength == 0.0 else (dir_xz.cross(Vector3.UP).normalized() * spin_strength + Vector3(0, -0.2 * clamp(spin_strength, 0.1, 1.0), 0)), spin_strength)
		return true
	else:
		# kąt w porządku — użyj obliczonego low-angle rozwiązania i pełnej prędkości max_speed
		# oblicz współczynniki cos/sin z tan:
		var cos_theta = 1.0 / sqrt(1.0 + chosen_tan * chosen_tan)
		var sin_theta = chosen_tan * cos_theta
		var dir_xz = to_target_xz.normalized()
		var vel_horizontal_mag = max_speed * cos_theta
		var vel_vertical = max_speed * sin_theta
		var initial_velocity = dir_xz * vel_horizontal_mag
		initial_velocity.y = vel_vertical
		_apply_velocity_or_impulse_correct(rigidbody, initial_velocity, use_impulse, Vector3.ZERO if spin_strength == 0.0 else (dir_xz.cross(Vector3.UP).normalized() * spin_strength + Vector3(0, -0.2 * clamp(spin_strength, 0.1, 1.0), 0)), spin_strength)
		return true


# Poprawiona funkcja aplikująca velocity/impuls
func _apply_velocity_or_impulse_correct(rigidbody: RigidBody3D, vel: Vector3, use_impulse: bool, offset: Vector3, spin_strength: float) -> void:

	# "Obudź" ciało, żeby natychmiast reagowało
	rigidbody.sleeping = false

	# Wyłącz duże tłumienie jeśli chcesz widoczny spin
	if rigidbody.angular_damp > 2.0:
		# opcjonalnie: zmniejsz damping na chwilę
		rigidbody.angular_damp = min(rigidbody.angular_damp, 2.0)

	# Jeśli chcesz deterministyczny efekt — ustaw linear_velocity
	if not use_impulse:
		rigidbody.linear_velocity = vel
		# jeśli chcesz od razu też obrócić obiekt (np. dodać angular velocity), można:
		if spin_strength > 0.0:
			# prosta metoda: daj angular_velocity (możesz tweakować wartości)
			var ang := Vector3(randf(), randf(), randf()).normalized() * spin_strength * 2.0
			rigidbody.angular_velocity = ang
		return

	# Jeśli używamy impulse -> oblicz impulse tak, by Δv = desired - current
	var current_v := rigidbody.linear_velocity
	var dv := vel - current_v
	# mass: bezpieczne pobranie (w Godot 4 RigidBody3D ma property .mass)
	var mass := 1.0
	if Engine.has_singleton("PhysicsServer"): # tylko by uniknąć niepewności, normalnie rigidbody.mass istnieje
		pass
	# bezpośrednio użyj rigidbody.mass (powinno istnieć)
	mass = rigidbody.mass if rigidbody.mass else mass

	var impulse := dv * mass

	# Jeśli offset jest niemal zerowy, użyj centralnego impulsu
	if offset.length_squared() <= 0.000001:
		rigidbody.apply_central_impulse(impulse)
	else:
		# apply_impulse(offset, impulse) — offset podawany w lokalnych współrzędnych ciała
		# w Godot 4: apply_impulse(offset: Vector3, impulse: Vector3)
		rigidbody.apply_impulse(offset, impulse)
		# dodatkowo aplikuj lekki moment obrotowy jeśli chcesz silniejszy efekt
		if spin_strength > 0.0:
			# oblicz przybliżony torque impulse: r x F
			var torque := offset.cross(impulse)
			# apply_torque_impulse dostępne w RigidBody3D
			rigidbody.apply_torque_impulse(torque * 0.5)


func _on_team_line_stop_picie() -> void:
	goforpucha = true
	state_machine.current_state.Transitioned.emit(state_machine.current_state, "Wait")

func assign_pucha(prop):
	pucha = prop
	if pucha.is_connected("puszka_przewrocona",_on_puszka_puszka_przewrocona):
		pucha.disconnect("puszka_przewrocona",_on_puszka_puszka_przewrocona)
	pucha.connect("puszka_przewrocona",_on_puszka_puszka_przewrocona)

func _on_navigation_agent_3d_target_reached() -> void:
	print("jestem")
