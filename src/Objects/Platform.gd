@tool
extends StaticBody2D

# Possible worlds the platform can belong to
enum Worlds {LIGHT, DARK}

# World that the platform belongs to
@export var world: Worlds = Worlds.DARK

# Reference to the collision polygon nodes used for physics
@onready var collision_polygons: = []

# Reference to the area used to detect overlap with lights
@onready var detection_area: Area2D = $Area2D

# Reference to the shape to detect overlap with lights and define the collision polygon
@onready var detection_area_shape: CollisionShape2D

# List of light areas currently overlapping with this platform
var _overlapping_light_areas: = []

func _ready() -> void:
	# Look for a child `CollisionShape2D` to use with the detection area
	for child in get_children():
		if child is CollisionShape2D:
			detection_area_shape = child

			# Move the platform's child collision shape to the area at runtime
			if not Engine.is_editor_hint():
				remove_child(child)
				detection_area.add_child(child)

	assert(detection_area.connect("area_entered", Callable(self, "_on_area_entered")) == 0)
	assert(detection_area.connect("area_exited", Callable(self, "_on_area_exited")) == 0)

# Updates the collision polygon when overlapping with a light
func _on_area_entered(area: Area2D) -> void:
	if area is LightArea:
		# Track how many light areas are currently overlapping with this platform
		_overlapping_light_areas.append(area)

		_update_collision_polygons()

		# Recalculate the polygon whenever the light's radius changes
		assert(area.connect("radius_changed", Callable(self, "_on_radius_changed")) == 0)

# Restores the collision polygon when no longer overlapping with a light
func _on_area_exited(area: Area2D) -> void:
	if area is LightArea:
		area.disconnect("radius_changed", Callable(self, "_on_radius_changed"))

		# Track how many lights are currently overlapping with this platform
		_overlapping_light_areas.erase(area)

		# Update the polygon one last time
		_update_collision_polygons()

# Update the platform's collision polygons when a light area's radius changes
func _on_radius_changed() -> void:
	_update_collision_polygons()

# Creates new collision polygons by handling overlap between platforms and light
func _update_collision_polygons() -> void:
	var modified_polygons: = _get_dark_polygons() if world == Worlds.DARK else _get_light_polygons()
	var total_polygons: int = max(modified_polygons.size(), collision_polygons.size())

	# Update the collision polygon nodes, clearing any that aren't used
	for index in total_polygons:
		var polygon: PackedVector2Array = PackedVector2Array() if index >= modified_polygons.size() else modified_polygons[index]
		_get_collision_polygon_node(index).set_deferred("polygon", polygon)

# Returns an array of polygons where the platform overlaps with light areas
func _get_light_polygons() -> Array[PackedVector2Array]:
	var default_polygon: = _get_detection_area_polygon()
	var modified_polygons: Array[PackedVector2Array] = []

	# Create an array of all polygons intersecting a light area's polygon
	for light_area in _overlapping_light_areas:
		var light_polygon: = _get_light_area_polygon(light_area)

		var resulting_polygons: = Geometry2D.intersect_polygons(default_polygon, light_polygon)

		modified_polygons.append_array(resulting_polygons)

	return modified_polygons

# Returns an array of polygons where the platform does not overlap with light areas
func _get_dark_polygons() -> Array[PackedVector2Array]:
	# Start with the detection area's polygon and break it down from there
	var modified_polygons: Array[PackedVector2Array] = [_get_detection_area_polygon()]

	for light_area in _overlapping_light_areas:
		var light_polygon: = _get_light_area_polygon(light_area)

		# Create a new array of modified polygons that can be modified while looping
		var temp_modified_polygons: = modified_polygons.duplicate()

		for index in modified_polygons.size():
			var resulting_polygons: = Geometry2D.clip_polygons(modified_polygons[index], light_polygon)

			# Store the new polygons in the temporary modified polygon array
			if resulting_polygons:
				temp_modified_polygons[index] = resulting_polygons.pop_front()
				temp_modified_polygons.append_array(resulting_polygons)
			else:
				temp_modified_polygons[index] = PackedVector2Array()

		# Update the modified polygons array after looping through its contents
		modified_polygons = temp_modified_polygons

	return modified_polygons

# Returns a `LightArea` polygon, transformed to be in the platform's local space
func _get_light_area_polygon(area: LightArea) -> PackedVector2Array:
	return (area.area_shape.global_transform * (area.polygon)) * detection_area.global_transform

# Returns a `CollisionPolygon2D` node for a specific polygon array index
# This allows multiple polygons to be used for collisions when needed
func _get_collision_polygon_node(index: int) -> CollisionPolygon2D:
	# Add as many nodes as necessary to reach the given index
	while index >= collision_polygons.size():
		var polygon: = CollisionPolygon2D.new()
		polygon.one_way_collision = detection_area_shape.one_way_collision

		collision_polygons.append(polygon)
		call_deferred("add_child", polygon)

	return collision_polygons[index]

# Creates a polygon in the shape of the detection area
func _get_detection_area_polygon() -> PackedVector2Array:
	if !detection_area_shape:
		return PackedVector2Array()

	var extents = detection_area_shape.shape.extents
	var transformation = detection_area_shape.transform
	return PackedVector2Array([
		transformation * (Vector2(-extents.x, -extents.y)),
		transformation * (Vector2(extents.x, -extents.y)),
		transformation * (Vector2(extents.x, extents.y)),
		transformation * (Vector2(-extents.x, extents.y))])

# Warns when no child CollisionShape2D is defined
func _get_configuration_warnings() -> PackedStringArray:
	return ["A child CollisionShape2D must be defined"] if not detection_area_shape else []
