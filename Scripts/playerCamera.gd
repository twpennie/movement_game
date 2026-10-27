extends Camera3D

var defaultFOV : float = fov
#@export var runFOV : float = 98
@export var player : PlayerMovement

@export var jumpRotation : Vector3 = Vector3(-1.0, -0.5, 0.2)
@export var jumpAnimation : ProceduralCurve

@export var landPosition : Vector3 = Vector3(0, -0.15, 0)
@export var landPosAnimation : ProceduralCurve

@export var landRotation : Vector3 = Vector3(-0.5, 0, 0)
@export var landRotAnimation : ProceduralCurve

@onready var rotationAnims = [jumpAnimation, landRotAnimation]
@onready var posAnims = [landPosAnimation]

@export var slideTilt : float = -1.0

@export var wallRunTilt : float = -3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.justJumped.connect(startJumpAnimation)
	player.justLanded.connect(startLandAnimation)

	jumpAnimation.set_targets(Vector3.ZERO, jumpRotation, Vector3.ZERO)
	landPosAnimation.set_targets(Vector3.ZERO, landPosition, Vector3.ZERO)
	landRotAnimation.set_targets(Vector3.ZERO, landRotation, Vector3.ZERO)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#fov = lerp(defaultFOV, runFOV, player.velocity.length()/player.speed)
	for anim in rotationAnims:
		if anim.is_running():
			rotation_degrees = anim.step(delta)
	
	for anim in posAnims:
		if anim.is_running():
			position = anim.step(delta)
	
	for anim in tiltAnims:
		if anim.is_running():
			rotation_degrees.z = anim.step(delta)


func startJumpAnimation() -> void:
	landPosAnimation.force_stop()
	landRotAnimation.force_stop()
	jumpAnimation.start(rotation_degrees)
	
func startLandAnimation() -> void:
	jumpAnimation.force_stop()
	landPosAnimation.start(position)
	landRotAnimation.start(rotation_degrees)
