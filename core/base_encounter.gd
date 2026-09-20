class_name BaseEncounter
extends Node2D

signal state_changed(new_state: int)
signal player_hp_changed(current: int, max_hp: int)
signal enemy_hp_changed(current: int, max_hp: int)
signal won
signal lost
signal spared

enum State { INTRO, PLAYER_TURN, ENEMY_PHASE, RESOLVE }

const FloatingTextScene := preload("res://components/floating_text.tscn")
const GrazeSparkScene := preload("res://components/graze_spark.tscn")
const START_FIGHT_LABEL := "Fight"

@export var data: EncounterData

var state: State = State.INTRO
var player_hp: int = 0
var enemy_hp: int = 0

var _after_dialog: Callable = Callable()

@onready var dialog_box: DialogBox = %DialogBox
@onready var menu: EncounterMenu = %EncounterMenu
@onready var arena: EncounterArena = %EncounterArena
@onready var hud: EncounterHud = %EncounterHud
@onready var enemy_sprite: AnimatedSprite2D = %EnemySprite
@onready var end_screen: EndScreen = %EndScreen
@onready var inventory_menu: InventoryMenu = %InventoryMenu
@onready var background: ThemeBackdrop = %Background
@onready var ambient_dust: AmbientDust = %AmbientDustBg

var _item_used_callback: Callable = Callable()
var _item_cancelled_callback: Callable = Callable()

var _in_intro_choices := false

var _past_intro := false

func _ready() -> void:
	SaveSystem.save_autosave()
	player_hp = data.player_max_hp
	enemy_hp = data.enemy_max_hp
	if data.enemy_frames:
		enemy_sprite.sprite_frames = data.enemy_frames
		enemy_sprite.play("idle")
	hud.set_enemy_name(data.enemy_name)
	hud.set_player_hp(player_hp, data.player_max_hp)
	hud.set_enemy_hp(enemy_hp, data.enemy_max_hp)
	_apply_theme(data.theme_color)
	_refresh_screen_mode()
	dialog_box.finished.connect(_on_dialog_finished)
	menu.option_selected.connect(_on_menu_option_selected)
	arena.soul_hit.connect(_on_soul_hit)
	arena.soul_grazed.connect(_on_soul_grazed)
	say(data.intro_lines, _start_intro_choices)

func _apply_theme(theme_color: Color) -> void:
	menu.theme_color = theme_color
	arena.theme_color = theme_color
	hud.enemy_name_color = theme_color
	hud.enemy_bar_color = theme_color
	background.theme_color = theme_color
	ambient_dust.modulate = theme_color

func _refresh_screen_mode() -> void:
	var combat_mode: bool = _past_intro and not dialog_box.active
	menu.combat_mode = combat_mode
	background.combat_mode = combat_mode
	ambient_dust.visible = combat_mode

func say(lines: Array[String], on_finished: Callable = Callable()) -> void:
	_after_dialog = on_finished
	dialog_box.show_lines(lines)
	_refresh_screen_mode()

func _on_dialog_finished() -> void:
	if _after_dialog.is_valid():
		var callback := _after_dialog
		_after_dialog = Callable()
		callback.call()
	_refresh_screen_mode()

func _change_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)

func _start_player_turn() -> void:
	_change_state(State.PLAYER_TURN)
	_past_intro = true
	hud.set_enemy_hp_visible(true)
	menu.set_options(data.menu_labels)
	menu.show_menu()
	_refresh_screen_mode()

func _start_intro_choices() -> void:
	if data.intro_choices.is_empty():
		_start_player_turn()
		return
	_in_intro_choices = true
	_show_intro_choice_menu()

func _show_intro_choice_menu() -> void:
	var labels: Array[String] = []
	for choice in data.intro_choices:
		labels.append(choice.question)
	labels.append(START_FIGHT_LABEL)
	menu.set_options(labels)
	menu.show_menu()

func _on_intro_choice_selected(index: int) -> void:
	if index == data.intro_choices.size():
		_in_intro_choices = false
		_start_player_turn()
		return
	var choice: DialogueChoice = data.intro_choices[index]
	say(choice.response_lines, _show_intro_choice_menu)

func _on_menu_option_selected(index: int) -> void:
	menu.hide_menu()
	if _in_intro_choices:
		_on_intro_choice_selected(index)
	else:
		_handle_menu_option(index)

func _handle_menu_option(_index: int) -> void:
	push_warning("BaseEncounter._handle_menu_option not overridden")

func start_enemy_phase() -> void:
	_change_state(State.ENEMY_PHASE)
	arena.start_phase()

func end_enemy_phase(on_finished: Callable) -> void:
	arena.end_phase()
	if player_hp <= 0:
		_lose()
	else:
		on_finished.call()

func deal_damage_to_enemy(amount: int) -> void:
	enemy_hp = max(0, enemy_hp - amount)
	enemy_hp_changed.emit(enemy_hp, data.enemy_max_hp)
	hud.set_enemy_hp(enemy_hp, data.enemy_max_hp)
	_spawn_floating_text("-%d" % amount, to_local(enemy_sprite.global_position) + Vector2(0, -50), Color(1, 1, 0.3))
	_play_enemy_hurt_reaction()
	_screen_shake(6.0, 0.2)

