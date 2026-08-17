class_name DamageEvent
extends RefCounted

## Immutable-by-convention payload passed into HealthComponent.apply_damage().
## `tag` is intentionally lightweight; no resistance/status taxonomy exists yet.
var source: Object
var amount: float
var tag: StringName
var knockback: Vector2
var metadata: Dictionary


func _init(
		damage_source: Object = null,
		damage_amount: float = 0.0,
		damage_tag: StringName = &"generic",
		damage_knockback: Vector2 = Vector2.ZERO,
		extra_metadata: Dictionary = {}
	) -> void:
	source = damage_source
	amount = maxf(damage_amount, 0.0)
	tag = damage_tag
	knockback = damage_knockback
	metadata = extra_metadata.duplicate(true)


func is_valid() -> bool:
	return amount > 0.0
