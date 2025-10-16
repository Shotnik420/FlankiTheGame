extends CharacterBody3D
class_name Player

#Czulosc rozgladania sie 
@export var SENSITIVITY : float = 0.003

#Siła skoku
var jump_velocity = 4.5

#Zmienne kiwania kamerą
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

#Predkość gracza
var walking_speed : float = 3.0
var sprinting_speed : float = 5.0
var crouching_speed : float = 1.0

#Obecna prędkość
var current_speed : float = 3.0

#Czy się ruszam?
var moving : bool = false

#Kierunek wejścia (WSAD)
var input_dir : Vector2 = Vector2.ZERO

#Kierunek gracza
var direction : Vector3 = Vector3.ZERO

#Głębokość kucnięcia
var crouching_depth : float = -0.7
#Normalna wysokość kamery
var stand_camera_height : float = 1.8

#Zmienne ślizgania się
var sliding : bool = false
var slide_timer = 0
var slide_timer_max = 1.0
var slide_vector : Vector2 = Vector2.ZERO
var slide_speed = 5.0

var sliding_window = 0
var sliding_window_max = 10

#Pierwotne fov
var base_fov = 90.0


#Trzymacz kamery i ona sama
@onready var head = $Head
#Ta część która zajmuje się kiwaniem kamery
@onready var eyes = $Head/Eyes
#Kamera gracza
@onready var camera = $Head/Eyes/Camera3D
#Sprawdzacz czy nad graczem coś jest (by odkucnąć)
@onready var standUpCheck = $Head/StandUpCheck
#Promień do wykrywania na co patrzy gracz (przedmioty)
@onready var vis_ray = $Head/Eyes/Camera3D/VisRay

#Krztałty kolizji gracza stojąca i kucania
@onready var standing_collision_shape = $StandShape
@onready var crouching_collision_shape = $CrouchShape

#Napis wyświetlający się gdy możesz coś podnieść
@onready var label = $HudLayer/UI/Label

#Hud obracające się kółko interakcji (nieużywane)
@onready var loading_circle = $UI/Loading

#Moduły, to są bloczki które dają graczowi poszczególne możliwości. Np rzucanie
@onready var modules = $Modules

#Node który trzyma przedmioty
@onready var item_holder = $Head/Eyes/Camera3D/ItemHolder

#Obecny item, który
var current_item

#Czy mogę rzucać?
var can_throw= true
#Scena petardy
var petarda=preload("res://sceny/petarda.tscn")
#Timer, opóźnienia
@onready var throw_timer: Timer = $ThrowTimer
#Lista wyrzuconych petard
var thrown_petards: Array = []  
#Maksymalne petardy
const MAX_PETARDS: int = 3
#Punkt wyrzutu
@onready var throw_point = $Head/Eyes/Camera3D/ThrowPoint

#Sygnał ogłaszający że kamera jest gotowa
signal cam_ready

#Stany gracza pomagają w ustalaniu prędkości kierunku i zachowania gracza.
enum PlayerState {
	IDLE_STAND,
	IDLE_CROUCH,
	CROUCHING,
	WALKING,
	SPRINTING,
	AIR
}

#Obecny stan gracza
var player_state : PlayerState = PlayerState.IDLE_STAND

#Blokada ruchu
var movement_block : bool = true

#Sygnał wysyłany gdy podniesiemy puszkę
signal mam_puszke

#Uruchamia się raz gdy wszystkie zmienne się załadują
func _ready() -> void:
	#Ustawiamy by myszką była zablokowana i można by było się obracać w 3D
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#Wysyłamy że kamera jest gotowa
	cam_ready.emit(self)


#Ta funkcja odpala się kiedy poruszysz myszką
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		#Obróć głowę lewo-prawo
		head.rotate_y(-event.relative.x * SENSITIVITY)
		#Obróc głowę góra-dół
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		#Blokada by nie można było się patrzeć za plecy
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))


#Uruchamia się 60 razy na sekundę
func _physics_process(delta: float) -> void:
	#Aktualizacja stanu gracza
	updatePlayerState()
	#Aktualizacja kiwania kamerą
	updateCamera(delta)
	
	if not is_on_floor():
		#Dodaj do prędkości spadek w dół
		velocity += get_gravity() * delta
	
	#Aktualizacja movementu
	if !movement_block:
		movement(delta)
	#else:
	##Gdy nie możesz się ruszać to rzucaj
	petarda_throw()
	
	#Jeżeli coś jest przed twarzą to wyświetl nazwę i czekaj na kliknięcie
	if vis_ray.is_colliding() and vis_ray.get_collider():
		label.show()
		label.text = "Wcisnij F by " + vis_ray.get_collider().display_name
		if Input.is_action_just_pressed("interact"):
			vis_ray.get_collider().interact(self)
	else:
		#Inaczej schowaj napis
		label.hide()
		
	
	
	#Aktualizuj moduły
	updateModules(delta)

	#Potrzebna funkcja by gracz mógł przetwarzać ruch
	move_and_slide()


