@tool
extends Area2D

class_name LightArea

# Emitted when the radius of the light changes
signal radius_changed()

# Possible states for the light, either on or off
enum States {ON, OFF}

# Number of vertices the circular polygon has
# Higher numbers are more circular with more accurate platform masking
@export var polygon_vertices := 16: set = set_polygon_vertices

# Viewport for the light world to be masked by this light
@export var light_world: Viewport

# Reference to the texture which displays the light world
@onready var light_world_shader: Material = $TextureRect.material.duplicate(true)

# Number of radians to rotate by when creating the circular polygon
@onready var _polygon_angle_delta: = deg_to_rad(360.0 / polygon_vertices)

# Reference to the light's area shape
var area_shape: CollisionShape2D

# Current state of the light, defaults to on
var state: int = States.ON: set = set_state

# Polygon approximating the circular shape of the light
var polygon: PackedVector2Array

# Initial radius of the light
var _initial_radius: float

# Last known position of the area shape, to reduce shader calls
var _last_area_shape_position: Vector2

func _ready() -> void:
	# Look for a child CircleShape2D
	for child in get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			_last_area_shape_position = child.global_position
			_initial_radius = child.shape.radius
			area_shape = child

	# Set the instanced shader and texture for the light world
	$TextureRect.material = light_world_shader
	$TextureRect.texture = light_world.get_texture()

	light_world_shader.set_shader_parameter("center", area_shape.global_position)
	light_world_shader.set_shader_parameter("radius", area_shape.shape.radius)

	# Create the initial circular polygon
	polygon = _create_circular_polygon()

func _process(_delta: float) -> void:
	if area_shape && !_last_area_shape_position.is_equal_approx(area_shape.global_position):
		light_world_shader.set_shader_parameter("center", area_shape.global_position)
		_last_area_shape_position = area_shape.global_position

		# Update the polygon's position in the editor as well
		if Engine.is_editor_hint():
			polygon = _create_circular_polygon()

	if not Engine.is_editor_hint():
		var target_radius: = _initial_radius if state == States.ON else 0.0
		var new_radius: float = lerp(area_shape.shape.radius, target_radius, 0.05)

		# Update the shader and polygon when the radius changes, then emit a signal
		if !is_equal_approx(area_shape.shape.radius, new_radius):
			light_world_shader.set_shader_parameter("radius", area_shape.shape.radius)
			polygon = _create_circular_polygon()

			radius_changed.emit()

		area_shape.shape.radius = new_radius
	elif light_world_shader && light_world_shader.get_shader_parameter("radius") != area_shape.shape.radius:
		# In the editor, the radius is the shape's radius
		light_world_shader.set_shader_parameter("radius", area_shape.shape.radius)
		polygon = _create_circular_polygon()

# Sets the current state of the light
func set_state(new_state: int) -> void:
	state = new_state

# Updates the number of vertices for the circular polygon in the editor
func set_polygon_vertices(new_vertex_count: int) -> void:
	polygon_vertices = new_vertex_count
	_polygon_angle_delta = deg_to_rad(360.0 / polygon_vertices)
	polygon = _create_circular_polygon()

# Creates a polygon which approximates the circular shape of the light
func _create_circular_polygon() -> PackedVector2Array:
	var new_polygon: = PackedVector2Array()
	var angle: = 0.0

	for _vertex in polygon_vertices:
		new_polygon.append(Vector2(cos(angle), sin(angle)) * area_shape.shape.radius)
		angle += _polygon_angle_delta

	# Display the circular polygon in the editor
	if Engine.is_editor_hint():
		var collision_polygon: CollisionPolygon2D

		if has_node("CollisionPolygon2D"):
			collision_polygon = $CollisionPolygon2D
		else:
			collision_polygon = CollisionPolygon2D.new()
			add_child(collision_polygon)

		collision_polygon.global_transform = area_shape.global_transform
		collision_polygon.polygon = new_polygon
		queue_redraw()

	return new_polygon

func _get_configuration_warnings() -> PackedStringArray:
	var collision_shape: CollisionShape2D

	# Look for a child `CollisionShape2D`
	for child in get_children():
		if child is CollisionShape2D:
			collision_shape = child

	if !collision_shape:
		return ["A child CollisionShape2D must be defined"]
	elif !(collision_shape.shape is CircleShape2D):
		return ["The CollisionShape2D shape must be a CircleShape2D"]
	elif !light_world:
		return ["A light world texture must be defined"]
	else:
		return []
