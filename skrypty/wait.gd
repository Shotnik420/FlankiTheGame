extends State


func Enter():
	npc = get_parent().npc
	if is_instance_valid(npc.anim_tree):
		npc.change_state_machine_condition("run", false)
		npc.change_state_machine_condition("unrun", true)
	

func PhysicsUpdate(delta: float) -> void:
	var rot_dir = npc.global_position.direction_to(npc.puszka_point.global_position)
	var target_rotation = Vector3(0, atan2(rot_dir.x, rot_dir.z), 0)
	npc.rotate_to_target(target_rotation)
	if npc.can_walk:
		Transitioned.emit(self, "Chase") 
	
	if Global.current_game_state == Global.Game_State.NpcThrow:
		Transitioned.emit(self,"Throw")