#Funkcja kiwania głową
func headbob() -> void:
	head_bobbing_vector.y = sin(head_bobbing_index)
	head_bobbing_vector.x = sin(head_bobbing_index/2) * 0.5


func movement(delta):
	# Handle jump.
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = jump_velocity
	
	#Pobierz wejście WSAD 
	input_dir = Input.get_vector("left", "right", "forward", "back")
	
	#Puszczenie sprinta daje jeszcze chwilkę by zacząć ślizg
	if Input.is_action_just_released("sprint"):
		sliding_window = sliding_window_max

	#Jeżeli wcisnąłem crouch i mogę się ślizgać i jest jakieś wejście na WSAD to się ślizgamyyyy
	if Input.is_action_just_pressed("crouch") and sliding_window > 0 and input_dir != Vector2.ZERO:
		sliding = true
		slide_timer = slide_timer_max
		slide_vector = input_dir
	
	#Jeżeli jesteśmy na ziemi to zmieniamy kierunek na podstawie klawiatury SZYBKO
	if is_on_floor():
		#Po Polsku:
		#Direction = wygładzanie(lerp) obecnego Direction w kierunku 
		#zwrócenia naszej głowy RAZY znormalizowane(kierunkowe) wejście ze WSAD
		#
		direction = lerp(direction, (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10.0)
	else:
		#Jeżeli mamy wejście na WSAD
		if input_dir !=Vector2.ZERO:
			#A jak jesteśmy w powietrzu to też zmieniamy kierunek ale wolno
			direction = lerp(direction, (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*3.0)
			#Przez to że na początku sprawdzamy czy jest wejście, gdy klikniemy samą spacje
			# to gracz poleci swobodnie do przodu, a gdy będzie manewrował to lekko poleci w daną stronę
	
	#Jeżeli się ślizgamy i wciskam ctrl to ślizgamy sie dalej ess
	if sliding and Input.is_action_pressed("crouch"):
		direction = (head.transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = (slide_timer+0.1) * slide_speed
	
	#Jeżeli mamy kierunek to zmierzamy w jego kierunku
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	else:
		#Inaczej powoli hamujemy do zera
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	#Obsługiwanie countera ślizgu i zmiana sliding na false gdy osiągnie zero
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			print("slide end")
			sliding = false
	if sliding_window >0 and is_on_floor():
		sliding_window -= 1
	
	#Jeżeli się ruszamy to zacznij kiwać głową. Inaczej wróc do 0,0
	if is_on_floor() and !sliding and input_dir != Vector2.ZERO:
		headbob()
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y *(head_bobbing_current_intensity/2.0), delta*10.0)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x *(head_bobbing_current_intensity), delta*10.0)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*10.0)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*10.0)



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
func sensitivity_change(value) -> void:
	SENSITIVITY=value

func pickUpItem(item):
	item_holder.add_child(item)
	current_item = item
	if item.is_in_group("piwo"):
		mam_puszke.emit()
		item.position = Vector3.ZERO
		item.rotation = Vector3.ZERO
		item.freeze = true
	return true

func petarda_throw():
	if Input.is_action_just_pressed("throw") && can_throw==true:
		# Tworzenie nowej petardy
		var petarda_spawn = petarda.instantiate()
		petarda_spawn.position = throw_point.global_position
		get_tree().current_scene.add_child(petarda_spawn)
		# Impuls rzutu
		var throw_force = -18.0
		var up_direction = 3.5
		var player_rotation = camera.global_transform.basis.z.normalized()
		petarda_spawn.apply_central_impulse(player_rotation * throw_force + Vector3(0, up_direction, 0))
		# Losowy obrót
		petarda_spawn.angular_velocity = Vector3(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)

		# Dodaj do listy
		thrown_petards.append(petarda_spawn)

		# Jeśli przekroczono limit – usuń najstarszą
		if thrown_petards.size() > MAX_PETARDS:
			var oldest = thrown_petards.pop_front()  # Usuwa pierwszy element
			if oldest and is_instance_valid(oldest):
				oldest.queue_free()


		# Zablokuj rzucanie i uruchom timer
		can_throw = false
		throw_timer.start()


func _on_throw_timer_timeout() -> void:
	can_throw = true


func _on_puszka_puszka_przewrocona() -> void:
	movement_block = false
