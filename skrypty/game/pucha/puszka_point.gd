extends Node3D

@onready var interact = $Interact
@onready var mdl = $Cylinder

var can_spin : bool = false
var pos_y : Vector3
func _ready() -> void:
	spin_mdl()
	pos_y = mdl.position

func be_interactable(prop):
	if prop:
		interact.collision_layer = 16
		interact.collision_mask = 16
	else:
		interact.collision_layer = 0
		interact.collision_mask = 0

func _physics_process(delta: float) -> void:
	if can_spin:
		spin_mdl()

func spin_mdl():
	if !mdl:
		return
	can_spin = false
	pos_y -= Vector3(0,0.2,0)
	var spin_tween = get_tree().create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	spin_tween.tween_property(mdl, "rotation_degrees:y", 180, 2.0)
	spin_tween.tween_property(mdl, "position", pos_y, 2.0)

	await spin_tween.finished
	pos_y += Vector3(0,0.2,0)
	spin_tween.kill()
	spin_tween = get_tree().create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	spin_tween.tween_property(mdl, "rotation_degrees:y", 360, 2.0)
	spin_tween.tween_property(mdl, "position", pos_y, 2.0)
	await spin_tween.finished
	can_spin = true
