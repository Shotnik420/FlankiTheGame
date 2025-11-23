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

func trans_to_throw():
	Transitioned.emit(self, "Throw")

func trans_to_chase():
	Transitioned.emit(self, "Chase")

func trans_to_drink():
	Transitioned.emit(self, "Drink")

func do_taunt():
	var tauntnum = ""
	if randi()%2==0:
		tauntnum = "taunt1"
	else:
		tauntnum = "taunt2"
	npc.change_state_machine_condition(tauntnum, true)
	await get_tree().create_timer(0.1,false).timeout
	npc.change_state_machine_condition(tauntnum, false)
