extends MovementMode
class_name NormalMovementMode

var speed : float = 15
var gravity : float = 20
var jump : float = 7

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


func ground(player: CharacterBody3D, delta : float) -> void:
	#isCrouching = handleCrouch(delta)
	
	player.floor_snap_length = floorSnapLength
	player.gravity_vec = Vector3.ZERO
	
	player.move(delta, floorAccel, floorDrag)
	player.groundToAir()
	
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
	if player.hasJumped:
		player.gravity_vec = (player.get_floor_normal() + Vector3.UP).normalized() * jump
		player.hasJumped = false
	else:
		player.gravity_vec = Vector3.DOWN * gravity * delta
	
	player.move(delta, airAccel, airDrag)
	
	if player.is_on_floor():
		player.changeState(player.MOVESTATES.GROUNDED)
		player.canJump = true
	
	# TODO: test this
	if Input.is_action_just_pressed("jump"):
		player.queueJump()
	
	return
	
func applyForce(player: CharacterBody3D, force : Vector3) -> void:
	player.velocity += force

func slowMovement(player: CharacterBody3D, amount : float) -> void:
	player.velocity *= amount
	
func getHorizontalAngle(vec1 : Vector3, vec2 : Vector3) -> float:
	vec1.y = 0
	vec2.y = 0
	return abs(vec1.angle_to(vec2))
