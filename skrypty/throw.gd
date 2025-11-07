extends State

func Enter():
	npc = get_parent().npc
	print("Odstep ", npc.global_position.distance_to(npc.pucha.global_position))
	await get_tree().create_timer(2.0).timeout
	npc.spawn_n_throw()

func PhysicsUpdate(delta: float) -> void:
	var rot_dir = npc.global_position.direction_to(npc.puszka_point.global_position)
	var target_rotation = Vector3(0, atan2(rot_dir.x, rot_dir.z), 0)
	npc.rotate_to_target(target_rotation)
