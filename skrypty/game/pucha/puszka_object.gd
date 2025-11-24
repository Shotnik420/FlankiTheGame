extends RigidBody3D
class_name Item
var przewrocona : bool = false

@onready var interact = $Interact
@onready var sound : AudioStreamPlayer3D = $Sound
@onready var sound2 : AudioStreamPlayer3D = $Sound2
var sounds_hard = [load("res://assety/dzwieki/puszka/hard_can_drop1.wav"),
load("res://assety/dzwieki/puszka/hard_can_drop2.wav"),
load("res://assety/dzwieki/puszka/hard_can_drop3.wav")]
var sounds_soft = [load("res://assety/dzwieki/puszka/soft_can_drop1.wav"),
load("res://assety/dzwieki/puszka/soft_can_drop2.wav"),
load("res://assety/dzwieki/puszka/soft_can_drop3.wav")]

@onready var fake_pucha = $PuchaFake
func _ready():
	connect("collision", Callable(self, "_on_collision"))

func _on_fall_check_body_entered(body: Node3D) -> void:
	
	if body.is_in_group("floor") and !przewrocona:
		przewrocona = true
		print("Trafiona")
		Global.puszka_has_fallen()
		if Global.current_game_state == Global.Game_State.NpcDrink:
			pickup_outline()
		interact.collision_layer = 16
		interact.collision_mask = 16



func reset_outline():
	fake_pucha.outline_thickness = 0.05
	fake_pucha.outline_color = Color(0.0, 0.0, 0.0, 1.0)
func pickup_outline():
	fake_pucha.outline_thickness = 0.25
	fake_pucha.outline_color = Color(1.0, 1.0, 0.0, 1.0)
	print(fake_pucha.myskin)
	fake_pucha.update_skin()
func play_hard():
	if sound.playing:
		sound2.stream = sounds_hard[randi_range(0,2)]
		sound2.play()
		return
	sound.stream = sounds_hard[randi_range(0,2)]
	sound.play()


func play_soft():
	if sound.playing:
		sound2.stream = sounds_soft[randi_range(0,2)]
		sound2.play()
		return
	sound.stream = sounds_soft[randi_range(0,2)]
	sound.play()

func play_sound_with_pitch_scale(stream):
	pass

func _integrate_forces(state):
	var count = state.get_contact_count()
	if count > 0:
		for i in range(count):
			var collision_force = state.get_contact_impulse(i)
			if collision_force.length() > 0.6: # minimalna siła uderzenia
				play_hard()
				break
			elif collision_force.length() > 0.2:
				play_soft()
