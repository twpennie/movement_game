extends CharacterBody3D
class_name PlayerMovement

var display_velocity

@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera3D
@onready var collider : CollisionShape3D = $CollisionShape3D
@export var speedFovIncrease : float = 5.0
@export var fovLerpSpeed : float = 5.0

var speed : float = 15
var gravity : float = 20
var jump : float = 7

var cam_accel : float = 40
var mouse_sense : float = 0.06

var direction : Vector3
var gravity_vec : Vector3

enum MOVESTATES {
	GROUNDED,
	AIRBORN,
	CROUCHED,
	SLIDING,
}

var currentState : MOVESTATES = MOVESTATES.AIRBORN
var previousState : MOVESTATES = MOVESTATES.AIRBORN

# GROUNDED
const floorSnapLength : float = 0.4
const floorAccel : float = 7
const floorDrag : float = 8

# AIRBORN
const airSnapLength : float = 0.1
const airAccel : float = 0.5 
const airSpeed : float = 16.0 
const airDrag : float = 0.1 

#Air Strafing
@export var airStrafeCurve : Curve
const minStrafeAngle : float = 0.0
const maxStrafeAngle : float = 180.0
const airStrafeModifier : float = 1.0

#Jumping
var canJump : bool = true
var hasJumped : bool = false
var coyoteTime : float = 0.2
var jumpQueued : bool = false

#Crouching
#@onready var fullHeight : float = collider.shape.height
#@onready var crouchHeight : float = fullHeight / 2.0
#@onready var ceilingCheck: ShapeCast3D = $CeilingCheck
#const heightLerpSpeed : float = 10.0
#@onready var headOffset : float = head.position.y
#var isCrouching : bool = false
#const crouchSpeed : float = 8; const crouchAccel : float = 4

#Signals
signal justJumped; signal justLanded;

func changeState(newState : MOVESTATES) -> void:
	previousState = currentState
	currentState = newState
	

# exponential decay function (lerp)
# current = target + (current - target) * exp(-decayConstant * deltaTime)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	
func _physics_process(delta: float) -> void:
	match currentState:
		MOVESTATES.GROUNDED:
			ground(delta)
		MOVESTATES.AIRBORN:
			air(delta)
		#MOVESTATES.CROUCHED:
		
	if (Input.is_action_just_pressed("jump") or jumpQueued) and canJump:
		canJump = false
		hasJumped = true
		jumpQueued = false
		emit_signal("justJumped")
		
		if currentState != MOVESTATES.AIRBORN:
			changeState(MOVESTATES.AIRBORN)
	

func ground(delta : float) -> void:
	#isCrouching = handleCrouch(delta)
	
	floor_snap_length = floorSnapLength
	gravity_vec = Vector3.ZERO
	
	move(delta, floorAccel, floorDrag)
	groundToAir()
	
	# ENTER SLIDE CODE
	#if !isCrouching or (isCrouching and velocity.length() > startSlideThresh):
		#move(delta, floorAccel, floorDrag)
		#if isCrouching:
			#toSlide()
	#else:
		#move(delta, crouchAccel, floorDrag)
	
	return

func air(delta : float) -> void:
	floor_snap_length = airSnapLength
	
	# Which way are we going?
	if hasJumped:
		gravity_vec = (get_floor_normal() + Vector3.UP).normalized() * jump
		hasJumped = false
	else:
		gravity_vec = Vector3.DOWN * gravity * delta
	
	move(delta, airAccel, airDrag)
	
	if is_on_floor():
		changeState(MOVESTATES.GROUNDED)
		emit_signal("justLanded")
		canJump = true
	
	# TODO: test this
	if Input.is_action_just_pressed("jump"):
		queueJump()
	
	return

func queueJump() -> void:
	jumpQueued = true
	await get_tree().create_timer(coyoteTime).timeout
	jumpQueued = false


func groundToAir() -> bool:
	if !is_on_floor():
		changeState(MOVESTATES.AIRBORN)
		if canJump:
			executeAfterTime(coyoteTime, func() : if !is_on_floor(): canJump = false)
		return true
	return false
	
func executeAfterTime(time : float, function : Callable) -> void:
	await get_tree().create_timer(time).timeout
	function.call()

func applyForce(force : Vector3) -> void:
	velocity += force

func slowMovement(amount : float) -> void:
	velocity *= amount

#func handleCrouch(delta : float, forceCrouch : bool = false, forceUncrouch : bool = false) -> bool:
	#var height : float = collider.shape.height
	#var crouching : bool = Input.is_action_pressed("crouch") or (height < fullHeight - 0.1 and ceilingCheck.is_colliding()) or forceCrouch
	#crouching = false if forceUncrouch else crouching 
	#
	#if height != fullHeight or height != crouchHeight:
		#collider.shape.height = lerp(collider.shape.height, crouchHeight if crouching else fullHeight, delta * heightLerpSpeed)
		#head.position.y = lerp(head.position.y, headOffset if !crouching else headOffset/2, delta * heightLerpSpeed)
	#
	#return crouching

func getHorizontalAngle(vec1 : Vector3, vec2 : Vector3) -> float:
	vec1.y = 0
	vec2.y = 0
	return abs(vec1.angle_to(vec2))

func move(delta: float, accel : float, drag : float, speed : float = speed) -> void:
	#get keyboard input
	direction = Vector3.ZERO
	var h_rot : float = global_transform.basis.get_euler().y
	var f_input : float = Input.get_axis("forward", "backward")
	var h_input : float = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	var wish_vel : Vector3 = direction * speed
	
	#Airstrafing
	match currentState:
		MOVESTATES.AIRBORN:
				var angle_diff : float = rad_to_deg(getHorizontalAngle(velocity, wish_vel))
				var samplePoint := (angle_diff - minStrafeAngle) / maxStrafeAngle
				#velocity += wish_vel.normalized() * delta * airStrafeCurve.sample(samplePoint) * airSpeed
				wish_vel *= 1.0 + (airStrafeCurve.sample(samplePoint) * airStrafeModifier)
	#
	#Crouching
	#if currentState == MOVESTATES.GROUND and isCrouching:
		#wish_vel = direction * crouchSpeed
	
	# speeding up or slowing down?
	if direction.length() > 0:
		velocity = lerp(velocity, wish_vel, accel * delta)
	else:
		velocity = lerp(velocity, wish_vel, drag * delta)
	
	velocity += gravity_vec
	move_and_slide()
	return
