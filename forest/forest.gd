extends Node2D

const DIALOGUE_JSON := "res://forest/forest_dialogue.json"
const MUSHROOM_GIRL_ENCOUNTER := "res://encounters/mushroom_girl/mushroom_girl.tscn"
const STRAWBERRY_GIRL_ENCOUNTER := "res://encounters/strawberry_girl/strawberry_girl.tscn"
const IVY_ENCOUNTER := "res://encounters/ivy/ivy.tscn"
const NEXT_SCENE := "res://jungle/jungle.tscn"
const IDLE_FRAME_COUNT := 9
const DOG_IDLE_FRAME_COUNT := 9

const STRAWBERRY_GIRL_PORTRAIT := preload("res://forest/assets/strawberry_girl_portrait_frames.tres")
const IVY_PORTRAIT := preload("res://forest/assets/ivy_portrait_frames.tres")

const MUSHROOM_ITEM := preload("res://items/mushroom_cap.tres")
const STRAWBERRY_ITEM := preload("res://items/strawberry.tres")

const BARRIER_LEAD := 10.0
const BARRIER_SAFE_OFFSET := 30.0

@onready var player: OverworldPlayer = %Player
@onready var dialog_box: DialogBox = %DialogBox
@onready var menu: EncounterMenu = %EncounterMenu
@onready var bust: AnimatedSprite2D = %Bust
@onready var mushroom_girl_zone: InteractZone = %MushroomGirlZone
@onready var mushroom_girl_sprite: AnimatedSprite2D = %MushroomGirlSprite
@onready var mushroom_item_box: Sprite2D = %MushroomItemBox
@onready var strawberry_girl_zone: InteractZone = %StrawberryGirlZone
@onready var strawberry_girl_sprite: AnimatedSprite2D = %StrawberryGirlSprite
@onready var strawberry_item_box: Sprite2D = %StrawberryItemBox
@onready var ivy_zone: InteractZone = %IvyZone
@onready var ivy_sprite: AnimatedSprite2D = %IvySprite
@onready var forest_dog_zone: InteractZone = %ForestDogZone
@onready var forest_dog_sprite: AnimatedSprite2D = %ForestDogSprite
@onready var exit_trigger: EncounterTrigger = %ExitTrigger

