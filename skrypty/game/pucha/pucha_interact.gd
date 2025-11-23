extends Interact


func interact(player):
	var parent : RigidBody3D = get_parent()
	parent.collision_layer = 0
	parent.collision_mask = 0
	await player.pickUpItem(parent.duplicate())
	parent.queue_free()
