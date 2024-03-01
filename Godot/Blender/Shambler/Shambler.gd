extends CharacterBody3D

@onready var skeleton = $shambler/Armature/Skeleton3D
@onready var anim_tree = $AnimationTree

var anim_player_rel_path = "../shambler/AnimationPlayer"
var time_between_anims = 3
var deltaTime = 0

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
	velocity.z = .1
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
	
