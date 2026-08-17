class_name CharacterMilestones
extends Resource

@export_range(1, 99, 1) var basic_upgrade_level: int = 5
@export_range(1, 99, 1) var tactical_upgrade_level: int = 10
@export_range(1, 99, 1) var ultimate_upgrade_level: int = 15


func is_valid() -> bool:
	return basic_upgrade_level < tactical_upgrade_level and tactical_upgrade_level < ultimate_upgrade_level
