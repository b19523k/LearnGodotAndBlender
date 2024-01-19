extends CharacterBody3D

@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var armature = $Armature
@onready var anim_tree = $AnimationTree
@onready var anim_player = $AnimationPlayer

const LERP_VAL = .15

const RUN_SPEED = 5.0
const ROLL_SPEED = 10.0

var is_rolling = false
var is_jumping = false
var speed = RUN_SPEED

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	anim_tree.active = true

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if (is_rolling):
		speed = ROLL_SPEED
	else:
		speed = RUN_SPEED

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
	if (is_moving && Input.is_action_just_pressed("roll")):
		anim_tree["parameters/conditions/is_rolling"] = true
		is_rolling = true
	elif (Input.is_action_just_pressed("jump")):
		anim_tree["parameters/conditions/is_jumping"] = true
		is_jumping = true
		anim_tree["parameters/conditions/is_rolling"] = false
		is_rolling = false
		
		


func _on_animation_tree_animation_finished(anim_name): # this needs to be linked to the animation tree
	#print("anim end: " + anim_name)
	if (anim_name == "roll"):
		anim_tree["parameters/conditions/is_rolling"] = false
		is_rolling = false
	if (anim_name == "jump"):
		anim_tree["parameters/conditions/is_jumping"] = false
		is_jumping = false
