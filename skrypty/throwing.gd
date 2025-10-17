extends Module

var can_throw : bool = true
#Scena petardy
var petarda=preload("res://sceny/petarda.tscn")
#Timer, opóźnienia
@onready var throw_timer: Timer = $"../../ThrowTimer"

@export var MAX_PETARDS : int = 3
#Lista wyrzuconych petard
var thrown_petards: Array = []  
func Enter():
	player = get_parent().player

func PhysicsUpdate(_delta):
	petarda_throw()

func petarda_throw():
	if Input.is_action_just_pressed("throw") && can_throw==true:
		# Tworzenie nowej petardy
		var petarda_spawn = petarda.instantiate()
		petarda_spawn.position = player.throw_point.global_position
		get_tree().current_scene.add_child(petarda_spawn)
		# Impuls rzutu
		var throw_force = -18.0
		var up_direction = 3.5
		var player_rotation = player.camera.global_transform.basis.z.normalized()
		petarda_spawn.apply_central_impulse(player_rotation * throw_force + Vector3(0, up_direction, 0))
		# Losowy obrót
		petarda_spawn.angular_velocity = Vector3(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)

		# Dodaj do listy
		thrown_petards.append(petarda_spawn)

		# Jeśli przekroczono limit – usuń najstarszą
		if thrown_petards.size() > MAX_PETARDS:
			var oldest = thrown_petards.pop_front()  # Usuwa pierwszy element
			if oldest and is_instance_valid(oldest):
				oldest.queue_free()


		# Zablokuj rzucanie i uruchom timer
		can_throw = false
		throw_timer.start()


func _on_throw_timer_timeout() -> void:
	can_throw = true
