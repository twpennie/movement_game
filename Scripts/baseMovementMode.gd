extends Resource 
class_name MovementMode

var canJump : bool = true
var hasJumped : bool = false
var jumpQueued : bool = false

func ground(player: CharacterBody3D, delta : float) -> void:
	pass
	
func air(player: CharacterBody3D, delta : float) -> void:
	pass
