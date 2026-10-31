extends CharacterBody3D
class_name Player

@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera3D
@onready var collider : CollisionShape3D = $CollisionShape3D
@export var speedFovIncrease : float = 5.0
@export var fovLerpSpeed : float = 5.0

var movementMode : MovementMode = NormalMovementMode.new()

var cam_accel : float = 40
var mouse_sense : float = 0.06


# DEV ONLY
enum TEST_MOVEMENT_MODES {
	NORMAL,
	SKIS,
	BHOP,
}

var movementModeList : Array[TEST_MOVEMENT_MODES] = [
TEST_MOVEMENT_MODES.NORMAL,
TEST_MOVEMENT_MODES.SKIS,
TEST_MOVEMENT_MODES.BHOP,
]

# position in list
var currentMovementModeIndex : int = 0

var currentMovementMode : TEST_MOVEMENT_MODES = TEST_MOVEMENT_MODES.NORMAL
signal signal_movement_mode_change(newMode: String)

# END DEV ONLY

enum MOVESTATES {
	GROUNDED,
	AIRBORN,
	CROUCHED,
	SLIDING,
}

var currentState : MOVESTATES = MOVESTATES.AIRBORN
var previousState : MOVESTATES = MOVESTATES.AIRBORN

#Crouching
#@onready var fullHeight : float = collider.shape.height
#@onready var crouchHeight : float = fullHeight / 2.0
#@onready var ceilingCheck: ShapeCast3D = $CeilingCheck
#const heightLerpSpeed : float = 10.0
#@onready var headOffset : float = head.position.y
#var isCrouching : bool = false
#const crouchSpeed : float = 8; const crouchAccel : float = 4

#Signals
signal signal_state_change(newState: String)

func changeState(newState : MOVESTATES) -> void:
	previousState = currentState
	currentState = newState
	match currentState:
		MOVESTATES.GROUNDED:
			signal_state_change.emit("GROUNDED")
		MOVESTATES.AIRBORN:
			signal_state_change.emit("AIRBORN")
	
# DEV ONLY
func cycleMovementMode() -> void:
	if currentMovementModeIndex == 2:
		currentMovementModeIndex = 0
	else:
		currentMovementModeIndex += 1
	
	currentMovementMode = movementModeList[currentMovementModeIndex] 
	match currentMovementMode:
		TEST_MOVEMENT_MODES.BHOP:
			movementMode = BhopMovementMode.new()
		TEST_MOVEMENT_MODES.SKIS:
			movementMode = SkiMovementMode.new()
		TEST_MOVEMENT_MODES.NORMAL:
			movementMode = NormalMovementMode.new()
	
	signal_movement_mode_change.emit(TEST_MOVEMENT_MODES.keys()[currentMovementMode])
# END DEV ONLY

# exponential decay function (lerp)
# current = target + (current - target) * exp(-decayConstant * deltaTime)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	signal_movement_mode_change.emit("NORMAL")

# mouse movement
func _input(event: InputEvent) -> void:
	# mouse input for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _process(_delta: float):
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("z"):
		cycleMovementMode()
	
func _physics_process(delta: float) -> void:
	match currentState:
		MOVESTATES.GROUNDED:
			movementMode.ground(self, delta)
		MOVESTATES.AIRBORN:
			movementMode.air(self, delta)
		#MOVESTATES.CROUCHED:
		
	if (Input.is_action_just_pressed("jump") or movementMode.jumpQueued) and movementMode.canJump:
		movementMode.canJump = false
		movementMode.hasJumped = true
		movementMode.jumpQueued = false
		
		if currentState != MOVESTATES.AIRBORN:
			changeState(MOVESTATES.AIRBORN)
	
