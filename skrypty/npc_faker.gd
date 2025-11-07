extends Node

var counter : int = -1
var max_counter : int = 400
func _physics_process(delta: float) -> void:
	#if counter > 0:
		#counter -= 1
	#elif counter == 0:
		#counter -= 1
		#fake_npc_put_puszka()
	pass
	


func _on_puszka_puszka_przewrocona() -> void:
	#counter = max_counter
	pass

func fake_npc_put_puszka():
	#print("Npc postawia puszkę.")
	#get_parent().player.stop_drink()
	#await get_tree().create_timer(3.0,false).timeout
	#get_parent().player.pick_up_minigame()
	pass
