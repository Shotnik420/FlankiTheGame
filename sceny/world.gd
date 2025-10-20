extends Node3D
@onready var player: CharacterBody3D = $Player

@onready var puszka_point = $PuszkaPoint
@onready var debug_window = $DebugLayer/DebugWindow

var was_blocked : bool = false
func _on_player_mam_puszke() -> void:
	puszka_point.show()
	puszka_point.be_interactable(true)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		debug_window.visible = !debug_window.visible
		if player:
			if !player.mouse_block:
				player.mouse_block = true
				was_blocked = false
			elif player.mouse_block:
				was_blocked = true
			
		if debug_window.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED) 
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
