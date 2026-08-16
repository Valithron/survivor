class_name CoreHud
extends Control

## Compact pixel-styled U1 combat HUD. It reads public player/progression/
## inventory state and intentionally contains no weapon, spawning, or run-rule
## decisions of its own.
var _player: Node2D
var _player_health: HealthComponent
var _progression: ProgressionController
var _inventory: WeaponInventory
var _message := "Combat online. Clear zombies, collect XP, and choose weapons."


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(player: Node2D, progression: ProgressionController, inventory: WeaponInventory) -> void:
	_player = player
	_player_health = player.get_node_or_null(^"HealthComponent") as HealthComponent if player != null else null
	_progression = progression
	_inventory = inventory


func set_message(message: String) -> void:
	_message = message


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _player == null or _player_health == null or _progression == null or _inventory == null:
		return
	var font := ThemeDB.fallback_font
	_draw_panel(Rect2(20.0, 20.0, 330.0, 144.0))
	var active_character := RunController.active_character
	var identity := "%s // %s" % [
		active_character.display_name.to_upper() if active_character != null else "SURVIVOR",
		active_character.archetype_summary.split(":")[0].to_upper() if active_character != null else "ACTIVE RUN",
	]
	_draw_text(font, Vector2(36.0, 47.0), identity, 16, Color(0.73, 0.92, 1.0))
	_draw_text(font, Vector2(36.0, 72.0), "HEALTH", 13, Color(0.83, 0.9, 0.94))
	_draw_meter(Rect2(104.0, 59.0, 225.0, 16.0), _player_health.health_ratio(), Color(0.88, 0.24, 0.25), Color(0.32, 0.055, 0.08))
	_draw_text(font, Vector2(108.0, 73.0), "%d / %d" % [roundi(_player_health.current_health), roundi(_player_health.maximum_health)], 12, Color.WHITE)
	var threshold := _progression.definition.total_xp_required_for_level(_progression.current_level + 1) if _progression.definition != null else 1
	var previous_threshold := _progression.definition.total_xp_required_for_level(_progression.current_level) if _progression.definition != null else 0
	var xp_ratio := clampf(float(_progression.total_xp - previous_threshold) / maxf(float(threshold - previous_threshold), 1.0), 0.0, 1.0)
	_draw_text(font, Vector2(36.0, 103.0), "LEVEL %02d" % _progression.current_level, 16, Color(1.0, 0.79, 0.34))
	_draw_meter(Rect2(36.0, 112.0, 293.0, 13.0), xp_ratio, Color(0.25, 0.84, 0.98), Color(0.05, 0.18, 0.28))
	_draw_text(font, Vector2(36.0, 145.0), "XP %d / %d" % [_progression.total_xp, threshold], 12, Color(0.83, 0.92, 0.97))

	_draw_panel(Rect2(1016.0, 20.0, 244.0, 98.0))
	_draw_text(font, Vector2(1034.0, 48.0), "RUN %s / 12:00" % _format_time(RunController.elapsed_seconds), 18, Color(1.0, 0.85, 0.51))
	_draw_text(font, Vector2(1034.0, 75.0), "AIM  %s" % ("MANUAL" if _player_manual_aim_enabled() else "AUTO"), 13, Color(0.72, 0.91, 1.0))
	_draw_text(font, Vector2(1034.0, 99.0), "FIRE %.1f / SEC" % _player_float_method(&"get_current_fire_rate"), 13, Color(0.92, 0.95, 0.98))

	var tactical_label := "Q  %s" % (active_character.tactical.display_name.to_upper() if active_character != null and active_character.tactical != null else "TACTICAL")
	var ultimate_label := "E  %s" % (active_character.ultimate.display_name.to_upper() if active_character != null and active_character.ultimate != null else "ULTIMATE")
	_draw_ability(font, Rect2(20.0, 180.0, 160.0, 52.0), tactical_label, _player_float_property(&"tactical_cooldown_remaining"), _is_tactical_active())
	_draw_ability(font, Rect2(190.0, 180.0, 160.0, 52.0), ultimate_label, _player_float_property(&"ultimate_cooldown_remaining"), _player_bool_method(&"is_ultimate_active"))

	_draw_text(font, Vector2(20.0, 562.0), "LOADOUT // 4 SHARED SLOTS", 14, Color(0.78, 0.9, 0.98))
	var entries := _inventory.get_entries()
	for index in range(WeaponInventory.MAX_SHARED_WEAPON_SLOTS):
		var slot_rect := Rect2(20.0 + 166.0 * index, 574.0, 156.0, 78.0)
		_draw_panel(slot_rect, Color(0.022, 0.055, 0.09, 0.92))
		if index < entries.size():
			var entry := entries[index]
			_draw_text(font, slot_rect.position + Vector2(11.0, 28.0), entry.definition.display_name.to_upper(), 14, Color(0.98, 0.9, 0.7))
			_draw_text(font, slot_rect.position + Vector2(11.0, 55.0), "RANK %d / 5" % entry.current_rank, 13, Color(0.72, 0.91, 1.0))
		else:
			_draw_text(font, slot_rect.position + Vector2(11.0, 42.0), "EMPTY", 14, Color(0.38, 0.49, 0.57))

	_draw_panel(Rect2(370.0, 650.0, 890.0, 50.0), Color(0.022, 0.055, 0.09, 0.86))
	_draw_text(font, Vector2(388.0, 680.0), _message, 14, Color(0.86, 0.94, 0.97))
	_draw_text(font, Vector2(388.0, 695.0), "WASD MOVE   MOUSE AIM   T AIM MODE   Q TACTICAL   E ULTIMATE   ESC PAUSE", 11, Color(0.5, 0.69, 0.79))


