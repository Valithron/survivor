class_name AnimationConvention
extends RefCounted

## Direction identifiers are screen-space and are deliberately shared by player
## and enemy sprite scenes. Art import may mirror compatible source frames.
const DIRECTIONS: PackedStringArray = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]


static func direction_id(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"s"
	var angle := direction.angle()
	var octant := int(round(angle / (TAU / 8.0)))
	var direction_index := posmod(octant + 2, DIRECTIONS.size())
	return StringName(DIRECTIONS[direction_index])


static func player_animation(action: StringName, direction: Vector2) -> StringName:
	return StringName("%s_%s" % [action, direction_id(direction)])
