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
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var steer_direction := (player.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	# Get floor vectors
	var floor_normal : Vector3 = player.get_floor_normal()
	var current_angle : float = rad_to_deg(player.get_floor_angle())
	player.floor_snap_length = floorSnapLength
	gravity_vec = Vector3.ZERO
	
	var player_facing_vector : Vector3 = -player.camera.global_transform.basis.z
	player_facing_vector = Vector3(player_facing_vector.x, 0.0, player_facing_vector.z).normalized()
	var player_turn_limit : float = 0.85
	
	player.floor_stop_on_slope = false
	
	# Calculate the downhill direction vector
	var slide_direction : Vector3 = (Vector3.DOWN - floor_normal * Vector3.DOWN.dot(floor_normal)).normalized()
	
	var steepness = remap(current_angle, slideStartAngle, 90.0, 0.0, 1.0)
	steepness = clamp(steepness, 0.0, 1.0)
	
	# Calculate total acceleration potential of the slope
	var total_slope_power : float = steepness * slopeAccel
	
	# --- TURNING & MOMENTUM HANDLING ---
	
	# Gravity always pulls downhill, regardless of where you look
	var gravity_slide_force : Vector3 = slide_direction * total_slope_power
	player.velocity += gravity_slide_force * delta
	
	# --- FRICTION & DRAG APPLICATION ---
	var current_speed := player.velocity.length()
	
	if current_speed > 0.1:
		var applied_drag : float = drag
		
		# Calculate turn friction 
		# If the player is actively steering, check how sharp their turn is
		if steer_direction.length_squared() > 0.0:
				# TODO: this is buggy, in testing it is 0 if going straight
				# turn_angle_match is 1.0 if moving straight, 0.0 if turning hard 90 degrees
				var turn_angle_match : float = player.velocity.normalized().dot(steer_direction)
				
				# Scale friction up when turning aggressively across momentum
				# negative maybe is more fun, it negates half of the ground friction when turning. So optimal
				# movement would be to strafe side to side kind of like bhopping. Then maybe crouch turning should slow you down but allow
				# for faster turns
				var carving_friction_factor : float = -0.05 # Increase for more speed-loss on hard turns
				applied_drag += remap(turn_angle_match, -1.0, 1.0, carving_friction_factor, 0.0)
			
		# Apply total linear drag over time
		player.velocity = lerp(player.velocity, Vector3.ZERO, applied_drag * delta)
		
		
		# check the players current velocity and where they are looking, calculating the dot product
		# This is so that you can only turn so much in relation to where you are looking. Prevents turning 360
		var player_facing_turning_relation : float = player_facing_vector.dot(player.velocity.normalized())
			
		# Apply steering control to redirect remaining momentum as long as the plaeyr isnt attempting to turn too sharply
		if !(player_facing_turning_relation < player_turn_limit) and steer_direction.length_squared() > 0.0:
			
			var turn_sharpness : float = 2.0 
			
			# Recalculate speed after drag
			var post_drag_speed := player.velocity.length()
			var target_velocity_dir = lerp(player.velocity.normalized(), steer_direction, turn_sharpness * delta).normalized()
			
			# Re-assign velocity keeping your speed intact, just pointing in the new carved direction
			player.velocity = target_velocity_dir * post_drag_speed
	
	player.move_and_slide()
