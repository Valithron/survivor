class_name BossDefinition
extends Resource

## B1's one boss contract. This is deliberately a single data object rather
## than a generic enemy hierarchy because the locked moveset is unique.
@export var boss_id: StringName = &"mutant_colossus"
@export var display_name := "Mutant Colossus"
@export_multiline var archetype_summary := "Huge asymmetrical multi-mutated zombie with an oversized arm."
@export_range(1.0, 100000.0, 1.0) var maximum_health := 2200.0
@export_range(1.0, 1000.0, 1.0) var move_speed := 62.0
@export_range(1.0, 512.0, 1.0) var collision_radius := 58.0
@export_range(0.0, 1000.0, 0.1) var contact_damage_per_second := 13.0
@export_range(0.0, 1000.0, 0.1) var attack_cooldown_seconds := 2.5
@export_range(1.0, 1000.0, 1.0) var attack_trigger_distance := 360.0
@export_range(0.0, 1000.0, 0.1) var ground_slam_damage := 28.0
@export_range(1.0, 1200.0, 1.0) var ground_slam_radius := 190.0
@export_range(0.1, 10.0, 0.05) var ground_slam_windup_seconds := 1.15
@export_range(0.0, 1000.0, 0.1) var sweep_damage := 24.0
@export_range(1.0, 1200.0, 1.0) var sweep_range := 270.0
@export_range(5.0, 355.0, 1.0) var sweep_angle_degrees := 118.0
@export_range(0.1, 10.0, 0.05) var sweep_windup_seconds := 1.0
@export_range(0.0, 1000.0, 0.1) var charge_damage := 31.0
@export_range(1.0, 2000.0, 1.0) var charge_distance := 470.0
@export_range(1.0, 4000.0, 1.0) var charge_speed := 610.0
@export_range(0.1, 10.0, 0.05) var charge_windup_seconds := 1.25
@export_range(0.1, 10.0, 0.05) var charge_max_seconds := 1.1
@export var visual_scene: PackedScene

