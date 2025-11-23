extends State

var beer_amount = 600
var drink_max = 120
var drink_timer = 120
var ended : bool = false

func Enter():
	drink_timer = drink_max
	npc = get_parent().npc
	print("StartDrinking")
	
	npc.anim_tree.set("parameters/Transition/transition_request", "drink")
	npc.change_state_machine("DrinkMachine")
	npc.change_state_machine_condition("drink_reset", false)

func end_picie():
	npc.change_state_machine_condition("drink_end",true)
	ended = true
	await get_tree().create_timer(3.0,false).timeout
	Transitioned.emit(self, "Wait")
func PhysicsUpdate(_delta: float) -> void:
	if !ended:
		drink_timer -= 1
		if drink_timer == 0:
			take_sip()
			drink_timer = drink_max

func take_sip():
	beer_amount -= 30 + randi_range(-10,10)

func Exit():
	npc.can_drink = false
	npc.anim_tree.set("parameters/Transition/transition_request", "gameplay")
	npc.change_state_machine_condition("drink_reset", true)
	npc.change_state_machine_condition("drink_end", false)
	npc.change_state_machine("StateMachine")
