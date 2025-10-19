extends Sprite2D

var clicked: bool = false
var hide_started : bool = false
var speed : float = 6.0
var op_tween : Tween 



func _ready() -> void:
	modulate.a = 0.0
	op_tween = get_tree().create_tween().set_parallel(true)
	op_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await op_tween.finished
	op_tween.kill()


func _physics_process(delta: float) -> void:
	if !clicked:
		global_position.x -= speed
		if position.x <=0.0:
			tween_hide()
		
	

func tween_hide():
	if !hide_started:
		hide_started = true
		op_tween = get_tree().create_tween().set_parallel(true)
		op_tween.tween_property(self, "modulate:a", 0.0, 0.6)
		await op_tween.finished
		op_tween.kill()

func tween_got_hit():
	hide_started = true
	if op_tween:
		op_tween.kill()
	op_tween = get_tree().create_tween().set_parallel(true)
	op_tween.tween_property(self, "scale", Vector2(0.5,0.5), 0.5)
	op_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await op_tween.finished
	op_tween.kill()
	queue_free()

func click():
	if !clicked:
		clicked = true
		tween_got_hit()
		return true
	return false
	
