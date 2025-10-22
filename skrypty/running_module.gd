extends Module

func Enter():
	player = get_parent().player
	player.movement_block = false
	player.mouse_block = false
