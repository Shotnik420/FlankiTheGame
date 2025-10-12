extends CharacterBody3D

#Predkosci gracza
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

#Czulosc rozgladania sie 
var SENSITIVITY : float = 0.003

#Deklaracja zmiennej kierunku gracza
var direction : Vector3 = Vector3.ZERO

#Trzymacz kamery i ona sama
@onready var head = $Head
@onready var camera = $Head/Camera3D

signal cam_ready
#Nowy komentarz
#Uruchamia się raz gdy wszystkie zmienne się załadują
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_ready.emit(self)

#Uruchamia się 60 razy na sekundę
func _physics_process(delta: float) -> void:
	#Dodanie grawitacji
	if not is_on_floor():
		velocity += get_gravity() * delta

	#Jeżeli wciśnięta spacja to dodaj prędkość w górę
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	#Bierze wejście z klawiatury i sprawdza kierunek prawo-lewo i przód-tył. 
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	
	#Bardzo zaawansowana funkcja która płynnie wybiera kierunek
	direction = lerp(direction, (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10.0)
	
	#Jeżeli jest kierunek to idź w jego strone
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
#		#Jak nie to powoli hamuj do zera
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	#Ta funkcja musi tu być. Odpowiada za poruszanie się gracza.
	move_and_slide()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		#patrzenie lewo-prawo
		head.rotate_y(-event.relative.x * SENSITIVITY)
		#patrzenie góra-dół
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		#ograniczenie by nie można było patrzeć za plecy.
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))


func sensitivity_change(value) -> void:
	SENSITIVITY=value
