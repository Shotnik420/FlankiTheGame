extends Control
@onready var pause_menu: Control = $"."
#panele
@onready var options: Panel = $options
@onready var buttons: Panel = $buttons
#slidebary(opcje)
@onready var fov: HSlider = $options/FOV/FOV
@onready var sensitivity: HSlider = $options/SENSITIVITY/SENSITIVITY
var sensitivity_value=0.003
signal VELO
var player_cam
var player
#@onready var fov_2: Label = $options/FOV/FOV2


func _ready() -> void:
	pause_menu.visible= false
	sensitivity.value=sensitivity_value

func resume():
	get_tree().paused = false
	pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pause():
	get_tree().paused = true
	pause_menu.visible = true
	buttons.visible = true
	options.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
func esc():
	if Input.is_action_just_pressed("esc") and get_tree().paused == false:
		
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused == true:
		resume()

func _process(delta):
	esc()


func _on_options_pressed() -> void:
	options.visible = true
	buttons.visible = false


func _on_resume_pressed() -> void:
	resume()


func _on_back_pressed() -> void:
	resume()
	


func _on_fov_value_changed(value: float) -> void:
	if player_cam !=null:
		player_cam.fov=value


func _on_player_cam_ready(prop) -> void:
	player =prop
	player_cam = player.camera
	sensitivity_value=player.SENSITIVITY*1000


func _on_sensitivity_value_changed(value: float) -> void:
	VELO.emit(value/1000)