var _runner: DialogueRunner
var _dialogue_tree: DialogueTree

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)
	MusicPlayer.ensure_playing_for_dev_test()
	exit_trigger.triggered.connect(_on_exit_triggered)

	_setup_npc(mushroom_girl_sprite, GameSettings.mushroom_girl_cleared, IDLE_FRAME_COUNT)
	_setup_npc(strawberry_girl_sprite, GameSettings.strawberry_girl_cleared, IDLE_FRAME_COUNT)
	_setup_npc(ivy_sprite, GameSettings.ivy_cleared, IDLE_FRAME_COUNT)
	mushroom_item_box.visible = GameSettings.mushroom_girl_cleared and not GameSettings.mushroom_item_collected
	strawberry_item_box.visible = GameSettings.strawberry_girl_cleared and not GameSettings.strawberry_item_collected
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(forest_dog_sprite, &"idle", DOG_IDLE_FRAME_COUNT, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

	if SaveSystem.has_pending_position():
		player.position = SaveSystem.consume_pending_position()

func _show_bust(frames: SpriteFrames) -> void:
	if frames == null:
		bust.visible = false
		return
	bust.sprite_frames = frames
	bust.play("idle")
	bust.visible = true

func _hide_bust() -> void:
	bust.visible = false

func _setup_npc(sprite: AnimatedSprite2D, cleared: bool, frame_count: int) -> void:
	if cleared:
		sprite.visible = false
		return
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(sprite, &"idle", frame_count, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func _collect_item(item: ItemData, box: Sprite2D, mark_collected: Callable) -> void:
	Inventory.add_item(item)
	mark_collected.call()
	box.visible = false

func _process(_delta: float) -> void:
	if dialog_box.active or menu.active:
		return
	if not GameSettings.mushroom_girl_cleared and player.position.y < mushroom_girl_zone.position.y - BARRIER_LEAD:
		_pull_back(mushroom_girl_zone.position)
		_on_mushroom_girl_triggered("mushroom_block")
		return
	if not GameSettings.strawberry_girl_cleared and player.position.y < strawberry_girl_zone.position.y - BARRIER_LEAD:
		_pull_back(strawberry_girl_zone.position)
		_on_strawberry_girl_triggered("strawberry_block")
		return
	if not GameSettings.ivy_cleared and player.position.y < ivy_zone.position.y - BARRIER_LEAD:
		_pull_back(ivy_zone.position)
		_on_ivy_triggered("ivy_block")
		return
	if not GameSettings.forest_dog_passed and player.position.y < forest_dog_zone.position.y - BARRIER_LEAD:
		_pull_back(forest_dog_zone.position)
		_on_forest_dog_triggered()
		return

func _pull_back(checkpoint_position: Vector2) -> void:
	player.position = checkpoint_position + Vector2(0, BARRIER_SAFE_OFFSET)
	player.velocity = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept") or dialog_box.active or menu.active:
		return
	if mushroom_girl_zone.is_player_inside:
		get_viewport().set_input_as_handled()
		if not GameSettings.mushroom_girl_cleared:
			_on_mushroom_girl_triggered()
		elif not GameSettings.mushroom_item_collected:
			_collect_item(MUSHROOM_ITEM, mushroom_item_box, GameSettings.mark_mushroom_item_collected)
	elif strawberry_girl_zone.is_player_inside:
		get_viewport().set_input_as_handled()
		if not GameSettings.strawberry_girl_cleared:
			_on_strawberry_girl_triggered()
		elif not GameSettings.strawberry_item_collected:
			_collect_item(STRAWBERRY_ITEM, strawberry_item_box, GameSettings.mark_strawberry_item_collected)
	elif ivy_zone.is_player_inside and not GameSettings.ivy_cleared:
		get_viewport().set_input_as_handled()
		_on_ivy_triggered()
	elif forest_dog_zone.is_player_inside and not GameSettings.forest_dog_passed:
		get_viewport().set_input_as_handled()
		_on_forest_dog_triggered()

func resync_rhythm() -> void:
	if not MusicPlayer.is_playing():
		return
	var bpm: float = MusicPlayer.get_bpm(MusicPlayer.current_track_id)
	for pair in [[mushroom_girl_sprite, GameSettings.mushroom_girl_cleared], [strawberry_girl_sprite, GameSettings.strawberry_girl_cleared], [ivy_sprite, GameSettings.ivy_cleared]]:
		var sprite: AnimatedSprite2D = pair[0]
		var cleared: bool = pair[1]
		if not cleared:
			RhythmSync.resync_if_needed(sprite, &"idle", IDLE_FRAME_COUNT, bpm)
	RhythmSync.resync_if_needed(forest_dog_sprite, &"idle", DOG_IDLE_FRAME_COUNT, bpm)

func _end_npc_dialogue() -> void:
	player.set_physics_process(true)
	_hide_bust()

func _on_dialogue_node(node: DialogueNode) -> void:
	match node.event:
		"mushroom_fight":
			SaveSystem.mark_pending_position(player.global_position)
			get_tree().change_scene_to_file(MUSHROOM_GIRL_ENCOUNTER)
		"strawberry_fight":
			SaveSystem.mark_pending_position(player.global_position)
			get_tree().change_scene_to_file(STRAWBERRY_GIRL_ENCOUNTER)
		"ivy_fight":
			SaveSystem.mark_pending_position(player.global_position)
			get_tree().change_scene_to_file(IVY_ENCOUNTER)
		"dog_give":
			Inventory.remove_item(MUSHROOM_ITEM)
			Inventory.remove_item(STRAWBERRY_ITEM)
			GameSettings.mark_forest_dog_passed()

func _start_dialogue(start_id: String) -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.node_entered.connect(_on_dialogue_node)
	_runner.finished.connect(_end_npc_dialogue)
	_runner.start(_dialogue_tree, start_id)

func _on_mushroom_girl_triggered(start_id: String = "mushroom_intro") -> void:
	_start_dialogue(start_id)

func _on_strawberry_girl_triggered(start_id: String = "strawberry_intro") -> void:
	_show_bust(STRAWBERRY_GIRL_PORTRAIT)
	_start_dialogue(start_id)

func _on_ivy_triggered(start_id: String = "ivy_intro") -> void:
	_show_bust(IVY_PORTRAIT)
	_start_dialogue(start_id)

func _on_forest_dog_triggered() -> void:
	if GameSettings.forest_dog_passed:
		return
	var has_mushroom := Inventory.get_count(MUSHROOM_ITEM) > 0
	var has_strawberry := Inventory.get_count(STRAWBERRY_ITEM) > 0
	if has_mushroom and has_strawberry:
		_start_dialogue("dog_offer")
	else:
		_start_dialogue("dog_refuse")

func _on_exit_triggered() -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.finished.connect(_on_exit_dialogue_finished)
	_runner.start(_dialogue_tree, "exit_line")

func _on_exit_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
