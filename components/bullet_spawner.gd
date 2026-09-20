class_name BulletSpawner
extends Node2D

var arena: EncounterArena
var projectile_scene: PackedScene
@export var projectile_speed: float = 100.0
@export var projectile_damage: int = 1

func spawn_from_top() -> void:
	var b: Rect2 = arena.bounds
	var x: float = b.position.x + randf_range(10, b.size.x - 10)
	var spawn_pos := Vector2(x, b.position.y - 12)
	arena.spawn_bullet(projectile_scene, spawn_pos, Vector2(0, projectile_speed), projectile_damage)

func spawn_from_side() -> void:
	var b: Rect2 = arena.bounds
	var from_left: bool = randi() % 2 == 0
	var y: float = b.position.y + randf_range(10, b.size.y - 10)
	var x: float = (b.position.x - 12) if from_left else (b.position.x + b.size.x + 12)
	var dir: float = 1.0 if from_left else -1.0
	arena.spawn_bullet(projectile_scene, Vector2(x, y), Vector2(projectile_speed * dir, 0), projectile_damage)

func spawn_from_rim() -> void:
	var b: Rect2 = arena.bounds
	var center: Vector2 = b.get_center()
	var radius: float = min(b.size.x, b.size.y) / 2.0
	var angle: float = randf_range(0.0, TAU)
	var rim_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * (radius + 12.0)
	var dir: Vector2 = (center - rim_pos).normalized()
	arena.spawn_bullet(projectile_scene, rim_pos, dir * projectile_speed, projectile_damage)

func spawn_ring_burst(count: int) -> void:
	var b: Rect2 = arena.bounds
	var center: Vector2 = b.get_center()
	for i in count:
		var angle: float = TAU * float(i) / float(count)
		var dir_vec := Vector2(cos(angle), sin(angle))
		arena.spawn_bullet(projectile_scene, center, dir_vec * projectile_speed, projectile_damage)

func spawn_static_burst(count: int) -> void:
	var b: Rect2 = arena.bounds
	for _i in count:
		var edge: int = randi() % 4
		var spawn_pos: Vector2
		var dir: Vector2
		match edge:
			0:
				spawn_pos = Vector2(b.position.x + randf_range(10, b.size.x - 10), b.position.y - 10)
				dir = Vector2(randf_range(-0.4, 0.4), 1.0)
			1:
				spawn_pos = Vector2(b.position.x + randf_range(10, b.size.x - 10), b.position.y + b.size.y + 10)
				dir = Vector2(randf_range(-0.4, 0.4), -1.0)
			2:
				spawn_pos = Vector2(b.position.x - 10, b.position.y + randf_range(10, b.size.y - 10))
				dir = Vector2(1.0, randf_range(-0.4, 0.4))
			_:
				spawn_pos = Vector2(b.position.x + b.size.x + 10, b.position.y + randf_range(10, b.size.y - 10))
				dir = Vector2(-1.0, randf_range(-0.4, 0.4))
		arena.spawn_bullet(projectile_scene, spawn_pos, dir.normalized() * projectile_speed, projectile_damage, true)

func spawn_ice_gap(top_scene: PackedScene, bottom_scene: PackedScene, gap_top: float, gap_bottom: float, speed: float, damage: int) -> void:
	var b: Rect2 = arena.bounds
	var x: float = b.position.x + b.size.x + 12
	var velocity := Vector2(-speed, 0)
	var top_length: float = gap_top - b.position.y
	if top_length > 0.0:
		var top_spike: Projectile = top_scene.instantiate()
		top_spike.position = Vector2(x, b.position.y)
		top_spike.velocity = velocity
		top_spike.damage = damage
		top_spike.configure_span(top_length, true)
		arena.bullets.add_child(top_spike)
	var bottom_length: float = (b.position.y + b.size.y) - gap_bottom
	if bottom_length > 0.0:
		var bottom_spike: Projectile = bottom_scene.instantiate()
		bottom_spike.position = Vector2(x, b.position.y + b.size.y)
		bottom_spike.velocity = velocity
		bottom_spike.damage = damage
		bottom_spike.configure_span(bottom_length, false)
		arena.bullets.add_child(bottom_spike)