func _player_manual_aim_enabled() -> bool:
	return bool(_player.get(&"manual_aim_enabled")) if _player != null else false


func _player_float_method(method: StringName) -> float:
	return float(_player.call(method)) if _player != null and _player.has_method(method) else 0.0


func _player_bool_method(method: StringName) -> bool:
	return bool(_player.call(method)) if _player != null and _player.has_method(method) else false


func _player_float_property(property_name: StringName) -> float:
	if _player == null:
		return 0.0
	var value: Variant = _player.get(property_name)
	return float(value) if value is float or value is int else 0.0


func _is_tactical_active() -> bool:
	if _player == null:
		return false
	if _player.has_method(&"is_charging") and bool(_player.call(&"is_charging")):
		return true
	if _player.has_method(&"is_overclock_active") and bool(_player.call(&"is_overclock_active")):
		return true
	return _player_float_property(&"fire_rate_buff_remaining") > 0.0


func _draw_panel(rect: Rect2, fill: Color = Color(0.016, 0.04, 0.072, 0.91)) -> void:
	draw_rect(rect, Color(0.15, 0.64, 0.84, 0.5), false, 2.0)
	draw_rect(rect.grow(-3.0), fill, true)


func _draw_meter(rect: Rect2, ratio: float, fill_color: Color, empty_color: Color) -> void:
	draw_rect(rect, Color(0.008, 0.015, 0.03, 0.95), true)
	draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), Vector2((rect.size.x - 4.0) * clampf(ratio, 0.0, 1.0), rect.size.y - 4.0)), fill_color, true)
	draw_rect(rect, empty_color, false, 1.0)


func _draw_ability(font: Font, rect: Rect2, label: String, cooldown_remaining: float, active: bool) -> void:
	_draw_panel(rect, Color(0.03, 0.075, 0.11, 0.94))
	var state := "ACTIVE" if active else ("READY" if cooldown_remaining <= 0.0 else "%.1fs" % cooldown_remaining)
	var color := Color(0.32, 1.0, 0.84) if active or cooldown_remaining <= 0.0 else Color(0.74, 0.82, 0.9)
	_draw_text(font, rect.position + Vector2(11.0, 23.0), label, 14, Color(0.78, 0.9, 0.98))
	_draw_text(font, rect.position + Vector2(11.0, 44.0), state, 14, color)


func _draw_text(font: Font, position: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _format_time(total_seconds: float) -> String:
	var seconds := int(floor(total_seconds))
	return "%02d:%02d" % [seconds / 60, seconds % 60]
