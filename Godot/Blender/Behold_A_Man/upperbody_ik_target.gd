extends Node3D

var cameraXOffset = -0.08726646 # 5 degrees
# var cameraXOffset = 0
var cameraYOffset = PI

func setRotation(targetX, targetY):
	# Weird ass offsets because I fucked up the blender model import or something
	rotation.x = -targetX + cameraXOffset
	rotation.y = targetY + cameraYOffset