func _play_enemy_hurt_reaction() -> void:
	var flash_tween := create_tween()
	enemy_sprite.modulate = Color(4, 4, 4)
	flash_tween.tween_property(enemy_sprite, "modulate", Color(1, 1, 1), 0.25)

	var recoil_tween := create_tween()
	var base_pos: Vector2 = enemy_sprite.position
	recoil_tween.tween_property(enemy_sprite, "position", base_pos + Vector2(0, 8), 0.06)
	recoil_tween.tween_property(enemy_sprite, "position", base_pos, 0.12)

	if enemy_sprite.sprite_frames and enemy_sprite.sprite_frames.has_animation("hurt"):
		enemy_sprite.play("hurt")
		await enemy_sprite.animation_finished
		if enemy_sprite.sprite_frames:
			enemy_sprite.play("idle")
			if has_method("resync_rhythm"):
				call("resync_rhythm")

func _spawn_floating_text(text: String, local_pos: Vector2, color: Color) -> void:
	var floating: FloatingText = FloatingTextScene.instantiate()
	floating.setup(text, color)
	floating.position = local_pos
	add_child(floating)

func _screen_shake(strength: float = 6.0, duration: float = 0.2) -> void:
	var tween := create_tween()
	var steps := 5
	for _i in steps:
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(self, "position", offset, duration / steps)
	tween.tween_property(self, "position", Vector2.ZERO, duration / steps)

func open_item_menu(on_used: Callable, on_cancelled: Callable) -> void:
	_item_used_callback = on_used
	_item_cancelled_callback = on_cancelled
	inventory_menu.item_selected.connect(_on_item_selected, CONNECT_ONE_SHOT)
	inventory_menu.cancelled.connect(_on_item_menu_cancelled, CONNECT_ONE_SHOT)
	inventory_menu.open(false, true)

func _on_item_selected(item: ItemData) -> void:
	if inventory_menu.cancelled.is_connected(_on_item_menu_cancelled):
		inventory_menu.cancelled.disconnect(_on_item_menu_cancelled)
	inventory_menu.close()
	Inventory.remove_item(item)
	var healed: int = heal_player(item.heal_amount)
	var callback := _item_used_callback
	_item_used_callback = Callable()
	callback.call(item, healed)

func _on_item_menu_cancelled() -> void:
	if inventory_menu.item_selected.is_connected(_on_item_selected):
		inventory_menu.item_selected.disconnect(_on_item_selected)
	inventory_menu.close()
	var callback := _item_cancelled_callback
	_item_cancelled_callback = Callable()
	callback.call()

func heal_player(amount: int) -> int:
	var healed: int = min(amount, data.player_max_hp - player_hp)
	player_hp += healed
	player_hp_changed.emit(player_hp, data.player_max_hp)
	hud.set_player_hp(player_hp, data.player_max_hp)
	return healed

func _on_soul_hit(damage: int) -> void:
	if state != State.ENEMY_PHASE:
		return
	player_hp = max(0, player_hp - damage)
	player_hp_changed.emit(player_hp, data.player_max_hp)
	hud.set_player_hp(player_hp, data.player_max_hp)
	_spawn_floating_text("-%d" % damage, to_local(arena.get_soul_global_position()) + Vector2(0, -18), Color(1, 0.4, 0.4))
	_screen_shake(4.0, 0.15)

func _on_soul_grazed() -> void:
	var spark: GrazeSpark = GrazeSparkScene.instantiate()
	spark.position = to_local(arena.get_soul_global_position())
	add_child(spark)

func _win() -> void:
	_change_state(State.RESOLVE)
	won.emit()
	_show_end_screen("VICTORY", ["Continue"], [true], _on_end_screen_continue)

func _lose() -> void:
	_change_state(State.RESOLVE)
	lost.emit()
	_show_end_screen("GAME OVER", ["Try Again", "Load Save", "Exit"], [true, SaveSystem.has_any_manual_save(), true], _on_game_over_option)

func _spare() -> void:
	_change_state(State.RESOLVE)
	spared.emit()
	_show_end_screen("SPARED", ["Continue"], [true], _on_end_screen_continue)

func _show_end_screen(title: String, options: Array[String], enabled: Array[bool], on_option: Callable) -> void:
	dialog_box.active = false
	dialog_box.visible = false
	menu.hide_menu()
	end_screen.option_selected.connect(on_option, CONNECT_ONE_SHOT)
	end_screen.show_screen(title, options, enabled)

func _on_end_screen_continue(_index: int) -> void:
	get_tree().change_scene_to_file(data.return_scene)

func _on_game_over_option(index: int) -> void:
	match index:
		0:
			SaveSystem.load_autosave()
		1:
			GlobalMenu.open_load_menu()
		2:
			get_tree().change_scene_to_file("res://menu/main_menu.tscn")
