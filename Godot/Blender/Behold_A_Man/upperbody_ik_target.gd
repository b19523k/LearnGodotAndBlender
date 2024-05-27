extends Node3D

func match_rotation(x, y):
    # Weird ass offsets because I fucked up the blender model import or something
    rotation.x = -x
    rotation.y = y + PI 