@tool
extends Sprite2D

# Path to a light area controlled by this switch
@export var light_area_path: NodePath

# The light area controlled by this switch
@onready var light_area: LightArea = get_node(light_area_path)

# Area within which an object can interact with this switch
@onready var _area = $Area2D

func _ready() -> void:
	_area.connect("body_entered", Callable(self, "_on_body_entered"))
	_area.connect("body_exited", Callable(self, "_on_body_exited"))

# Toggles the current state of the associated light area
func interact() -> void:
	light_area.state = LightArea.States.OFF if light_area.state == LightArea.States.ON else LightArea.States.ON

# Registers this interactable node with the body
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_interactable"):
		body.add_interactable(self)

# Deregisters this interactable node with the body
func _on_body_exited(body: Node2D) -> void:
	if body.has_method("remove_interactable"):
		body.remove_interactable(self)

# Warns when no `LightArea` is associated with this node
func _get_configuration_warnings() -> PackedStringArray:
	if !light_area_path:
		return ["No LightArea is associated with this node"]
	elif !(light_area is LightArea):
		return ["Light3D area must be of type LightArea"]

	return []
