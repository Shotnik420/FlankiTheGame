extends Node3D

@onready var interact = $Interact
@onready var mdl = $Cylinder
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func be_interactable(prop):
	if prop:
		interact.collision_layer = 16
		interact.collision_mask = 16
	else:
		interact.collision_layer = 0
		interact.collision_mask = 0
