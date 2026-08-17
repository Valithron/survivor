class_name ChainLightningRuntime
extends SharedWeaponRuntime

signal chain_fired(points: PackedVector2Array, hit_count: int)

var _tuning: Dictionary = {}
var _cooldown_remaining := 0.0

func _process(delta: float) -> void:
	if current_rank <= 0:
		return
	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		fire_chains()

func force_attack() -> bool:
	return fire_chains()

func _on_rank_applied(rank_definition: WeaponRankDefinition) -> void:
	_tuning = rank_definition.tuning.duplicate(true)
	_cooldown_remaining = minf(_cooldown_remaining, _cooldown())

func fire_chains() -> bool:
	var origin := _owner_position()
	var initial_targets := WeaponTargeting.nearby_targets(self, origin, _range())
	if initial_targets.is_empty():
		_cooldown_remaining = 0.1
		return false
	_cooldown_remaining = _cooldown()
	var used_ids: Dictionary = {}
	var total_hits := 0
	for chain_index in range(_chain_volley_count()):
		var start_target := _first_unused(initial_targets, used_ids)
		if start_target == null:
			break
		var points := _fire_one_chain(origin, start_target, used_ids)
		total_hits += points.size() - 1
		_spawn_effect(points)
		chain_fired.emit(points, points.size() - 1)
	return total_hits > 0

func _fire_one_chain(origin: Vector2, start_target: Node2D, used_ids: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array([origin])
	var current := start_target
	var current_damage := _damage()
	for _jump in range(_chain_count()):
		if current == null:
			break
		var instance_id := current.get_instance_id()
		if used_ids.has(instance_id):
			break
		used_ids[instance_id] = true
		WeaponTargeting.apply_damage(current, self, current_damage, &"shared_weapon_chain_lightning")
		points.append(current.global_position)
		current_damage *= _damage_decay()
		current = _first_unused(WeaponTargeting.nearby_targets(self, points[-1], _jump_range()), used_ids)
	return points

func _first_unused(candidates: Array[Node2D], used_ids: Dictionary) -> Node2D:
	for candidate in candidates:
		if not used_ids.has(candidate.get_instance_id()):
			return candidate
	return null

func _spawn_effect(points: PackedVector2Array) -> void:
	if points.size() < 2 or get_parent() == null:
		return
	var effect := ChainLightningEffect.new()
	get_parent().add_child(effect)
	effect.configure(points, 0.12)

func _owner_position() -> Vector2: return (weapon_owner as Node2D).global_position if weapon_owner is Node2D else Vector2.ZERO
func _cooldown() -> float: return maxf(float(_tuning.get("cooldown", 1.0)), 0.01)
func _range() -> float: return maxf(float(_tuning.get("range", 400.0)), 1.0)
func _jump_range() -> float: return maxf(float(_tuning.get("jump_range", 140.0)), 1.0)
func _damage() -> float: return maxf(float(_tuning.get("damage", 0.0)), 0.0)
func _damage_decay() -> float: return clampf(float(_tuning.get("damage_decay", 0.85)), 0.01, 1.0)
func _chain_count() -> int: return maxi(int(_tuning.get("chain_count", 2)), 1)
func _chain_volley_count() -> int: return maxi(int(_tuning.get("chain_volley_count", 1)), 1)
