extends NormalMovementMode 
class_name SkiMovementMode

var slide_start_angle : float = 1
var max_slide_accel: float = 500 

func ground(player: CharacterBody3D, delta : float) -> void:
	#isCrouching = handleCrouch(delta)
	var floor_normal : Vector3 = player.get_floor_normal()
	var current_angle : float = rad_to_deg(player.get_floor_angle())
	player.floor_snap_length = floorSnapLength
	player.gravity_vec = Vector3.ZERO
	
	if current_angle >= slide_start_angle:
		toSlide(player, current_angle, delta)
	
	else:
		player.floor_stop_on_slope = true
	
	player.move(delta, floorAccel, floorDrag)
	player.groundToAir()
	
	return

func toSlide(player: CharacterBody3D, current_angle : float, delta : float) -> void:
	var floor_normal : Vector3 = player.get_floor_normal()
	player.floor_stop_on_slope = false
	
	var slide_direction = (Vector3.DOWN - floor_normal * Vector3.DOWN.dot(floor_normal)).normalized()
	var steepness = remap(current_angle, slide_start_angle, 90.0, 0.0, 1.0)
	steepness = clamp(steepness, 0.0, 1.0)
	
	var slide_force = slide_direction * (steepness * max_slide_accel)
	player.velocity += slide_force * delta
	
	
