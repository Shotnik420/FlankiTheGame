extends State


func Enter():
	npc = get_parent().npc
	if npc.nav_agent.target_reached.is_connected(PointReached):
		npc.nav_agent.target_reached.disconnect(PointReached)
	npc.nav_agent.target_reached.connect(PointReached)
	npc.change_state_machine_condition("run", true)
	npc.change_state_machine_condition("unrun", false)
func Exit():
	npc.nav_agent.target_reached.disconnect(PointReached)

func PhysicsUpdate(delta: float) -> void:
	if npc.pucha and npc.goforpucha:
		npc.set_target_pos(npc.pucha.global_position)
	elif npc.has_puszka:
		npc.set_target_pos(npc.puszka_point.global_position)
	elif npc.won:
		npc.set_target_pos(npc.my_winner_point.global_position)
	elif !npc.goforpucha:
		npc.set_target_pos(npc.spawn_point)
		
	if npc.can_walk:
		npc.walk()


func PointReached():
	if npc.has_puszka:
		npc.has_puszka = false
		npc.can_walk = false
		npc.change_state_machine_condition("pickup", true)
		await get_tree().create_timer(0.5).timeout
		npc.change_state_machine_condition("pickup", false)
		npc.puszka_point.get_node("Interact").interact(npc)
		await get_tree().create_timer(1.1).timeout
		npc.can_walk = true
	elif !npc.goforpucha:
		npc.can_walk = false
		Transitioned.emit(self,"Wait")
		Global.get_next_step()
	else:
		Transitioned.emit(self,"PickUp")
