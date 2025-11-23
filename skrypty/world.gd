extends Node3D
@onready var player: CharacterBody3D = $PlayerTeam/Player
@onready var puszka_point = $PuszkaPoint
@onready var debug_window = $DebugLayer/DebugWindow
@onready var pucha = $Puszka
@onready var player_team_holder = $PlayerTeam
@onready var npc_team_holder = $NpcTeam
@onready var team_line = $TeamLine
var whose_turn : int = 1

func _ready() -> void:
	Global.world = self
	Global.pucha = pucha
	Global.player_team_line = team_line
	if player_team_holder:
		for plr in player_team_holder.get_children():
			Global.teams["player_team"].append(plr)
	if npc_team_holder:
		for npc in npc_team_holder.get_children():
			Global.teams["npc_team"].append(npc)
