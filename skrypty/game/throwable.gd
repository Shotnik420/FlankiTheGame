extends RigidBody3D


func _ready() -> void:
	await get_tree().create_timer(4.0,false).timeout
	queue_free()
