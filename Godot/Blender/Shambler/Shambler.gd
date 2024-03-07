extends CharacterBody3D

@onready var skeleton = $shambler/Armature/Skeleton3D
@onready var anim_tree = $AnimationTree

var rng = RandomNumberGenerator.new()

var anim_player_rel_path = "../shambler/AnimationPlayer"
var time_between_anims = 3
var deltaTime = 0

var playersInRange = []
var currentPlayerTarget = null

var baseMoveSpeed = 3
var moveAttackSpeed = 0.2

var swipeCoolDown = 4
var smashCoolDown = 6
var shoveCoolDown = 0.5
var throwCoolDown = 3
var timeSinceSwipe = swipeCoolDown
var timeSinceSmash = smashCoolDown
var timeSinceShove = shoveCoolDown
var timeSinceThrow = throwCoolDown

var availableActions = ["swipe", "smash", "shove"]

func auto_blender_import():
	# Settings to import from Blender automatically
	anim_tree.anim_player = NodePath(anim_player_rel_path)
	skeleton.rotation.y = 135 #Why tf does this need to be 135

func _ready():
	auto_blender_import()
	anim_tree.active = true
	


func _physics_process(delta):
	timeSinceSwipe += delta
	timeSinceSmash += delta
	timeSinceShove += delta
	timeSinceThrow += delta
	
	if (currentPlayerTarget != null):
		var targetPos = currentPlayerTarget.transform.origin
		var moveDir = (targetPos - position).normalized()
		
		look_at(targetPos, Vector3.UP)
		
		var dist = position.distance_to(targetPos)
		print(dist)
		
		if (dist < 1.6):
			if (timeSinceSwipe > swipeCoolDown && availableActions.count("swipe") < 2):
				availableActions.push_back("swipe")
				timeSinceSwipe = 0
			elif(timeSinceSmash > smashCoolDown && availableActions.count("smash") < 2):
				availableActions.push_back("smash")
				timeSinceSmash = 0
			elif(timeSinceShove > shoveCoolDown):
				availableActions.push_back("shove")
				timeSinceShove = 0
			
			var nextAction = availableActions.pick_random()
			availableActions.erase(nextAction)
			
			if (nextAction == "swipe"):
				anim_tree["parameters/conditions/swipe"] = true
				velocity = moveDir * moveAttackSpeed
			elif (nextAction == "smash"):
				anim_tree["parameters/conditions/smash"] = true
				velocity = moveDir * moveAttackSpeed
			elif (nextAction == "shove"):
				anim_tree["parameters/conditions/shove"] = true
				velocity = moveDir * moveAttackSpeed

				
		elif (dist > 6):
			if (timeSinceThrow > throwCoolDown):
				anim_tree["parameters/conditions/throw"] = true
				velocity = Vector3.ZERO * 0
			else:
				velocity = moveDir * baseMoveSpeed
		else:
			anim_tree["parameters/conditions/idle"] = false
			anim_tree["parameters/conditions/walk"] = true
			velocity = moveDir * baseMoveSpeed
	else:
		velocity = Vector3.ZERO
		anim_tree["parameters/conditions/idle"] = true
		anim_tree["parameters/conditions/walk"] = false
		
		#anim_tree["parameters/conditions/idle"] = false
		#anim_tree["parameters/conditions/death"] = true
		#anim_tree["parameters/conditions/death"] = false
		#anim_tree["parameters/conditions/attack"] = true
		#anim_tree["parameters/conditions/attack"] = false
		#
		#anim_tree["parameters/conditions/walk"] = false
		#anim_tree["parameters/conditions/idle"] = true
		
	move_and_slide()
	


func _on_rigid_body_3d_body_entered(body):
	playersInRange.push_back(body)
	if (currentPlayerTarget == null):
		currentPlayerTarget = playersInRange[0]


func _on_rigid_body_3d_body_exited(body):
	playersInRange.erase(body)
	if (body == currentPlayerTarget):
		if (playersInRange.size() > 0):
			currentPlayerTarget = playersInRange[0]
		else:
			currentPlayerTarget = null


func _on_animation_tree_animation_finished(anim_name):
	if (anim_name == "swipe"):
		anim_tree["parameters/conditions/swipe"] = false
		timeSinceSwipe = 0
	elif(anim_name == "smash"):
		anim_tree["parameters/conditions/smash"] = false
		timeSinceSmash = 0
	elif(anim_name == "shove"):
		anim_tree["parameters/conditions/shove"] = false
		timeSinceShove = 0
	elif(anim_name == "throw"):
		anim_tree["parameters/conditions/throw"] = false
		timeSinceThrow = 0
