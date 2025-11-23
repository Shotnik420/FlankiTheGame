extends Module


func Enter() -> void:
	player = get_parent().player 
	player.mouse_block = false
	player.movement_block = true
