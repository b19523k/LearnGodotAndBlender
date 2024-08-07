extends CharacterBody3D

@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var armature = $behold_a_man/Armature
@onready var skeleton = $behold_a_man/Armature/Skeleton3D
@onready var anim_tree = $AnimationTree
@onready var upperbody_ik = $behold_a_man/Armature/Skeleton3D/spine_ik
@onready var upperbody_ik_target = $upperbody_ik_target
@onready var healthBar = $HealthBar

var anim_player_rel_path = "../behold_a_man/AnimationPlayer"


const LERP_VAL = .15
# const LERP_VAL = 1

const RUN_SPEED = 5.0
const ROLL_SPEED = 10.0
const PUNCH_SPEED = 1.0
const JUMP_VELOCITY = 6

var maxHealth = 100
var health = 40
var attackHit = false

var is_rolling = false
var roll_started = false
var is_jumping = false
var jump_started = false
var is_punching = false
var punch_started = false

var speed = RUN_SPEED

var is_blocking = false

var timeOffFloor = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func auto_blender_import():
	# Settings to import from Blender automatically
	anim_tree.anim_player = NodePath(anim_player_rel_path)
	skeleton.rotation.y = 135
	
func _ready():
	auto_blender_import()

	upperbody_ik_target.setRotation(spring_arm.rotation.x, spring_arm_pivot.rotation.y)
	upperbody_ik.start()
	
	# Other ready settings
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	anim_tree.active = true

	healthBar.max_value = maxHealth
	healthBar.value = maxHealth
	health = maxHealth

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/4)
		upperbody_ik_target.setRotation(spring_arm.rotation.x, spring_arm_pivot.rotation.y)

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
		anim_tree.set("parameters/upperLowerBlend/turnBlend/blend_amount", 0)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		velocity.z = lerp(velocity.z, 0.0, LERP_VAL)
		var lerpYOne = lerp_angle(armature.rotation.y, spring_arm_pivot.rotation.y, 1) # Need to detect if rotation diff is half a circle (0.5 rad)
		var lerpYTriple = lerp_angle(armature.rotation.y, spring_arm_pivot.rotation.y, LERP_VAL * 3) # Need to detect if rotation diff is half a circle (0.5 rad)
		var lerpY = lerp_angle(armature.rotation.y, spring_arm_pivot.rotation.y, LERP_VAL) # Need to detect if rotation diff is half a circle (0.5 rad)
		var yDiff = snappedf(lerpY - armature.rotation.y, 0.001)
		# print(yDiff)
		if (yDiff != 0):
			armature.rotation.y = lerpY if abs(yDiff) < LERP_VAL * 2 else lerpYTriple if abs(yDiff) < LERP_VAL * 3 else lerpYOne
			# armature.rotation.y = lerpYOne
			# armature.rotation.y = lerpY
			var clampedYDiff = clampf(yDiff * 50, -1 , 1)
			anim_tree.set("parameters/upperLowerBlend/turnBlend/blend_amount", clampedYDiff)
		else:
			anim_tree.set("parameters/upperLowerBlend/turnBlend/blend_amount", 0)

		
	anim_tree.set("parameters/upperLowerBlend/idleRunBlend/blend_position", velocity.length() / speed)

	move_and_slide()

func update_animation_parameters(is_moving):

	if (is_moving && Input.is_action_just_pressed("roll") && !is_jumping && !is_punching && !is_rolling):
		upperbody_ik.stop()
		is_rolling = true
	elif (Input.is_action_just_pressed("jump") && !is_punching && !is_jumping):
		is_jumping = true
		if (is_rolling):
			upperbody_ik.start()
			is_rolling = false
	elif (is_moving && Input.is_action_just_pressed("primary") && !is_jumping && !is_rolling && !is_punching):
		is_punching = true
	elif (Input.is_action_just_released("block")):
		is_blocking = false
		anim_tree.set("parameters/upperLowerBlend/blockBlend/blend_amount", 0)
	elif (Input.is_action_pressed("block")):
		is_blocking = true
		anim_tree.set("parameters/upperLowerBlend/blockBlend/blend_amount", 1)

func _on_animation_tree_animation_finished(anim_name): # this needs to be linked to the animation tree
	# print("animation ended: " , anim_name)
	if (anim_name == "roll"):
		is_rolling = false
		roll_started = false
		upperbody_ik.start()
	elif (anim_name == "jump"):
		is_jumping = false
		jump_started = false
		is_rolling = false
		roll_started = false
		upperbody_ik.start()
	elif (anim_name == "punch"):
		is_punching = false
		punch_started = false
		attackHit = false

func _on_animation_tree_animation_started(anim_name:StringName):
	# print("animation started: ", anim_name)
	if (anim_name == "punch"):
		punch_started = true
	elif (anim_name == "jump"):
		jump_started = true
	elif (anim_name == "roll"):
		roll_started = true

func _on_punch_rigid_body_3d_hitbox_entered(collidedWith:Node):
	if (!attackHit && punch_started):
		var collsionOwner = collidedWith.owner
		collsionOwner.takeDamage(3)
		attackHit = true

func takeDamage(amount:int):
	health -= amount
	healthBar.value = health
	print("Player took: ", amount, " damage, and has: ", health, " health remaining")