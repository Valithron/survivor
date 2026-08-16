class_name WeaponDefinition
extends Resource

const MAX_RANK := 5

enum TargetingMode {
	NEAREST_ENEMY,
	FORWARD,
	AROUND_PLAYER,
	GROUND_AREA,
}

@export var weapon_id: StringName
@export var display_name: String
@export_multiline var summary: String
@export var targeting_mode: TargetingMode = TargetingMode.NEAREST_ENEMY
@export var runtime_scene: PackedScene
@export var icon: Texture2D
@export var ranks: Array[WeaponRankDefinition] = []


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if weapon_id.is_empty():
		errors.append("WeaponDefinition requires weapon_id.")
	if display_name.is_empty():
		errors.append("WeaponDefinition requires display_name.")
	if ranks.size() != MAX_RANK:
		errors.append("WeaponDefinition must define exactly five ranks.")
		return errors

	var seen_ranks: Dictionary = {}
	for rank_definition in ranks:
		if rank_definition == null:
			errors.append("WeaponDefinition contains a missing rank resource.")
			continue
		seen_ranks[rank_definition.rank] = true
	for expected_rank in range(1, MAX_RANK + 1):
		if not seen_ranks.has(expected_rank):
			errors.append("WeaponDefinition is missing Rank %d." % expected_rank)
	return errors


func get_rank_definition(rank: int) -> WeaponRankDefinition:
	for rank_definition in ranks:
		if rank_definition != null and rank_definition.rank == rank:
			return rank_definition
	return null
