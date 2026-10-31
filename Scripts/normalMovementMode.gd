extends MovementMode
class_name NormalMovementMode

var speed : float = 15
var gravity : float = 20
var jump : float = 7

var gravity_vec : Vector3

#Jumping
var coyoteTime : float = 0.2

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
var airStrafeCurve : Curve = load("res://Curves/45degreecurve.tres")
const minStrafeAngle : float = 0.0
const maxStrafeAngle : float = 180.0
const airStrafeModifier : float = 1.0

var direction : Vector3

enum MOVESTATES {
	GROUNDED,
	AIRBORN,
	CROUCHED,
	SLIDING,
}

var currentState : MOVESTATES = MOVESTATES.AIRBORN
var previousState : MOVESTATES = MOVESTATES.AIRBORN




func ground(player: CharacterBody3D, delta : float) -> void:
	#isCrouching = handleCrouch(delta)
	
	player.floor_snap_length = floorSnapLength
	gravity_vec = Vector3.ZERO
	
	move(player, delta, floorAccel, floorDrag)
	groundToAir(player)
	
	# ENTER SLIDE CODE
	#if !isCrouching or (isCrouching and velocity.length() > startSlideThresh):
		#move(delta, floorAccel, floorDrag)
		#if isCrouching:
			#toSlide()
	#else:
		#move(delta, crouchAccel, floorDrag)
	
	return

func air(player: CharacterBody3D, delta : float) -> void:
	player.floor_snap_length = airSnapLength
	
	# Which way are we going?
	if hasJumped:
		gravity_vec = (player.get_floor_normal() + Vector3.UP).normalized() * jump
		hasJumped = false
	else:
		gravity_vec = Vector3.DOWN * gravity * delta
	
	move(player, delta, airAccel, airDrag)
	
	if player.is_on_floor():
		player.changeState(player.MOVESTATES.GROUNDED)
		canJump = true
	
	# TODO: test this
	if Input.is_action_just_pressed("jump"):
		queueJump(player)
	
	return
	
func applyForce(player: CharacterBody3D, force : Vector3) -> void:
	player.velocity += force

func slowMovement(player: CharacterBody3D, amount : float) -> void:
	player.velocity *= amount
	
func getHorizontalAngle(vec1 : Vector3, vec2 : Vector3) -> float:
	vec1.y = 0
	vec2.y = 0
	return abs(vec1.angle_to(vec2))


func move(player: CharacterBody3D, delta: float, accel : float, drag : float) -> void:
	#get keyboard input
	direction = Vector3.ZERO
	var h_rot : float = player.global_transform.basis.get_euler().y
	var f_input : float = Input.get_axis("forward", "backward")
	var h_input : float = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	var wish_vel : Vector3 = direction * speed
	
	#Airstrafing
	#match currentState:
		#MOVESTATES.AIRBORN:
				#var angle_diff : float = rad_to_deg(movementMode.getHorizontalAngle(velocity, wish_vel))
				#var samplePoint = (angle_diff - movementMode.minStrafeAngle) / movementMode.maxStrafeAngle
				##velocity += wish_vel.normalized() * delta * airStrafeCurve.sample(samplePoint) * airSpeed
				#wish_vel *= 1.0 + (movementMode.airStrafeCurve.sample(samplePoint) * movementMode.airStrafeModifier)
	#
	#Crouching
	#if currentState == MOVESTATES.GROUND and isCrouching:
		#wish_vel = direction * crouchSpeed
	
	# speeding up or slowing down?
	if direction.length() > 0:
		player.velocity = lerp(player.velocity, wish_vel, accel * delta)
	else:
		player.velocity = lerp(player.velocity, wish_vel, drag * delta)
	
	player.velocity += gravity_vec
	player.move_and_slide()
	return


func queueJump(player: CharacterBody3D) -> void:
	jumpQueued = true
	await player.get_tree().create_timer(coyoteTime).timeout
	jumpQueued = false


func groundToAir(player: CharacterBody3D) -> bool:
	if !player.is_on_floor():
		player.changeState(MOVESTATES.AIRBORN)
		if canJump:
			executeAfterTime(player, coyoteTime, func() : if !player.is_on_floor(): canJump = false)
		return true
	return false
	
func executeAfterTime(player: CharacterBody3D, time : float, function : Callable) -> void:
	await player.get_tree().create_timer(time).timeout
	function.call()

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
