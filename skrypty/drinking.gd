extends Module

@export var Line : Node2D

@export var Fluid : Node2D

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
