extends CharacterBody2D

const AIR_RESISTANCE:float = 2
const SPEED:float = 300.0
const xaccel:float = 600
const JUMP_VELOCITY:float = 600.0
const MAX_GLIDE_DOWN:int = 80
const MAX_AIR_JUMPS:int = 0
var air_jumps:int=MAX_AIR_JUMPS
var jumpRequestedTime:int=0
var physicsInfo:PhysicsInfo = PhysicsInfo.new()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	CollectPhysicsInfo()
	var glide: int = MAX_GLIDE_DOWN
	
	if Input.is_action_pressed("ui_down"):
		glide*=	4
	
	# Add the gravity.
	if not physicsInfo.onFloor:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, glide)
	else:
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
	var direction: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = move_toward(velocity.x, GetTargetSpeed(direction, SPEED), GetAccel(direction, xaccel, delta))
	move_and_slide()

const JUMP_REQUEST_RECENT_ENOUGH: int = 500
func JumpRequestedRecentlyEnough() -> bool:
	return Time.get_ticks_msec() - jumpRequestedTime < JUMP_REQUEST_RECENT_ENOUGH
	
const ON_FLOOR_RECENT_ENOUGH: int = 500
func OnFloorRecentlyEnough() -> bool:
	return Time.get_ticks_msec() - physicsInfo.onFloorTime < ON_FLOOR_RECENT_ENOUGH

func Jump(jumpNumber:int):
	jumpRequestedTime = 0
	physicsInfo.onFloorTime=0
	physicsInfo.onFloor=false
	var xspd            = abs(velocity.x)
	var pctSpeed: float = SPEED * 0.8
	var extraJump       = 0 if xspd < pctSpeed else (xspd-pctSpeed)/ SPEED * JUMP_VELOCITY /3
	velocity.y -= (JUMP_VELOCITY + extraJump)
	
func GetTargetSpeed(direction:float, speed:float) -> float:
	var goingDownHill:bool = physicsInfo.downHillDirection == 1 && direction == 1
	var extraSpeed:float = 0 if !goingDownHill else speed * physicsInfo.floorNormal.x * 2
	speed += extraSpeed
	return direction * speed
	
func GetAccel(direction:float, accel:float, delta:float) -> float:
	if !physicsInfo.onFloor:
		if(direction == 0):
			return AIR_RESISTANCE;  #in air, no effort, no acceleration
		var couldPropelSelfFasterInSameDirection = abs(velocity.x) < SPEED
		var propelingFasterInSameDirection: bool = (direction>0) == (velocity.x>0) && couldPropelSelfFasterInSameDirection
		var pushingAgainstVelocity: bool         = (velocity.x >0) != (direction >0)
		if(!propelingFasterInSameDirection && !pushingAgainstVelocity ):
			return AIR_RESISTANCE;
	var goingDownHill:bool = physicsInfo.downHillDirection == 1 && direction == 1
	var extraAccel:float = 0 if !goingDownHill else accel * physicsInfo.floorNormal.x * 2
	if(extraAccel > 0):
		accel += extraAccel
	return accel * delta
		
func CollectPhysicsInfo():
	physicsInfo.onFloor = is_on_floor()
	physicsInfo.floorNormal = Vector2.ZERO if !physicsInfo.onFloor else get_floor_normal()
	if physicsInfo.onFloor: physicsInfo.onFloorTime = Time.get_ticks_msec()
	physicsInfo.lastSlideCollision = get_last_slide_collision()
	physicsInfo.downHillDirection = 0 if !physicsInfo.onFloor else 1 if physicsInfo.floorNormal.x > 0 else -1
	physicsInfo.floorSlope = 0 if (!physicsInfo.onFloor) else get_floor_angle()
