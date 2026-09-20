class_name EncounterArena
extends Node2D

signal soul_hit(damage: int)
signal soul_grazed

@export var bounds: Rect2 = Rect2(210, 265, 220, 130)
@export var shape: String = "rect"
@export var theme_color := Color(0.8, 0.8, 0.85)

@onready var soul: PlayerSoul = %PlayerSoul
@onready var bullets: Node2D = %Bullets

func _ready() -> void:
	soul.hit.connect(func(damage: int) -> void: soul_hit.emit(damage))
	soul.grazed.connect(func() -> void: soul_grazed.emit())
	soul.bounds = bounds
	soul.deactivate()

func _process(_delta: float) -> void:
	soul.bounds = bounds
	soul.bounds_shape = shape
	queue_redraw()

func start_phase() -> void:
	soul.activate()
	soul.position = bounds.get_center()
	_clear_bullets()

func end_phase() -> void:
	soul.deactivate()
	_clear_bullets()

func set_soul_frozen(value: bool) -> void:
	soul.frozen = value

func _clear_bullets() -> void:
	for child in bullets.get_children():
		child.queue_free()

func get_soul_global_position() -> Vector2:
	return soul.global_position

func spawn_bullet(scene: PackedScene, spawn_pos: Vector2, velocity: Vector2, damage: int = 1, glitch: bool = false, punchable: bool = false) -> Projectile:
	var bullet: Projectile = scene.instantiate()
	bullet.position = spawn_pos
	bullet.velocity = velocity
	bullet.damage = damage
	bullet.glitch_mode = glitch
	bullet.punchable = punchable
	bullets.add_child(bullet)
	return bullet

func _draw() -> void:
	if not soul.active:
		return
	if shape == "circle":
		var radius: float = min(bounds.size.x, bounds.size.y) / 2.0
		PanelStyle.draw_circle_panel(self, bounds.get_center(), radius, theme_color)
	elif shape == "teardrop":
		PanelStyle.draw_teardrop_panel(self, bounds, theme_color)
	else:
		PanelStyle.draw_rect_panel(self, bounds, theme_color)
