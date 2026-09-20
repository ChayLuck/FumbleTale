extends BaseEncounter

const SWEET_FRAMES := preload("res://encounters/cafe_girl/girl_sweet_frames.tres")
const PSYCHO_FRAMES := preload("res://encounters/cafe_girl/girl_psycho_frames.tres")
const MAX_TURNS := 5

enum Mood { SWEET, AMUSED, UNSETTLED, PSYCHO }

const FLIRT_LINES := {
	Mood.SWEET: ["She giggles, cheeks going pink. \"Ohh, you're bold for a first date.\""],
	Mood.AMUSED: ["Her laugh gets a little sharper. \"Keep going. I like that you're not scared of me yet.\""],
	Mood.UNSETTLED: ["She laughs too long, too loud. \"Does it feel good, hurting something that keeps smiling back?\""],
	Mood.PSYCHO: ["She's laughing with tears in her eyes, and she still won't stop smiling. \"MORE. Please. I'll remember this one.\""],
}

const MERCY_LINES := {
	Mood.SWEET: ["\"Aww, sparing me already?\" She pats the seat next to her. \"That's sweet. But we're just getting started.\""],
	Mood.AMUSED: ["\"Mercy? Here?\" She laughs behind her hand. \"Cute. Try again.\""],
	Mood.UNSETTLED: ["Her smile doesn't move, but something behind her eyes does. \"You don't get to decide when this is over.\""],
	Mood.PSYCHO: ["She's not even looking at you anymore, just laughing at something only she can see. \"Mercy's not on the menu, sweetheart.\""],
}

const TALK_LINES := {
	Mood.SWEET: ["She tilts her head, voice honey-soft.", "\"You don't have to keep doing this, you know. Nobody would blame you for just... stopping.\"", "\"So? What do you say?\""],
	Mood.AMUSED: ["She leans in, grinning wider than before.", "\"It's cute that you think this ends if you just try hard enough. It doesn't. It ends when I say it does.\"", "\"Wouldn't it be so much easier to just let go?\""],
	Mood.UNSETTLED: ["Her voice drops, almost tender, almost cruel.", "\"I could stop. Right now. All you'd have to do is ask nicely — beg a little.\"", "\"Come on. Give up for me.\""],
	Mood.PSYCHO: ["She's laughing and crying at the same time now, mascara running like ink.", "\"Please give up. PLEASE. I don't— I don't know what happens if you don't.\"", "\"Just say it. Say you're done.\""],
}

const KEEP_GOING_LINES := {
	Mood.SWEET: ["\"Okay then~\" She smiles like nothing happened."],
	Mood.AMUSED: ["\"Stubborn. I can work with stubborn.\""],
	Mood.UNSETTLED: ["\"...Fine. Have it your way.\" Something flickers behind her smile."],
	Mood.PSYCHO: ["\"OKAY! Okay okay okay—\" She claps once, delighted."],
}

var turn_count := 0
var _awaiting_give_up_choice := false

func _lines_for(pool: Dictionary, mood: Mood) -> Array[String]:
	var result: Array[String] = []
	result.assign(pool[mood])
	return result

func _ready() -> void:
	super._ready()
	AnimPacing.apply(enemy_sprite, [PSYCHO_FRAMES])
	_update_mood_visual()

func _mood() -> Mood:
	if enemy_hp <= 1:
		return Mood.PSYCHO
	elif enemy_hp <= 7:
		return Mood.UNSETTLED
	elif enemy_hp <= 14:
		return Mood.AMUSED
	else:
		return Mood.SWEET

func _update_mood_visual() -> void:
	var target_frames: SpriteFrames = PSYCHO_FRAMES if enemy_hp <= 7 else SWEET_FRAMES
	if enemy_sprite.sprite_frames != target_frames:
		enemy_sprite.sprite_frames = target_frames
		enemy_sprite.play("idle")
	enemy_sprite.modulate = Color(1.3, 0.65, 0.75) if enemy_hp <= 1 else Color(1, 1, 1)

func _handle_menu_option(index: int) -> void:
	if _awaiting_give_up_choice:
		_awaiting_give_up_choice = false
		_on_give_up_choice(index)
		return
	match index:
		0: _do_flirt()
		1: _do_talk()
		2: _do_item()
		3: _do_mercy()

func _do_flirt() -> void:
	var dmg: int = min(randi_range(3, 6), max(enemy_hp - 1, 0))
	if dmg > 0:
		deal_damage_to_enemy(dmg)
	_update_mood_visual()
	say(_lines_for(FLIRT_LINES, _mood()), _advance_turn)

func _do_mercy() -> void:
	say(_lines_for(MERCY_LINES, _mood()), _advance_turn)

func _do_talk() -> void:
	say(_lines_for(TALK_LINES, _mood()), _show_give_up_prompt)

func _show_give_up_prompt() -> void:
	_awaiting_give_up_choice = true
	menu.set_options(["Give up", "Keep going"])
	menu.show_menu()

func _on_give_up_choice(index: int) -> void:
	if index == 0:
		_give_up_ending()
	else:
		say(_lines_for(KEEP_GOING_LINES, _mood()), _advance_turn)

func _do_item() -> void:
	open_item_menu(_on_item_used, _start_player_turn)

func _on_item_used(item: ItemData, healed: int) -> void:
	say(["You used %s. Healed %d HP." % [item.item_name, healed]], _advance_turn)

func _advance_turn() -> void:
	turn_count += 1
	if turn_count >= MAX_TURNS:
		_special_ending()
	else:
		_start_player_turn()

func _give_up_ending() -> void:
	_change_state(State.RESOLVE)
	say([
		"\"...Thank you,\" she breathes, and for a second she almost looks sad.",
		"Then the smile comes back, wider than before.",
		"\"That's all I needed.\"",
		"The lights over the bar flicker. She's still smiling when she reaches for you.",
	], _play_special_ending_effect)

func _special_ending() -> void:
	_change_state(State.RESOLVE)
	say([
		"\"Five,\" she whispers, counting on her fingers like it's a nursery rhyme.",
		"\"That's the number, silly. Didn't anyone tell you?\"",
		"The lights over the bar flicker. Once. Twice.",
		"She's still smiling when she reaches for you.",
	], _play_special_ending_effect)

func _play_special_ending_effect() -> void:
	_screen_shake(14.0, 0.6)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.05, 0.0, 0.05), 1.2)
	tween.tween_callback(_go_to_next_chapter)

func _go_to_next_chapter() -> void:
	get_tree().change_scene_to_file("res://school/classroom.tscn")
