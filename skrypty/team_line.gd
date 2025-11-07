extends Area3D

@onready var puszka = $"../Puszka"

var puszka_przewrocona : bool = false

signal stop_picie

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and puszka_przewrocona:
		print("yupp")
		body.passed_the_line()
		stop_picie.emit()

func _on_interact_spawned_pucha(_pucha) -> void:
	print(Global.current_game_state)
	if Global.current_game_state == Global.Game_State.NpcThrow:
		puszka_przewrocona = true


func _on_puszka_puszka_przewrocona() -> void:
	puszka_przewrocona = false
