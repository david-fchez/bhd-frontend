extends Spatial

export (NodePath) var target

export (float, 0.0, 2.0) var rotation_speed = PI/2

# mouse properties

export (bool) var mouse_control = false
export (float, 0.001, 0.1) var mouse_sensitivity = 0.005
export (bool) var invert_y = false
export (bool) var invert_x = false

export (Vector3) var Heading = Vector3(0,0,0)

var dragging = false

var events = {}
var last_drag_distance = 0.0

func _ready():
	#set default rotation of arrow to UP
	#$InnerGimbal.rotate_object_local(Vector3.RIGHT, -85)
	$InnerGimbal.rotate_x(-1.5708)
	pass

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
		else:
			dragging = false
	if mouse_control and event is InputEventMouseMotion and dragging:
		if event.relative.x != 0:
			var dir = 1 if invert_x else -1
			rotate_object_local(Vector3.UP, dir * event.relative.x * mouse_sensitivity)
		if event.relative.y != 0:
			var dir = 1 if invert_y else -1
			var y_rotation = clamp(event.relative.y, -30, 30)
			$InnerGimbal.rotate_object_local(Vector3.RIGHT, dir * y_rotation * mouse_sensitivity)
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
		else:
			events.erase(event.index)
	if event is InputEventScreenDrag:
		events[event.index] = event
		if events.size() == 1:
			pass
			#position += event.relative.rotated(rotation) * zoom.x

func get_input_keyboard(delta):
	# Rotate outer gimbal around y axis

	var y_rotation = 0
	if Input.is_action_pressed("cam_right"):
		y_rotation += 1
	if Input.is_action_pressed("cam_left"):
		y_rotation += -1
	rotate_object_local(Vector3.UP, y_rotation * rotation_speed * delta)
	# Rotate inner gimbal around local x axis

	var x_rotation = 0
	if Input.is_action_pressed("cam_up"):
		x_rotation += -1
	if Input.is_action_pressed("cam_down"):
		x_rotation += 1
	x_rotation = -x_rotation if invert_y else x_rotation
	$InnerGimbal.rotate_object_local(Vector3.RIGHT, x_rotation * rotation_speed * delta)

func _process(delta):
	#if !mouse_control:
	get_input_keyboard(delta)
	#$InnerGimbal.rotation.x = clamp($InnerGimbal.rotation.x, -1.4, 0.5)
	#scale = lerp(scale, Vector3.ONE * zoom, zoom_speed)
	if target:
		global_transform.origin = get_node(target).global_transform.origin
	self.Heading = ($InnerGimbal/arrow.global_transform.origin - Vector3(5,5,5)).normalized()