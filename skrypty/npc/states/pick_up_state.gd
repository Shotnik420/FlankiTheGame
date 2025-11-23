extends State

func Enter():
	npc = get_parent().npc
	npc.current_item = npc.pucha.duplicate()
	npc.change_state_machine_condition("pickup", true)
	await get_tree().create_timer(0.5).timeout
	npc.pucha.queue_free()
	npc.goforpucha = false
	npc.has_puszka = true
	await get_tree().create_timer(0.8).timeout
	npc.change_state_machine_condition("pickup", false)
	
	Transitioned.emit(self,"Chase")
	
