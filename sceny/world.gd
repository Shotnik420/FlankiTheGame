extends Node3D
@onready var player: CharacterBody3D = $Player

@onready var puszka_point = $PuszkaPoint


func _on_player_mam_puszke() -> void:
	puszka_point.show()
