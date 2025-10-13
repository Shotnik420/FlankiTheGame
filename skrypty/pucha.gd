extends Interact


func interact(player):
	var parent : RigidBody3D = get_parent()
	parent.collision_layer = 0
	parent.collision_mask = 0
	player.current_item = parent
