extends Control
@export var player : Player
var was_blocked : bool = false


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		visible = !visible
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			if player:
				if !player.mouse_block:
					was_blocked = false
				elif player.mouse_block:
					was_blocked = true
				player.mouse_block = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			if player:
				if was_blocked:
					player.mouse_block = true
				else:
					player.mouse_block = false

func _on_puszka_fall_player_pressed() -> void:
	player.drinking_minigame()
	was_blocked = true


func _on_puszka_put_player_pressed() -> void:
	player.throwing_minigame()


func _on_puszka_fall_npc_pressed() -> void:
	player.pick_up_minigame()


func _on_puszka_put_npc_pressed() -> void:
	player.changeModule(player.wait_module)
	was_blocked = false
