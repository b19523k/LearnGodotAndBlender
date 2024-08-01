extends CharacterBody3D

@onready var skeleton = $shambler/Armature/Skeleton3D
@onready var anim_tree = $AnimationTree

var rng = RandomNumberGenerator.new()

var health = 15

var anim_player_rel_path = "../shambler/AnimationPlayer"
var time_between_anims = 3
var deltaTime = 0

var timeOffFloor = 0

var playersInRange = []
var currentPlayerTarget = null

var baseMoveSpeed = 3
var moveAttackSpeed = 0.2

var actionsTaken = 0
var actionsUntilGeneralCooldown = 8

var swipeCoolDown = 4
var smashCoolDown = 6
var shoveCoolDown = 2
var throwCoolDown = 4
var timeSinceSwipe = swipeCoolDown
var timeSinceSmash = smashCoolDown
var timeSinceShove = shoveCoolDown
var timeSinceThrow = throwCoolDown
var timeSinceClose = 0

var animating = false

var availableActions = ["swipe", "smash", "shove"]

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func auto_blender_import():
	# Settings to import from Blender automatically
	anim_tree.anim_player = NodePath(anim_player_rel_path)
	skeleton.rotation.y = 135 #Why tf does this need to be 135

func _ready():
	auto_blender_import()
	anim_tree.active = true

	anim_tree["parameters/conditions/is_dead"] = health <= 0


func _physics_process(delta):
	timeOffFloor += delta
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta * (1 + timeOffFloor)
	else:
		timeOffFloor = 0
	
	timeSinceSwipe += delta
	timeSinceSmash += delta
	timeSinceShove += delta
	timeSinceThrow += delta
	timeSinceClose += delta

	
	if (currentPlayerTarget != null):
		var targetPos = currentPlayerTarget.transform.origin
		var moveDir = (targetPos - position).normalized()

		if(anim_tree["parameters/conditions/general_cooldown"] == false && health > 0):
			look_at(targetPos, Vector3.UP)

		var dist = position.distance_to(targetPos)

		if (!animating && actionsTaken >= actionsUntilGeneralCooldown):
			availableActions.push_front('general_cooldown')
		if (timeSinceSwipe > swipeCoolDown && availableActions.count("swipe") < 3):
			availableActions.push_back("swipe")
			timeSinceSwipe = 0
		if(timeSinceSmash > smashCoolDown && availableActions.count("smash") < 2):
			availableActions.push_back("smash")
			timeSinceSmash = 0
		if((timeSinceShove > shoveCoolDown || dist < 1) && availableActions.count("shove") < 1):
			availableActions.push_back("shove")
			timeSinceShove = 0

		#print(availableActions)
		
		if (availableActions.size() > 0):
			if (!animating && availableActions[0] == "general_cooldown"):
				anim_tree["parameters/conditions/idle"] = true
				anim_tree["parameters/conditions/general_cooldown"] = true
				availableActions.erase("general_cooldown")
				velocity = Vector3.ZERO

			if (dist < 1.6):
				timeSinceClose = 0
			
				if (!animating):
					var nextAction = availableActions.pick_random()
					if (nextAction == 'shove'):
						nextAction = availableActions.pick_random()
					availableActions.erase(nextAction)
					animating = true
					
					if (nextAction == "swipe"):
						anim_tree["parameters/conditions/swipe"] = true
					elif (nextAction == "smash"):
						var smashAngle = 0
						if (dist < 0.9):
							smashAngle = .55
						anim_tree["parameters/smash_blend/blend_position"] = smashAngle
						anim_tree["parameters/conditions/smash"] = true
						velocity = moveDir * moveAttackSpeed
					elif (nextAction == "shove"):
						anim_tree["parameters/conditions/shove"] = true
						
				else:
					velocity = moveDir * moveAttackSpeed
					
			elif (dist > 6 || timeSinceClose > 5):
				if (timeSinceThrow > throwCoolDown):
					if (!animating):
						timeSinceClose = 0
						anim_tree["parameters/conditions/throw"] = true
						anim_tree["parameters/conditions/idle"] = false
						anim_tree["parameters/conditions/walk"] = false
						animating = true
						velocity = Vector3.ZERO
					else:
						velocity = Vector3.ZERO
				else:
					velocity = moveDir * baseMoveSpeed
					anim_tree["parameters/conditions/idle"] = false
					anim_tree["parameters/conditions/walk"] = true
			elif (animating):
				velocity = Vector3.ZERO
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
	if (anim_name == "general_cooldown"):
		anim_tree["parameters/conditions/general_cooldown"] = false
		actionsTaken = 0
		animating = false
	elif (anim_name == "swipe"):
		anim_tree["parameters/conditions/swipe"] = false
		timeSinceSwipe = 0
		actionsTaken += 1
		animating = false
	elif(anim_name == "smash" || anim_name == "smash_down" || anim_name == "smash_up"): # Could also check if smash blend space completed?
		anim_tree["parameters/smash_blend/blend_position"] = 0
		anim_tree["parameters/conditions/smash"] = false
		actionsTaken += 3
		timeSinceSmash = 0
		animating = false
	elif(anim_name == "shove"):
		anim_tree["parameters/conditions/shove"] = false
		timeSinceShove = 0
		actionsTaken += 2
		animating = false
	elif(anim_name == "throw"):
		anim_tree["parameters/conditions/throw"] = false
		timeSinceThrow = 0
		actionsTaken += 1
		animating = false

func takeDamage(amount:int):
	health -= amount
	if (health <= 0):
		anim_tree["parameters/conditions/is_dead"] = true
		print("shambler took: ", amount, " damage, and has died")
	else:
		print("shambler took: ", amount, " damage, and has: ", health, " remaining")

