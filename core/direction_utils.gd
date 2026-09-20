class_name DirectionUtils
extends RefCounted

static func from_vector(dir: Vector2) -> String:
	if absf(dir.x) > absf(dir.y):
		return "east" if dir.x > 0 else "west"
	return "south" if dir.y > 0 else "north"
