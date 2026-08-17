extends Node

## Hooks are intentionally signal-only. Gameplay systems opt into them during
## development; production UI never depends on this singleton.
signal xp_award_requested(amount: int)
signal enemy_spawn_requested(enemy_id: StringName, count: int)
signal timer_jump_requested(target_seconds: float)
signal weapon_rank_requested(weapon_id: StringName, target_rank: int)


func request_xp_award(amount: int) -> void:
	xp_award_requested.emit(maxi(amount, 0))


func request_enemy_spawn(enemy_id: StringName, count: int = 1) -> void:
	enemy_spawn_requested.emit(enemy_id, maxi(count, 1))


func request_timer_jump(target_seconds: float) -> void:
	timer_jump_requested.emit(maxf(target_seconds, 0.0))


func request_weapon_rank(weapon_id: StringName, target_rank: int) -> void:
	weapon_rank_requested.emit(weapon_id, clampi(target_rank, 1, 5))
