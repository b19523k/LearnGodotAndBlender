extends CharacterBody3D

@onready var skeleton = $shambler/Armature/Skeleton3D
@onready var anim_tree = $AnimationTree

var anim_player_rel_path = "../shambler/AnimationPlayer"
var time_between_anims = 3
var deltaTime = 0

var playersInRange = []
var currentPlayerTarget = null

var MV_SP = 3

var idle = true
var death = false
var attack = false
var walk = false

func auto_blender_import():
	# Settings to import from Blender automatically
	anim_tree.anim_player = NodePath(anim_player_rel_path)
	skeleton.rotation.y = 135

func _ready():
	auto_blender_import()
	
	anim_tree.active = true


func _physics_process(delta):
	
	if (currentPlayerTarget != null):
		var targetPos = currentPlayerTarget.transform.origin
		var moveDir = (targetPos - position).normalized()
		velocity = moveDir * MV_SP
		look_at(targetPos, Vector3.UP)
	else:
		velocity = Vector3.ZERO
	

	
	deltaTime = deltaTime + delta
	if (deltaTime > time_between_anims):
		deltaTime = deltaTime - time_between_anims
		if (idle):
			idle = false
			death = true
			anim_tree["parameters/conditions/idle"] = false
			anim_tree["parameters/conditions/death"] = true
		elif (death):
			death = false
			attack = true
			anim_tree["parameters/conditions/death"] = false
			anim_tree["parameters/conditions/attack"] = true
		elif (attack):
			attack = false
			walk = true
			anim_tree["parameters/conditions/attack"] = false
			anim_tree["parameters/conditions/walk"] = true
		elif (walk):
			walk = false
			idle = true
			anim_tree["parameters/conditions/walk"] = false
			anim_tree["parameters/conditions/idle"] = true
	move_and_slide()
	


func _on_rigid_body_3d_body_entered(body):
	playersInRange.push_back(body)
	if (currentPlayerTarget == null && playersInRange.size() > 0):
		currentPlayerTarget = playersInRange[0]


func _on_rigid_body_3d_body_exited(body):
	playersInRange.erase(body)
	if (body == currentPlayerTarget):
		if (playersInRange.size() > 0):
			currentPlayerTarget = playersInRange[0]
		else:
			currentPlayerTarget = null
