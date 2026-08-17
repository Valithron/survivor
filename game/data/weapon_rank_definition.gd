class_name WeaponRankDefinition
extends Resource

@export_range(1, 5, 1) var rank: int = 1
@export_multiline var summary: String
## Rank-specific numbers live here once W0 establishes behavior. The flexible
## dictionary avoids prematurely imposing one schema on very different weapons.
@export var tuning: Dictionary = {}
