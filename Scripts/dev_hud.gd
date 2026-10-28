extends CanvasLayer


@onready var display_list : VBoxContainer = $Control/VBoxContainer
@export var player : CharacterBody3D
@onready var state_label : Label = $Control/VBoxContainer/StateLabel
@onready var velocity_label : Label = $Control/VBoxContainer/VelocityLabel
var display_velocity : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	display_velocity = Vector2(player.velocity.x, player.velocity.z).length()
	velocity_label.text = "velocity: " + str(int(display_velocity))


func _on_player_signal_state_change(newState: String) -> void:
	state_label.text = "currentState: " + newState
	pass # Replace with function body.
