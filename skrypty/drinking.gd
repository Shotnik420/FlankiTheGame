extends Module

@export var Line : Node2D

@export var Fluid : Node2D

func Enter():
	Line.spawn_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func PhysicsUpdate(delta: float) -> void:
	Line.PhysicsUpdate(delta)
	Fluid.PhysicsUpdate(delta)

func Exit():
	Line.spawn_timer.stop()
