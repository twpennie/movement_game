extends NormalMovementMode 
class_name SkiMovementMode

const slideStartAngle : float = 1
const slopeAccel: float = 20 
const skiDrag : float = 0.1 
const skiFloorAccel : float = 0.5 

# ski strafe
var skiStrafeCurve : Curve = load("res://Curves/45degreecurve.tres")
const minSkiStrafeAngle : float = 0.0
const maxSkiStrafeAngle : float = 180.0
const skiStrafeModifier : float = 1.0
const skiStrafeSpeed : float = 15

func _init() -> void:
	speed = 2 

func ground(player: CharacterBody3D, delta : float) -> void:
	#isCrouching = handleCrouch(delta)
	ski_move(player, delta, skiFloorAccel, skiDrag)
	groundToAir(player)
	
	return

func ski_move(player: CharacterBody3D, delta: float, accel : float, drag : float) -> void:
	# Gather player input 
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var steer_direction := (player.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	# add the slope vector to the wish vector
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
		var slope_alignment : float = slide_direction.dot(player_facing_vector)
		
		# 4. Calculate total acceleration potential of the slope
		var total_slope_power : float = steepness * slopeAccel
		
		# --- TURNING & MOMENTUM HANDLING ---
		
		# 5. Gravity always pulls downhill, regardless of where you look
		var gravity_slide_force : Vector3 = slide_direction * total_slope_power
		player.velocity += gravity_slide_force * delta
	
	# --- FRICTION & DRAG APPLICATION ---
	var current_speed := player.velocity.length()
	
	if current_speed > 0.1:
		var applied_drag : float = drag
		
		# 6. Optional: Calculate carving/braking friction 
		# If the player is actively steering, check how sharp their turn is
		if steer_direction.length_squared() > 0.0:
			var turn_angle_match : float = player.velocity.normalized().dot(steer_direction)
			# turn_angle_match is 1.0 if moving straight, 0.0 if turning hard 90 degrees
			
			# Scale friction up when turning aggressively across momentum
			var carving_friction_factor : float = 0.5 # Increase for more speed-loss on hard turns
			applied_drag += remap(turn_angle_match, -1.0, 1.0, carving_friction_factor, 0.0)
		
		# Apply total linear drag over time
		player.velocity = lerp(player.velocity, Vector3.ZERO, applied_drag * delta)
	
	# 7. Apply steering control to redirect remaining momentum
	if steer_direction.length_squared() > 0.0:
		var turn_sharpness : float = 2.0 
		
		# Recalculate speed after drag
		var post_drag_speed := player.velocity.length()
		var target_velocity_dir = lerp(player.velocity.normalized(), steer_direction, turn_sharpness * delta).normalized()
		
		# Re-assign velocity keeping your speed intact, just pointing in the new carved direction
		player.velocity = target_velocity_dir * post_drag_speed
		
	player.move_and_slide()
