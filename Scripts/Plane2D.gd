class_name Plane2D

var normal : Vector2
var origin : Vector2
var distance : float

func _init(n : Vector2 = Vector2.ZERO, d : Vector2 = Vector2.ZERO):
	normal = n
	distance = normal.dot(d)
	origin = d

func update_points(n : Vector2 = Vector2.ZERO, d : Vector2 = Vector2.ZERO):
	normal = n
	distance = normal.dot(d)
	origin = d


func from_two_points(a : Vector2 = Vector2.ZERO, b : Vector2 = Vector2.ZERO):
	var dvec = (b - a).normalized()
	normal = Vector2(dvec.y, -dvec.x)
	distance = normal.dot(a)

func distance_to(point : Vector2):
	return normal.dot(point) - distance


func point_in_plane(length : float):
	return origin + (normal.rotated(1.5708) * length)
	
