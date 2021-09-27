extends Node2D




var point : Vector2

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().reload_current_scene()
	
	
	if Input.is_mouse_button_pressed(1):
		point = get_global_mouse_position()
		
	$platform.global_position = point
	if Input.is_action_pressed("ui_select"):
		$platform.rotation = $platform.global_position.angle_to_point(global_position) + deg2rad(90)
