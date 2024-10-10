extends CharacterBody2D

@export var speed: int = 300
@export var jump_speed: int = -900
@export var gravity: int = 2000

# Array of objects the player can currently interact with
var _interactables: Array = []

# Registers an interactable to use when pressing the interaction key
func add_interactable(interactable: Node) -> void:
	_interactables.append(interactable)

# Removes an interactable, no longer interacting with it when the interaction key is pressed
func remove_interactable(interactable: Node) -> void:
	_interactables.erase(interactable)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed && event.keycode == KEY_Z:
			for interactable in _interactables:
				interactable.interact()

func get_input():
	velocity.x = 0
	if Input.is_action_pressed("ui_right"):
		velocity.x += speed
	if Input.is_action_pressed("ui_left"):
		velocity.x -= speed

func _physics_process(delta):
	get_input()
	velocity.y += gravity * delta
	set_velocity(velocity)
	set_up_direction(Vector2.UP)
	move_and_slide()
	velocity = velocity
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = jump_speed
