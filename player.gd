extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -600.0
const MAX_GLIDE_DOWN = 50
const MAX_AIR_JUMPS = 1
var air_jumps=MAX_AIR_JUMPS
var jumpRequestedTime = 0
var onFloorTime = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		if(Input.is_action_pressed("ui_accept")):
			velocity.y = min(velocity.y, MAX_GLIDE_DOWN)
	else:
		onFloorTime = Time.get_ticks_msec()
		air_jumps=MAX_AIR_JUMPS

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		jumpRequestedTime = Time.get_ticks_msec()
	
	if JumpRequestedRecentlyEnough():
		if(OnFloorRecentlyEnough()):
			Jump(0)
		else:
			if(air_jumps > 0):
				air_jumps -= 1
				Jump(MAX_AIR_JUMPS - air_jumps)
			
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

const JUMP_REQUEST_RECENT_ENOUGH = 500
func JumpRequestedRecentlyEnough():
	return Time.get_ticks_msec() - jumpRequestedTime < JUMP_REQUEST_RECENT_ENOUGH
	
const ON_FLOOR_RECENT_ENOUGH = 500
func OnFloorRecentlyEnough():
	return Time.get_ticks_msec() - onFloorTime < ON_FLOOR_RECENT_ENOUGH

func Jump(jumpNumber:int):
	jumpRequestedTime = 0
	velocity.y = JUMP_VELOCITY	
