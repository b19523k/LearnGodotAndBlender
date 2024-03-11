# Tutorials Used

## Basics of Godot and Blender Animation

### Tutorial Video

[Godot 4 / Blender - Third Person Character From Scratch](https://www.youtube.com/watch?v=VasHZZyPpYU)

### Why watch it

Learn how to create a controllable 3D character

### Contents and timestamps

- 00:53 - 19:30 : Blender modelling
- 19:31 - 30:30 : Blender rigging
- 30:31 - 44:05 : Blender animating
- 44:05 - end : Godot setup

## Animation State Machines

### Tutorial Video

[Animation Tree State Machine Setup w/ Conditions & BlendSpace2D - Godot 4 Resource Gatherer Tutorial](https://www.youtube.com/watch?v=WrMORzl3g1U)

### Why watch it

Learn how to setup a animation state machine to control the player model while the player performs different actions. For example, add a roll animation that triggers when the player presses space, and transition back and forth to a blendspace1D for standing still / running.

### Contents and timestamps

- 00:00 - 07:00ish : setup the state machine, setup transition parameters, set transition parameters in code

## Move Enemy Towards Player

![image](tutorials_used/moveEnemyTowardsPlayer.png)

## Dynamically Blending Animations

### Tutorial Video

[Godot Quick Tip - How to use AnimationTrees](https://www.youtube.com/watch?v=WY2cN9uG6W8&ab_channel=Miziziziz)

### Why watch it

Learn how to blend animations, including seperating upper/lower body for things like aiming a gun while running.

## Link Bone To Deform Model

[Assign Vertext Group To Specific Bone | Blender Rig Tutorial](https://www.youtube.com/watch?v=P47IpDEj2Y4&ab_channel=Himel356)

### Why Watch it

Quick explaination on how to create a vertex group, and link it to a bone for model deformation during posing / animating.

### Too Long, Didn't Watch

In edit mode on the model geometry, select a group vertexs, press ctrl+g, and "Assign to new vertex group". Name the vertex group in the "Data" tab on the bottom right (3 green boxes linked by green lines in inverted diamond formation). Set the bone to have the same name as the vertex group, and the bone will deform the vertex group when moved.