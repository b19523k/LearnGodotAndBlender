extends CharacterBody3D

@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var armature = $behold_a_man/Armature
@onready var skeleton = $behold_a_man/Armature/Skeleton3D
@onready var anim_tree = $AnimationTree

var anim_player_rel_path = "../behold_a_man/AnimationPlayer"


const LERP_VAL = .15

const RUN_SPEED = 5.0
const ROLL_SPEED = 10.0
const PUNCH_SPEED = 1.0
const JUMP_VELOCITY = 4.5

var is_rolling = false
var is_jumping = false
var is_punching = false
var speed = RUN_SPEED
var is_pooing = false

var timeOffFloor = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func auto_blender_import():
	# Settings to import from Blender automatically
	anim_tree.anim_player = NodePath(anim_player_rel_path)
	skeleton.rotation.y = 135
	
func _ready():
	auto_blender_import()
	
	# Other ready settings
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	anim_tree.active = true

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func update_move_speed():
	speed = RUN_SPEED
	
	if (is_rolling):
		speed = ROLL_SPEED
	elif (is_punching):
		speed = PUNCH_SPEED

func _physics_process(delta):
	timeOffFloor += delta
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta * (1 + timeOffFloor)
	else:
		timeOffFloor = 0
		
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !is_jumping:
		if (is_rolling):
			velocity.y = JUMP_VELOCITY * 1.3
		else:
			velocity.y = JUMP_VELOCITY
		
	update_move_speed()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	update_animation_parameters(direction)
	if direction:
		velocity.x = lerp(velocity.x, direction.x * speed, LERP_VAL)
		velocity.z = lerp(velocity.z, direction.z * speed, LERP_VAL)
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VAL)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		velocity.z = lerp(velocity.z, 0.0, LERP_VAL)
		
	anim_tree.set("parameters/BlendSpace1D/blend_position", velocity.length() / speed)

	move_and_slide()

func update_animation_parameters(is_moving):
	var cameraAngle = rad_to_deg(spring_arm_pivot.global_rotation.y) + 180
	var playerAngle = rad_to_deg(armature.global_rotation.y) + 180
	var punchAngle = (playerAngle - cameraAngle)

	if (punchAngle > 180):
		punchAngle = -45

	if (punchAngle < -180):
		punchAngle = 45

	if (is_moving && Input.is_action_just_pressed("roll")):
		anim_tree["parameters/conditions/is_rolling"] = true
		is_rolling = true
	elif (Input.is_action_just_pressed("jump")):
		anim_tree["parameters/conditions/is_jumping"] = true
		is_jumping = true
		anim_tree["parameters/conditions/is_rolling"] = false
		is_rolling = false
	elif (is_moving && Input.is_action_just_pressed("primary") && !is_jumping && !is_rolling):
		anim_tree["parameters/conditions/is_punching"] = true
		anim_tree["parameters/punch/blend_position"] = deg_to_rad(punchAngle) * 100
		is_punching = true
	elif (Input.is_action_just_pressed("poo")):
		anim_tree["parameters/conditions/is_pooing"] = true
		is_pooing = true


func _on_animation_tree_animation_finished(anim_name): # this needs to be linked to the animation tree
	#print("anim end: " + anim_name)
	if (anim_name == "roll"):
		anim_tree["parameters/conditions/is_rolling"] = false
		is_rolling = false
	elif (anim_name == "jump"):
		anim_tree["parameters/conditions/is_jumping"] = false
		is_jumping = false
	elif (["punch", "punch_l", "punch_r"].has(anim_name)):
	#elif (anim_name == "punch.r" || anim_name == "punch.l" || anim_name == "punch"):
		anim_tree["parameters/conditions/is_punching"] = false
		is_punching = false
	elif (anim_name == "punch_001"):
		anim_tree["parameters/conditions/is_pooing"] = false
		is_pooing = false

