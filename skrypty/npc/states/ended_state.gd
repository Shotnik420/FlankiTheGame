extends State

func Enter():
	npc = get_parent().npc
	npc.can_walk = true
	npc.won = true
	npc.goforpucha = false
	
	await get_tree().create_timer(1.0, false).timeout
	Transitioned.emit(self, "Chase")
	
