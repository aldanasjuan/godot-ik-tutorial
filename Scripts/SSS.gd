tool
extends Node2D
class_name SSSIK

class Bone:
	var start : Node2D
	var end : Node2D
	var length := 0.0
	func _init(_start : Node2D, _end : Node2D):
		start = _start
		end = _end
		length = start.global_position.distance_to(end.global_position)
	func angle():
		return end.global_position.angle_to_point(start.global_position)
	func inner_angle():
		return end.position.angle()
	func normal():
		return start.global_position.direction_to(end.global_position)

class Bones:
	var a : Bone
	var b : Bone
	var c : Bone
	func keys():
		return ["a","b","c"]


export (int, -1, 1) var direction := 0 setget set_direction
export (bool) var follow := false
export (Vector2) var offset := Vector2.ZERO
export (NodePath) var root setget set_root
export (NodePath) var bone_a setget set_bone_a
export (NodePath) var end_bone_a setget set_end_bone_a
export (NodePath) var bone_b setget set_bone_b
export (NodePath) var end_bone_b setget set_end_bone_b
export (NodePath) var bone_c setget set_bone_c
export (NodePath) var end_bone_c setget set_end_bone_c
export (NodePath) var target setget set_target

export (bool) var draw_bones := false
export (bool) var draw_target := false
export (bool) var view_target_in_game := false
export (bool) var view_bones_in_game := false
export (Color) var target_color := Color.green

export (float, 0.1, 1, 0.01) var lerp_rate := 0.2
export (float) var lerp_range := 10.0

export (float, -180, 180, 0.01) var c_rotation_degrees := 0.0 setget set_rotation_degrees
export (float, -180, 180, 0.01) var c_rotation_offset := 0.0 setget set_rotation_offset
export (float, -180, 180, 0.01) var c_max_rotation := 90.0
export (float, -180, 180, 0.01) var c_min_rotation := -90.0
export (bool) var constrain_c_angle := false
export (bool) var reset := false setget set_reset

var bones : Bones = Bones.new()
var root_node : Node2D
var flip_vector := Vector2(1,1)
var target_node : Node2D
var total_length := 0.0
var min_dist := 0.0
var ready := false
var distance_to_target := 0.0
var remaining_distance_to_target := 0.0

func set_reset(value):
	reset = false
	init()

func _ready():
	init()

func init():
	
#	add_child(tween)
	if has_node(root):
		root_node = get_node(root)
	if has_node(target):
		target_node = get_node(target)
	total_length = 0
	if has_node(bone_a) && has_node(bone_b) && has_node(bone_c) && has_node(end_bone_a) && has_node(end_bone_b) && has_node(end_bone_c):
		bones.a = Bone.new(get_node(bone_a), get_node(end_bone_a))
		bones.b = Bone.new(get_node(bone_b), get_node(end_bone_b))
		bones.c = Bone.new(get_node(bone_c), get_node(end_bone_c))
		min_dist = bones.a.length - bones.b.length
		total_length = bones.a.length + bones.b.length
		ready = true
	else:
		ready = false

func _draw():
	if draw_target && target_node && (Engine.editor_hint || view_target_in_game):
		draw_circle((target_node.global_position + offset - global_position) * flip_vector, 5, target_color)
	if draw_bones && Engine.editor_hint || view_bones_in_game:
		for i in bones.keys():
			var bone : Bone = bones[i]
			draw_circle((bone.start.global_position - global_position) * flip_vector, 4, Color.white)
			draw_circle((bone.end.global_position - global_position) * flip_vector, 4, Color.white)
			draw_line((bone.start.global_position - global_position) * flip_vector, (bone.end.global_position  - global_position) * flip_vector, Color.white, 2)


func _process(delta):
	if !ready:
		return
	update()
	if target_node && follow:
		get_ik()
	else:
		forward()
	bones.c.start.rotation = lerp_angle(bones.c.start.rotation, deg2rad(c_rotation_degrees + c_rotation_offset), lerp_rate * Engine.time_scale)
	
	
func forward():
	bones.c.start.global_position = bones.b.end.global_position
	bones.b.start.global_position = bones.a.end.global_position
	bones.a.start.global_position = global_position

	
