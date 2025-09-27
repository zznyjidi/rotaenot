extends Node2D

signal rotation_changed(angle: float)
signal basket_entered(basket: String)
signal basket_exited(basket: String)

var current_rotation: float = 0.0
var target_rotation: float = 0.0
var rotation_speed: float = 5.0
var smoothing_factor: float = 0.15

var mouse_control: bool = true
var gyro_available: bool = false
var current_basket: String = ""

var basket_width: float = 45.0
var left_basket_center: float = 270.0
var right_basket_center: float = 90.0

func _ready():
	_check_gyroscope_availability()

func _check_gyroscope_availability():
	if Input.get_connected_joypads().size() > 0:
		for joypad in Input.get_connected_joypads():
			if Input.is_joy_known(joypad):
				print("Controller detected, checking for gyro...")

	if Input.get_accelerometer() != Vector3.ZERO:
		gyro_available = true
		print("Gyroscope/Accelerometer available")
	else:
		gyro_available = false
		print("No gyroscope detected, using mouse/keyboard controls")

func _process(delta):
	if mouse_control and not gyro_available:
		_handle_mouse_rotation(delta)
	elif gyro_available:
		_handle_gyro_rotation(delta)

	_handle_keyboard_rotation(delta)

	current_rotation = lerp_angle(current_rotation, target_rotation, smoothing_factor)
	rotation = current_rotation

	rotation_changed.emit(rad_to_deg(current_rotation))
	_check_basket_position()

func _handle_mouse_rotation(delta):
	var mouse_pos = get_global_mouse_position()
	var center = get_viewport_rect().size / 2
	var angle_to_mouse = (mouse_pos - center).angle()
	target_rotation = angle_to_mouse

func _handle_gyro_rotation(delta):
	var accel = Input.get_accelerometer()
	if accel != Vector3.ZERO:
		var angle = atan2(accel.x, -accel.y)
		target_rotation = angle

func _handle_keyboard_rotation(delta):
	var rotation_input = 0.0

	if Input.is_action_pressed("rotate_left"):
		rotation_input -= 1.0
	if Input.is_action_pressed("rotate_right"):
		rotation_input += 1.0

	if rotation_input != 0:
		target_rotation += rotation_input * rotation_speed * delta
		mouse_control = false
	elif Input.is_action_just_pressed("ui_select"):
		mouse_control = true

func _check_basket_position():
	var angle_deg = rad_to_deg(current_rotation)
	while angle_deg < 0:
		angle_deg += 360
	while angle_deg >= 360:
		angle_deg -= 360

	var new_basket = ""

	var left_min = left_basket_center - basket_width / 2
	var left_max = left_basket_center + basket_width / 2
	if angle_deg >= left_min and angle_deg <= left_max:
		new_basket = "left"

	var right_min = right_basket_center - basket_width / 2
	var right_max = right_basket_center + basket_width / 2
	if angle_deg >= right_min and angle_deg <= right_max:
		new_basket = "right"

	if new_basket != current_basket:
		if current_basket != "":
			basket_exited.emit(current_basket)
		if new_basket != "":
			basket_entered.emit(new_basket)
		current_basket = new_basket

func set_rotation_angle(degrees: float):
	var radians = deg_to_rad(degrees)
	current_rotation = radians
	target_rotation = radians
	rotation = radians

func get_rotation_degrees() -> float:
	return rad_to_deg(current_rotation)

func calibrate():
	current_rotation = 0.0
	target_rotation = 0.0
	rotation = 0.0