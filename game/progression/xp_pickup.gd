class_name XpPickup
extends Node2D

## Temporary geometric presentation until the approved XP art arrives. It is a
## gameplay pickup, not a substitute for final sprite/VFX production assets.
signal collected(award: XpAward)

var award: XpAward
var collector: Node2D
var attraction_radius: float = 220.0
var attraction_speed: float = 720.0
var collect_radius: float = 18.0


func configure(new_award: XpAward, target: Node2D, radius: float, speed: float, collection_radius: float) -> void:
	award = new_award
	collector = target
	attraction_radius = radius
	attraction_speed = speed
	collect_radius = collection_radius
	queue_redraw()


func _process(delta: float) -> void:
	if award == null or collector == null or not is_instance_valid(collector):
		return
	var delta_to_collector := collector.global_position - global_position
	var distance := delta_to_collector.length()
	if distance <= collect_radius:
		collected.emit(award)
		queue_free()
		return
	if distance <= attraction_radius:
		global_position += delta_to_collector.normalized() * minf(attraction_speed * delta, distance)


func _draw() -> void:
	var size := 5.0 + minf(float(award.amount) * 0.15, 4.0) if award != null else 5.0
	var diamond := PackedVector2Array([Vector2(0, -size), Vector2(size, 0), Vector2(0, size), Vector2(-size, 0)])
	draw_colored_polygon(diamond, Color("72e8a6"))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("d9ffef"), 1.0, true)