func get_ik():
	if root_node && flip_vector.x != root_node.transform.x.x:
		flip_vector.x = root_node.transform.x.x
		
	var target_pos = target_node.global_position + offset
	remaining_distance_to_target = bones.b.end.global_position.distance_to( (target_pos) * flip_vector) 
	if remaining_distance_to_target < 0.05:
		return

	distance_to_target = bones.a.start.global_position.distance_to(target_pos)

	#calculate lerp weight
	var clamped = clamp(remaining_distance_to_target, 0, lerp_range) # 100
	var weight = stepify(range_lerp(clamped, 0, lerp_range, 1, lerp_rate), 0.1) # 0.2
	
	var direction_to_target = bones.a.start.global_position.direction_to(target_pos) * flip_vector
	var parent_angle = get_parent().rotation
	var angle_to_target = direction_to_target.angle() - parent_angle

	if distance_to_target < total_length:
		if distance_to_target < min_dist:
			distance_to_target = min_dist
		var angles = sss(bones.a.length, bones.b.length, distance_to_target, direction)
		if !is_nan(angles.a) && !is_nan(angles.b):
			bones.a.start.rotation = lerp_angle(bones.a.start.rotation, angle_to_target - bones.a.inner_angle() + angles.b, weight * Engine.time_scale)
			bones.b.start.rotation = lerp_angle(bones.b.start.rotation, angle_to_target - bones.b.inner_angle() - angles.a, weight * Engine.time_scale)
	else:
		bones.a.start.rotation = lerp_angle(bones.a.start.rotation, angle_to_target - bones.a.inner_angle(), weight * Engine.time_scale)
		bones.b.start.rotation = lerp_angle(bones.b.start.rotation, angle_to_target - bones.b.inner_angle(), weight * Engine.time_scale)

	bones.a.start.global_position = global_position
	bones.b.start.global_position = bones.a.end.global_position
	bones.c.start.global_position = bones.b.end.global_position

func sss(side_a, side_b, side_c, dir):
	if side_c >= side_a + side_b:
		return {"a": 0, "b": 0}
	var angle_a = law_of_cos(side_b, side_c, side_a)
	var angle_b = law_of_cos(side_c, side_a, side_b)
	return {"a": angle_a * dir, "b": angle_b * dir}

func law_of_cos(a : float,b : float,c : float):
	if 2 * a * b == 0:
		return 0
	return acos( (a * a + b * b - c * c) / (2 * a * b) )


#helpers
func follow_plane(plane : Plane2D):
	if ready:
		var diff = plane.normal * plane.distance_to((target_node.global_position + offset))
		offset -= diff

func follow_plane_with_normal(plane : Plane2D, normal : Vector2, distance : float):
	if ready:
		var diff = (plane.normal * plane.distance_to((target_node.global_position + offset))) + (normal * distance * -1)
		offset = lerp(offset, offset - diff, lerp_rate * Engine.time_scale)

func follow_point(point : Vector2):
	if ready:
		var diff = point - (target_node.global_position + offset)
		offset += diff

func follow_point_with_normal(point : Vector2, normal : Vector2, distance : float):
	if ready:
		var diff = (point - (target_node.global_position + offset) + (normal * distance * -1))
		offset += diff

func reset_offset(weight : float):
	if ready:
		offset = lerp(offset, Vector2.ZERO, weight)

func reset_offset_with_normal(normal : Vector2, distance : float, weight : float):
	if ready:
		offset = lerp(offset, normal * distance * -1, weight)
#end of helpers


#setters
func set_rotation_degrees(value):
	c_rotation_degrees = value

func set_rotation_offset(value):
	if constrain_c_angle && c_rotation_degrees + value > c_max_rotation:
		c_rotation_offset = c_max_rotation - c_rotation_degrees
	elif constrain_c_angle && c_rotation_degrees + value < c_min_rotation:
		c_rotation_offset = c_min_rotation - c_rotation_degrees
	else:
		c_rotation_offset = value
func set_direction(v):
	if direction == -1:
		direction = 1
	else:
		direction = -1
func set_bone_a(v):
	bone_a = v
	init()
func set_end_bone_a(v):
	end_bone_a = v
	init()
func set_bone_b(v):
	bone_b = v
	init()
func set_end_bone_b(v):
	end_bone_b = v
	init()
func set_bone_c(v):
	bone_c = v
	init()
func set_end_bone_c(v):
	end_bone_c = v
	init()
func set_target(v):
	target = v
	init()
func set_root(v):
	root = v
	init()




