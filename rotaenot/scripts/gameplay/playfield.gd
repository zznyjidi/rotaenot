extends Node2D

@onready var outer_ring = $JudgmentCircle/OuterRing
@onready var inner_ring = $JudgmentCircle/InnerRing
@onready var left_basket = $Baskets/LeftBasket
@onready var right_basket = $Baskets/RightBasket
@onready var rotation_indicator = $RotationIndicator

var judgment_radius = 300.0
var inner_radius = 50.0
var basket_width = 45.0
var rotation_controller

func _ready():
	rotation_controller = load("res://scripts/input/rotation_controller.gd").new()
	add_child(rotation_controller)

	if rotation_controller.has_signal("rotation_changed"):
		rotation_controller.rotation_changed.connect(_on_rotation_changed)
	if rotation_controller.has_signal("basket_entered"):
		rotation_controller.basket_entered.connect(_on_basket_entered)
	if rotation_controller.has_signal("basket_exited"):
		rotation_controller.basket_exited.connect(_on_basket_exited)

	_setup_circles()
	_setup_baskets()

func _setup_circles():
	var points_outer = []
	var points_inner = []
	var segments = 64

	for i in range(segments + 1):
		var angle = (TAU * i) / segments

		var outer_point = Vector2(
			cos(angle) * judgment_radius,
			sin(angle) * judgment_radius
		)
		points_outer.append(outer_point)

		var inner_point = Vector2(
			cos(angle) * inner_radius,
			sin(angle) * inner_radius
		)
		points_inner.append(inner_point)

	outer_ring.points = points_outer
	inner_ring.points = points_inner

func _setup_baskets():
	var basket_arc_points_left = []
	var basket_arc_points_right = []
	var segments = 16

	var left_start = deg_to_rad(270 - basket_width/2)
	var left_end = deg_to_rad(270 + basket_width/2)
	for i in range(segments + 1):
		var angle = lerp(left_start, left_end, float(i) / segments)
		var point = Vector2(
			cos(angle) * judgment_radius * 1.1,
			sin(angle) * judgment_radius * 1.1
		)
		basket_arc_points_left.append(point)

	var right_start = deg_to_rad(90 - basket_width/2)
	var right_end = deg_to_rad(90 + basket_width/2)
	for i in range(segments + 1):
		var angle = lerp(right_start, right_end, float(i) / segments)
		var point = Vector2(
			cos(angle) * judgment_radius * 1.1,
			sin(angle) * judgment_radius * 1.1
		)
		basket_arc_points_right.append(point)

	left_basket.points = basket_arc_points_left
	right_basket.points = basket_arc_points_right

func _process(_delta):
	queue_redraw()

func _on_rotation_changed(angle: float):
	rotation_indicator.rotation = deg_to_rad(angle)

func _on_basket_entered(basket: String):
	match basket:
		"left":
			left_basket.default_color = Color(1, 0.8, 0, 1)
			left_basket.width = 8.0
		"right":
			right_basket.default_color = Color(0, 0.8, 1, 1)
			right_basket.width = 8.0

func _on_basket_exited(basket: String):
	match basket:
		"left":
			left_basket.default_color = Color(1, 0.5, 0, 0.6)
			left_basket.width = 5.0
		"right":
			right_basket.default_color = Color(0, 0.5, 1, 0.6)
			right_basket.width = 5.0

func get_judgment_radius() -> float:
	return judgment_radius