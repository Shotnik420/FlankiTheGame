extends CharacterBody3D
class_name Player

#Czulosc rozgladania sie 
@export var SENSITIVITY : float = 0.003

var jump_velocity = 4.5

var bob_freq = 2.0
var bob_amp = 0.08
var t_bob = 0.0

const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intesity = 0.2
const head_bobbing_walking_intesity = 0.1
const head_bobbing_crouching_intesity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

var walking_speed : float = 3.0
var sprinting_speed : float = 5.0
var crouching_speed : float = 1.0
var current_speed : float = 3.0
var moving : bool = false
var input_dir : Vector2 = Vector2.ZERO
var direction : Vector3 = Vector3.ZERO
var crouching_depth : float = -0.7
var stand_camera_height : float = 1.8

var sliding : bool = false
var slide_timer = 0
var slide_timer_max = 1.0
var slide_vector : Vector2 = Vector2.ZERO
var slide_speed = 5.0

var sliding_window = 0
var sliding_window_max = 10
var base_fov = 90.0


#Trzymacz kamery i ona sama
@onready var head = $Head
@onready var eyes = $Head/Eyes
@onready var camera = $Head/Eyes/Camera3D
@onready var standUpCheck = $Head/StandUpCheck
@onready var vis_ray = $Head/Eyes/Camera3D/VisRay

@onready var standing_collision_shape = $StandShape
@onready var crouching_collision_shape = $CrouchShape

@onready var label = $HudLayer/UI/Label
@onready var loading_circle = $UI/Loading

@onready var modules = $Modules

@onready var item_holder = $Head/Eyes/Camera3D/ItemHolder
var holder_pos = Vector3.ZERO
var current_item

enum PlayerState {
	IDLE_STAND,
	IDLE_CROUCH,
	CROUCHING,
	WALKING,
	SPRINTING,
	AIR
}
var player_state : PlayerState = PlayerState.IDLE_STAND

var movement_block : bool = false
var clicked_object

#Uruchamia się raz gdy wszystkie zmienne się załadują
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	holder_pos = item_holder.position
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
#Uruchamia się 60 razy na sekundę
func _physics_process(delta: float) -> void:
	updatePlayerState()
	updateCamera(delta)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if !movement_block:
		movement(delta)
	
	if vis_ray.is_colliding():
		label.show()
		label.text = "Wcisnij F by " + vis_ray.get_collider().display_name
		if Input.is_action_just_pressed("interact"):
			vis_ray.get_collider().interact(self)
	else:
		label.hide()
		clicked_object = false
		
	
	
	
	updateModules(delta)
	updatePickedUp(delta)
	
	move_and_slide()

func headbob() -> void:
	head_bobbing_vector.y = sin(head_bobbing_index)
	head_bobbing_vector.x = sin(head_bobbing_index/2) * 0.5

func updatePickedUp(delta):
	
	if current_item:
		#item_holder.global_position = lerp(item_holder.global_position,holder_pos,delta*10 )
		current_item.global_position = item_holder.global_position
		current_item.global_rotation = item_holder.global_rotation

func movement(delta):
	# Handle jump.
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = jump_velocity
	input_dir = Input.get_vector("left", "right", "forward", "back")
	if Input.is_action_just_released("sprint"):
		sliding_window = sliding_window_max
	if Input.is_action_just_pressed("crouch") and sliding_window > 0 and input_dir != Vector2.ZERO:
		print("slide start")
		sliding = true
		slide_timer = slide_timer_max
		slide_vector = input_dir
		
	if is_on_floor():
		direction = lerp(direction, (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10.0)
	else:
		if input_dir !=Vector2.ZERO:
			direction = lerp(direction, (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*3.0)
	if sliding and Input.is_action_pressed("crouch"):
		direction = (head.transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = (slide_timer+0.1) * slide_speed
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			print("slide end")
			sliding = false
	if sliding_window >0 and is_on_floor():
		sliding_window -= 1
	
	if is_on_floor() and !sliding and input_dir != Vector2.ZERO:
		headbob()
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y *(head_bobbing_current_intensity/2.0), delta*10.0)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x *(head_bobbing_current_intensity), delta*10.0)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*10.0)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*10.0)

#func interact_circle():
	#interact_circle_value -= 0.1
	#interact_circle_value = clampf(interact_circle_value, 0.0, 1.0)
	#if interact_circle_value == 1.0:
		#vis_ray.get_collider().interact()
		#interact_circle_value = 0.0
		#clicked_object = true
	#loading_circle.material.set("shader_parameter/fill_ratio",interact_circle_value);

func updatePlayerState() -> void:
	moving = (input_dir != Vector2.ZERO)
	if not is_on_floor():
		player_state = PlayerState.AIR
	else:
		if Input.is_action_pressed("crouch"):
			if not moving:
				player_state = PlayerState.IDLE_CROUCH
			else:
				player_state = PlayerState.CROUCHING
		elif !standUpCheck.is_colliding():
			if not moving:
				player_state = PlayerState.IDLE_STAND
			elif Input.is_action_pressed("sprint"):
				sliding_window = sliding_window_max
				player_state = PlayerState.SPRINTING
			else:
				player_state = PlayerState.WALKING
				
	updatePlayerSpeed(player_state)
	updatePlayerColShape(player_state)
	



func updatePlayerColShape(_player_state : PlayerState) -> void:
	if _player_state == PlayerState.CROUCHING or _player_state == PlayerState.IDLE_CROUCH:
		crouching_collision_shape.disabled = false
		standing_collision_shape.disabled = true
	else:
		crouching_collision_shape.disabled = true
		standing_collision_shape.disabled = false

func updatePlayerSpeed(_player_state : PlayerState) -> void:
	if _player_state == PlayerState.CROUCHING or _player_state == PlayerState.IDLE_CROUCH:
		current_speed = crouching_speed
	elif _player_state == PlayerState.WALKING:
		current_speed = walking_speed
	elif _player_state == PlayerState.SPRINTING:
		current_speed = sprinting_speed

func updateCamera(delta: float) -> void:
	if player_state == PlayerState.AIR:
		pass
	if player_state == PlayerState.CROUCHING or player_state == PlayerState.IDLE_CROUCH:
		head_bobbing_current_intensity = head_bobbing_crouching_intesity
		head_bobbing_index += head_bobbing_crouching_speed * delta
		head.position.y = lerp(head.position.y, stand_camera_height + crouching_depth, delta *10.0)
		camera.fov = lerp(camera.fov, base_fov-6.0,delta * 10)
	elif player_state == PlayerState.IDLE_STAND:
		head.position.y = lerp(head.position.y, stand_camera_height, delta *10.0)
		camera.fov = lerp(camera.fov, base_fov,delta * 10)
	elif player_state == PlayerState.WALKING:
		head_bobbing_current_intensity = head_bobbing_walking_intesity
		head_bobbing_index += head_bobbing_walking_speed * delta
		head.position.y = lerp(head.position.y, stand_camera_height, delta *10.0)
		camera.fov = lerp(camera.fov, base_fov+2.0,delta * 10)
	elif player_state == PlayerState.SPRINTING:
		head_bobbing_current_intensity = head_bobbing_sprinting_intesity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
		head.position.y = lerp(head.position.y, stand_camera_height, delta *10.0)
		camera.fov = lerp(camera.fov, base_fov+7.0,delta * 10)


func add_module(module : Module):
	modules.add_child(module)

func updateModules(delta):
	for module in modules.get_children():
		module.PhysicsUpdate(delta)
