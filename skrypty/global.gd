extends Node


var player : Player

var pucha

var world

enum Game_State {
	PlayerThrow,
	NpcThrow
}

var current_game_state : Game_State = Game_State.PlayerThrow

func switch_game_state():
	if current_game_state == Game_State.PlayerThrow:
		current_game_state = Game_State.NpcThrow
	else:
		current_game_state = Game_State.PlayerThrow

func on_player_mam_puszke() -> void:
	world.puszka_point.show()
	world.puszka_point.be_interactable(true)
	
