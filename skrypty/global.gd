extends Node


var player : Player

var pucha

var world

enum Game_State {
	PlayerThrow,
	NpcThrow,
	PlayerDrink,
	NpcDrink,
	PlayerWon,
	NpcWon
}

var current_game_state : Game_State = Game_State.PlayerThrow
var teams = {
	"player_team": [],
	"npc_team": []
}
var player_cursor : int = 0
var npc_cursor : int = 0

var throw_tried : bool = false
var player_team_line 

var player_winner_points : Node3D
var npc_winner_points : Node3D

func switch_game_state():
	if current_game_state == Game_State.PlayerThrow:
		current_game_state = Game_State.NpcThrow
	else:
		current_game_state = Game_State.PlayerThrow
	print("TRYB GRY:   ",current_game_state)

func puszka_has_fallen():
	if current_game_state == Game_State.PlayerThrow:
		current_game_state = Game_State.PlayerDrink
	elif current_game_state == Game_State.NpcThrow:
		current_game_state = Game_State.NpcDrink
	apply_step()

func player_throw():
	player.passed_the_line()

func on_player_mam_puszke() -> void:
	world.puszka_point.show()
	world.puszka_point.be_interactable(true)

func get_next_step():
	if current_game_state == Game_State.PlayerThrow and throw_tried:
		current_game_state = Game_State.NpcThrow
	elif current_game_state == Game_State.NpcThrow and throw_tried:
		current_game_state = Game_State.PlayerThrow
	elif current_game_state == Game_State.NpcDrink:
		current_game_state = Game_State.PlayerThrow
	elif current_game_state == Game_State.PlayerDrink:
		current_game_state = Game_State.NpcThrow
	
	apply_step()
func apply_step():
	print("CURRENT GAME STATE  ", current_game_state)
	assign_winner_points()
	match current_game_state:
		Game_State.PlayerThrow:
			teams["player_team"][player_cursor].throw_minigame()
			for npc in teams["npc_team"]:
				npc.wait()
		Game_State.NpcThrow:
			teams["npc_team"][npc_cursor].throw_minigame()
			for plr in teams["player_team"]:
				plr.wait()
		Game_State.PlayerDrink:
			for plr in teams["player_team"]:
				plr.drinking_minigame()
			teams["npc_team"][npc_cursor].chase_pucha_minigame()
			for npc in teams["npc_team"]:
				npc.taunt_hurry_up()
		Game_State.NpcDrink:
			for npc in teams["npc_team"]:
				npc.drinking_minigame()
			teams["player_team"][player_cursor].chase_pucha_minigame()
			player_team_line.puszka_przewrocona = false
		Game_State.PlayerWon:
			for npc in teams["npc_team"]:
				npc.game_lost()
			for plr in teams["player_team"]:
				plr.game_won()
		Game_State.NpcWon:
			for npc in teams["npc_team"]:
				npc.game_won()
			for plr in teams["player_team"]:
				plr.game_lost()
	if player_cursor +1 ==  teams["player_team"].size():
		player_cursor = 0
	else:
		player_cursor += 1
	
	if npc_cursor +1 ==  teams["npc_team"].size():
		npc_cursor = 0
	else:
		npc_cursor +=1



func assign_pucha_to_all():
	for plr in teams["player_team"]:
		plr.assign_pucha(Global.pucha)
	for npc in teams["npc_team"]:
		npc.assign_pucha(Global.pucha)

func assign_winner_points():
	var plrpoints = Global.player_winner_points.get_children()
	for plr in teams["player_team"]:
		var rand_point = plrpoints[randi_range(0,plrpoints.size()-1)]
		plr.my_winner_point = rand_point
		plrpoints.erase(rand_point)
	var npcpoints = Global.npc_winner_points.get_children()
	for npc in teams["npc_team"]:
		var rand_point = npcpoints[randi_range(0,npcpoints.size()-1)]
		npc.my_winner_point = rand_point
		npcpoints.erase(rand_point)
func remove_npc(npc):
	var try = teams["player_team"].find(npc)
	if try != -1:
		teams["player_team"].erase(npc)
	try = teams["npc_team"].find(npc)
	if try != -1:
		teams["npc_team"].erase(npc)
	game_ended_check()

func game_ended_check():
	if teams["player_team"].size() == 0:
		current_game_state = Game_State.PlayerWon
		apply_step()
	elif teams["npc_team"].size() == 0:
		current_game_state = Game_State.NpcWon
		apply_step()
