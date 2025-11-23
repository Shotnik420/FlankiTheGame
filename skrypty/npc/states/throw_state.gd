extends State

var threw : bool = false
var failure_timer : int = 0
func Enter():
	npc = get_parent().npc
	Global.throw_tried = false
	npc.anim_tree.set("parameters/Transition/transition_request", "throw")
	npc.change_state_machine("ThrowMachine")
	
	await get_tree().create_timer(2.0,false).timeout
	npc.change_state_machine_condition("throw", true)
	await get_tree().create_timer(0.5,false).timeout
	npc.spawn_n_throw()
	Global.throw_tried = true
	threw = true
	failure_timer = 120

func PhysicsUpdate(delta: float) -> void:
	var rot_dir = npc.global_position.direction_to(npc.puszka_point.global_position)
	var target_rotation = Vector3(0, atan2(rot_dir.x, rot_dir.z), 0)
	npc.rotate_to_target(target_rotation)
	if threw:
		
		if failure_timer == 0:
			threw = false
			npc.change_state_machine_condition("throw_fail", true)
			await get_tree().create_timer(1.5,false).timeout
			Global.get_next_step()
			Transitioned.emit(self, "Wait")
		elif failure_timer > 0:
			failure_timer -= 1

func trans_to_drink():
	Transitioned.emit(self, "Drink")
func Exit():
	threw = false
	npc.anim_tree.set("parameters/Transition/transition_request", "gameplay")
	npc.change_state_machine_condition("throw", false)
	npc.change_state_machine_condition("throw_fail", false)
	npc.change_state_machine_condition("reset_throw", false)
