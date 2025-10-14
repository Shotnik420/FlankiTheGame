extends RigidBody3D

var przewrocona : bool = false

@onready var interact = $Interact

func _on_fall_check_body_entered(body: Node3D) -> void:
	if body.is_in_group("floor") and !przewrocona:
		przewrocona = true
		print("Trafiona")
		interact.collision_layer = 16
		interact.collision_mask = 16
