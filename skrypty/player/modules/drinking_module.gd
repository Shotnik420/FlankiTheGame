extends Module

@export var Line : Control

@export var Fluid : Node2D
var camera_rot : Vector3
func Enter():
	
	player = get_parent().player
	Line.spawn_timer.start()
	player.mouse_block = true
	player.movement_block = true
	player.beer_layer.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func PhysicsUpdate(delta: float) -> void:
	Line.PhysicsUpdate(delta)
	Fluid.PhysicsUpdate(delta)

func Exit():
	Line.spawn_timer.stop()
	player.beer_layer.hide()


func _on_line_took_sip(_sip_amount) -> void:
	player.camera_sipping()
