extends Interact

func interact(player):
	print("postawiam puszkę")
	get_parent().hide()
	var pucha : RigidBody3D = player.current_item.duplicate()
	get_parent().be_interactable(false)
	get_tree().root.add_child(pucha)
	pucha.freeze = false
	pucha.global_position = get_parent().mdl.global_position + Vector3(0, 0.1,0)
	pucha.collision_layer = 3
	pucha.collision_mask = 3
	pucha.axis_lock_angular_x = true
	pucha.axis_lock_angular_z = true
	player.current_item.queue_free()
	player.current_item = null
	await get_tree().create_timer(0.4, false).timeout
	pucha.axis_lock_angular_x = false
	pucha.axis_lock_angular_z = false
