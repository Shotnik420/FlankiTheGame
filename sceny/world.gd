extends Node3D
@onready var player: CharacterBody3D = $Player

@onready var puszka_point = $PuszkaPoint
@onready var debug_window = $DebugLayer/DebugWindow

var whose_turn : int = 1

func _on_player_mam_puszke() -> void:
	puszka_point.show()
	puszka_point.be_interactable(true)
