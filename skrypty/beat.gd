extends Control

@onready var klocek_check : Area2D = $"Holder/Area2D"
@onready var linia : Sprite2D = $Holder/linia
@onready var klocek = preload("res://sceny/kocek.tscn")
@onready var drinking_text = preload("res://sceny/drinkingText.tscn")
@onready var text_spawn = $Holder/TextSpawn

@onready var arr1 = $Holder/Sprite2D
@onready var arr2 = $Holder/Sprite2D2

@onready var pucha = $"../BeerHold/Sprite2D"
@onready var spawn_timer = $Holder/SpawnTimer

var arr_tween : Tween 

signal took_sip

var my_scale : Vector2 = Vector2(1.0,1.0)

var pucha_scale : Vector2 = Vector2(1.0,1.0)

func _ready() -> void:
	my_scale = scale
	pucha_scale = pucha.scale

func PhysicsUpdate(delta: float) -> void:
	for kloc in linia.get_children():
		kloc.PhysicsUpdate(delta)
	if Input.is_action_just_pressed("space") and klocek_check.get_overlapping_areas().size() > 0:
		var areas = klocek_check.get_overlapping_areas()
		if areas[0].get_parent().click():
			hit(areas[0].get_parent().position)
func hit(pos):
	var xpos = round(abs(pos.x))
	var best = -1
	match xpos:
		var n when n < 10.0:
			if 3 > best:
				best = 3
		var n when n < 20.0:
			if 2 > best:
				best = 2
		var n when n <=40.0:
			if 1 > best:
				best = 1
	
	var score = 35.0 - xpos
	took_sip.emit(score)
	spawn_new_score(best, score)
	arrows()
	tween_self()
func spawn_new_score(x, score):
	var message = "Error"
	var color = "#111111"
	match x:
		-1: 
			message = "Error no value"
		0: 
			message = "How???"
		1: 
			message = "Ledwo"
			color = "a69f9a"
		2: 
			message = "Srednio"
			color = "3cade0"
		3: 
			message = "Super"
			color = "f4c759"
		
	var drink_ins : Label = drinking_text.instantiate()
	drink_ins.text = str(score* -1.0) + " ml " + message
	drink_ins.label_settings.font_color = Color(color)
	
	arr1.modulate = Color(color)
	arr2.modulate = Color(color)
	
	text_spawn.add_child(drink_ins)
	var drink_tween : Tween = get_tree().create_tween().set_parallel(true)
	
	drink_tween.tween_property(drink_ins, "position:y", -100.0, 1.0)
	drink_tween.tween_property(drink_ins, "modulate:a", 0.0, 0.8)
	await drink_tween.finished
	drink_ins.queue_free()
func _on_spawn_timer_timeout() -> void:
	var kloc_ins = klocek.instantiate()
	linia.add_child(kloc_ins)
	kloc_ins.position.x = 380
	kloc_ins.speed = 7
func arrows():
	if arr_tween:
		arr_tween.kill()
	arr1.position.y = -30
	arr2.position.y = 30
	arr_tween = get_tree().create_tween().set_parallel(true)
	arr_tween.tween_property(arr1, "position:y",-45.0,1.0)
	arr_tween.tween_property(arr2, "position:y",45.0,1.0)
	
	arr_tween.tween_property(arr1, "modulate",Color.WHITE,1.0)
	arr_tween.tween_property(arr2, "modulate",Color.WHITE,1.0)
	await arr_tween.finished
	arr_tween.kill()
func tween_self():
	scale = my_scale + Vector2(0.05,0.05)
	pucha.scale = pucha_scale + Vector2(0.05,0.05)
	var self_tween = get_tree().create_tween().set_parallel(true)
	self_tween.tween_property(self, "scale", my_scale,0.5)
	self_tween.tween_property(pucha, "scale", pucha_scale,0.5)
	await self_tween.finished
	self_tween.kill()
