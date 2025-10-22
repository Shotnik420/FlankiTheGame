extends Area3D

@onready var puszka = $"../Puszka"

var puszka_przewrocona : bool = false
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and puszka_przewrocona:
		body.passed_the_line()


func _on_interact_spawned_pucha() -> void:
	puszka_przewrocona = true


func _on_puszka_puszka_przewrocona() -> void:
	puszka_przewrocona = false
