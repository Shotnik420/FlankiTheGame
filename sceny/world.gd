extends Node3D
@onready var player: CharacterBody3D = $Player

@onready var puszka_point = $PuszkaPoint
@onready var debug_window = $DebugLayer/DebugWindow
@onready var pucha = $Puszka
var whose_turn : int = 1

func _ready() -> void:
	Global.world = self
	Global.pucha = pucha
