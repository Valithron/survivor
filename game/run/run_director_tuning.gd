class_name RunDirectorTuning
extends Resource

## Initial R1 intensity values. The fixed event schedule is locked; these
## multipliers remain editable balance data for later full-run playtests.
@export_category("Baseline")
@export_range(0.0, 10.0, 0.05) var baseline_swarm_intensity := 1.0
@export_range(0.0, 10.0, 0.05) var baseline_fast_intensity := 0.0
@export_range(0.0, 10.0, 0.05) var baseline_tank_intensity := 0.0
@export_category("Surges")
@export_range(0.0, 10.0, 0.05) var swarm_surge_swarm_intensity := 1.75
@export_range(0.0, 10.0, 0.05) var fast_surge_swarm_intensity := 0.85
@export_range(0.0, 10.0, 0.05) var fast_surge_fast_intensity := 1.45
@export_range(0.0, 10.0, 0.05) var tank_surge_swarm_intensity := 0.75
@export_range(0.0, 10.0, 0.05) var tank_surge_fast_intensity := 0.8
@export_range(0.0, 10.0, 0.05) var tank_surge_tank_intensity := 1.15
@export_range(0.0, 10.0, 0.05) var combined_swarm_intensity := 1.25
@export_range(0.0, 10.0, 0.05) var combined_fast_intensity := 1.25
@export_range(0.0, 10.0, 0.05) var combined_tank_intensity := 1.25
