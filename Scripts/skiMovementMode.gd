extends NormalMovementMode 
class_name SkiMovementMode

const slideStartAngle : float = 1
const slopeAccel: float = 30 
const skiDrag : float = 0.1 
const skiFloorAccel : float = 0.5 

# ski strafe
var skiStrafeCurve : Curve = load("res://Curves/tightCurve.tres")
const minSkiStrafeAngle : float = 0.0
const maxSkiStrafeAngle : float = 180.0
const skiStrafeModifier : float = 1.0

func _init() -> void:
	speed = 2 

func ground(player: CharacterBody3D, delta : float) -> void:
	#isCrouching = handleCrouch(delta)
	var floor_normal : Vector3 = player.get_floor_normal()
	var current_angle : float = rad_to_deg(player.get_floor_angle())
	player.floor_snap_length = floorSnapLength
	gravity_vec = Vector3.ZERO
	
	if current_angle >= slideStartAngle:
		player.floor_stop_on_slope = false
		
		# 1. Calculate the downhill direction vector
		var slide_direction : Vector3 = (Vector3.DOWN - floor_normal * Vector3.DOWN.dot(floor_normal)).normalized()
		
		var steepness = remap(current_angle, slideStartAngle, 90.0, 0.0, 1.0)
		steepness = clamp(steepness, 0.0, 1.0)
		
		# 2. Get the clean, flattened direction the player is looking
		var player_facing_vector : Vector3 = -player.camera.global_transform.basis.z
		player_facing_vector = Vector3(player_facing_vector.x, 0.0, player_facing_vector.z).normalized()
		
		# 3. Find out how much the player's face matches the downhill direction
		# Returns 1.0 looking perfectly downhill, 0.0 perpendicular, -1.0 perfectly uphill
		var slope_alignment : float = slide_direction.dot(player_facing_vector)
		
		# 4. Calculate total acceleration potential of the slope
		var total_slope_power : float = steepness * slopeAccel
		
		# 5. Apply the force along the player's facing vector, scaled by the slope alignment
		var final_slide_force : Vector3 = player_facing_vector * (slope_alignment * total_slope_power)
		
		player.velocity += final_slide_force * delta
	
	move(player, delta, skiFloorAccel, skiDrag)
	groundToAir(player)
	
	return

func move(player: CharacterBody3D, delta: float, accel : float, drag : float) -> void:
	#get keyboard input
	direction = Vector3.ZERO
	var h_rot : float = player.global_transform.basis.get_euler().y
	var f_input : float = 0.0
	
	# we only want to have forward or backward affect the player if they are moving slowly
	if player.velocity.length() <= speed:
		f_input = Input.get_axis("forward", "backward")
	
	var h_input : float = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	#var wish_vel : Vector3 = direction * speed
	var wish_vel : Vector3 = direction * player.velocity.length()
	
	# calculate angle between the wish velocity and current velocity, and sample it on the curve
	var angle_diff : float = rad_to_deg(getHorizontalAngle(player.velocity, wish_vel))
	var samplePoint = (angle_diff - minSkiStrafeAngle) / maxSkiStrafeAngle
	
	# strength of the wish velocity depends on the value obtained by the curve
	wish_vel *= 1.0 + (skiStrafeCurve.sample(samplePoint) * skiStrafeModifier)
	print(1.0  + (skiStrafeCurve.sample(samplePoint) * skiStrafeModifier))

	# speeding up or slowing down?
	if direction.length() > 0:
		player.velocity = lerp(player.velocity, wish_vel, accel * delta)
	else:
		player.velocity = lerp(player.velocity, wish_vel, drag * delta)
	
	player.velocity += gravity_vec
	player.move_and_slide()
	return
