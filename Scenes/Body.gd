extends Node2D

var walking := true
var point : Vector2


func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		walk()
	
	if Input.is_mouse_button_pressed(1):
		point = get_global_mouse_position()
		
	$ray.global_rotation = $ray.global_position.angle_to_point(point) + deg2rad(90)
	if $ray.is_colliding():
		update_floor()


func walk():
	if walking:
		$anim.play("stance")
	else:
		$anim.play("walk")
	
	walking = !walking

func update_floor():
	var normal = $ray.get_collision_normal()
	var coll = $ray.get_collision_point()
	var floor_angle = normal.angle() + deg2rad(90)
	$hip/left_leg.offset = normal * $hip/left_leg.bones.c.length
	$hip/right_leg.offset = normal * $hip/right_leg.bones.c.length
	
	$hip/left_leg.c_rotation_offset = rad2deg(floor_angle)
	$hip/right_leg.c_rotation_offset = rad2deg(floor_angle)
	$targets.global_position = coll
	$targets.rotation = floor_angle
