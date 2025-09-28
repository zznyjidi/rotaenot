extends Node2D

# Background effects for the diamond menu
# Creates explosive particle effects, wave pulses, and interactive shapes

# Shape pool for performance
var shape_pool = []
var active_shapes = []
var max_shapes = 50

# Wave effects
var wave_pool = []
var active_waves = []
var max_waves = 5

# Audio analysis
var audio_bus_index: int = 0
var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var beat_threshold: float = 0.3
var last_beat_time: float = 0.0
var beat_cooldown: float = 0.15

# Visual properties - Futuristic monochromatic theme
var primary_color = Color(0.4, 0.8, 1.0, 0.4)  # Cyan with lower opacity
var secondary_color = Color(0.3, 0.6, 0.8, 0.3)  # Darker cyan
var accent_color = Color(0.5, 0.9, 1.0, 0.35)  # Lighter cyan

# Animation states
var is_exploding: bool = false
var is_returning: bool = false
var shapes_stopped: bool = false

# Center position
var center_pos: Vector2 = Vector2(640, 360)

# Shape types - Using only geometric shapes for futuristic feel
enum ShapeType { TRIANGLE, SQUARE, HEXAGON }

class Shape:
	var sprite: Sprite2D
	var velocity: Vector2
	var rotation_speed: float
	var type: int
	var color: Color
	var size: float
	var target_pos: Vector2
	var original_velocity: Vector2
	var pulse_scale: float = 1.0

	func _init():
		sprite = Sprite2D.new()
		velocity = Vector2.ZERO
		rotation_speed = 0.0
		type = 0
		size = 1.0
		pulse_scale = 1.0

class Wave:
	var ring: Line2D
	var radius: float
	var max_radius: float
	var alpha: float
	var speed: float
	var color: Color

	func _init():
		ring = Line2D.new()
		radius = 0.0
		max_radius = 800.0
		alpha = 1.0
		speed = 300.0

# Continuous wave timer
var wave_timer: float = 0.0
var wave_interval: float = 1.5  # Wave every 1.5 seconds

func _ready():
	# Set up audio analyzer
	_setup_audio_analyzer()

	# Initialize pools
	_initialize_shape_pool()
	_initialize_wave_pool()

	# Start with explosion effect after small delay
	await get_tree().create_timer(0.2).timeout
	trigger_explosion()

func _setup_audio_analyzer():
	# Get the audio bus
	audio_bus_index = AudioServer.get_bus_index("Master")

	# Add spectrum analyzer effect if not present
	var effect_count = AudioServer.get_bus_effect_count(audio_bus_index)
	var analyzer_found = false

	for i in range(effect_count):
		var effect = AudioServer.get_bus_effect(audio_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_analyzer = AudioServer.get_bus_effect_instance(audio_bus_index, i)
			analyzer_found = true
			break

	if not analyzer_found:
		var spectrum_effect = AudioEffectSpectrumAnalyzer.new()
		spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
		AudioServer.add_bus_effect(audio_bus_index, spectrum_effect)
		spectrum_analyzer = AudioServer.get_bus_effect_instance(audio_bus_index, AudioServer.get_bus_effect_count(audio_bus_index) - 1)

func _initialize_shape_pool():
	for i in range(max_shapes):
		var shape = Shape.new()
		shape.sprite.visible = false
		shape.sprite.z_index = 1  # Behind UI elements
		add_child(shape.sprite)
		shape_pool.append(shape)

		# Create texture for shape
		_create_shape_texture(shape)

func _create_shape_texture(shape: Shape):
	shape.type = randi() % 3  # Random shape type (only 3 types now)
	var texture_size = 32
	var image = Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)

	# Clear image
	for x in range(texture_size):
		for y in range(texture_size):
			image.set_pixel(x, y, Color(0, 0, 0, 0))

	var center = Vector2(texture_size / 2.0, texture_size / 2.0)
	var shape_color = [primary_color, secondary_color, accent_color][randi() % 3]
	shape.color = shape_color

	match shape.type:
		ShapeType.TRIANGLE:
			_draw_triangle(image, center, texture_size * 0.4, shape_color)
		ShapeType.SQUARE:
			_draw_square(image, center, texture_size * 0.35, shape_color)
		ShapeType.HEXAGON:
			_draw_hexagon(image, center, texture_size * 0.4, shape_color)

	var texture = ImageTexture.create_from_image(image)
	shape.sprite.texture = texture

func _draw_triangle(image: Image, center: Vector2, size: float, color: Color):
	var points = []
	for i in range(3):
		var angle = (i * 120 - 90) * PI / 180
		points.append(center + Vector2(cos(angle), sin(angle)) * size)

	# Simple filled triangle
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			if _point_in_triangle(Vector2(x, y), points[0], points[1], points[2]):
				image.set_pixel(x, y, color)

func _draw_square(image: Image, center: Vector2, size: float, color: Color):
	var half_size = size
	for x in range(int(center.x - half_size), int(center.x + half_size)):
		for y in range(int(center.y - half_size), int(center.y + half_size)):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

func _draw_hexagon(image: Image, center: Vector2, size: float, color: Color):
	var points = []
	for i in range(6):
		var angle = (i * 60) * PI / 180
		points.append(center + Vector2(cos(angle), sin(angle)) * size)

	# Simple filled hexagon
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			if _point_in_polygon(Vector2(x, y), points):
				image.set_pixel(x, y, color)

func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var sign_func = func(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
		return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)

	var d1 = sign_func.call(p, a, b)
	var d2 = sign_func.call(p, b, c)
	var d3 = sign_func.call(p, c, a)

	var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
	var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

	return not (has_neg and has_pos)

func _point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside = false
	var p1 = polygon[0]

	for i in range(1, polygon.size() + 1):
		var p2 = polygon[i % polygon.size()]

		if point.y > min(p1.y, p2.y):
			if point.y <= max(p1.y, p2.y):
				if point.x <= max(p1.x, p2.x):
					var xinters: float = 0.0
					if p1.y != p2.y:
						xinters = (point.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y) + p1.x
					if p1.x == p2.x or point.x <= xinters:
						inside = not inside

		p1 = p2

	return inside

func _initialize_wave_pool():
	for i in range(max_waves):
		var wave = Wave.new()
		wave.ring.visible = false
		wave.ring.width = 3.0
		wave.ring.default_color = primary_color
		wave.ring.z_index = 0  # Behind shapes
		wave.ring.closed = true

		# Create circle points
		var points = []
		for j in range(64):
			var angle = (j / 64.0) * TAU
			points.append(Vector2(cos(angle), sin(angle)))

		for point in points:
			wave.ring.add_point(point)

		add_child(wave.ring)
		wave_pool.append(wave)

func trigger_explosion():
	if is_exploding:
		return

	is_exploding = true
	is_returning = false
	shapes_stopped = false

	# Activate all shapes with explosion velocities
	for i in range(max_shapes):
		var shape = shape_pool[i]
		shape.sprite.visible = true
		shape.sprite.position = center_pos
		shape.sprite.scale = Vector2.ONE * randf_range(0.8, 1.5)
		shape.size = shape.sprite.scale.x

		# Random explosion direction and speed
		var angle = randf() * TAU
		var speed = randf_range(200, 500)
		shape.velocity = Vector2(cos(angle), sin(angle)) * speed
		shape.original_velocity = shape.velocity
		shape.rotation_speed = randf_range(-5, 5)

		# Random target position for stopping
		var stop_distance = randf_range(150, 400)
		shape.target_pos = center_pos + shape.velocity.normalized() * stop_distance

		active_shapes.append(shape)

	# Create initial explosion wave
	_create_wave(primary_color * 1.5, 500.0)

	# Slow down shapes over time
	var tween = create_tween()
	tween.tween_property(self, "is_exploding", false, 1.5)
	tween.tween_callback(_stop_shapes)

func _stop_shapes():
	shapes_stopped = true

	# Gradually slow shapes to their target positions
	for shape in active_shapes:
		var tween = create_tween()
		tween.tween_property(shape.sprite, "position", shape.target_pos, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func trigger_return(menu_closing: bool = false):
	if is_returning:
		return

	# Only return shapes if we're actually closing the menu
	if not menu_closing:
		return

	is_returning = true
	shapes_stopped = false

	# Return all shapes to center
	for shape in active_shapes:
		var tween = create_tween()
		tween.tween_property(shape.sprite, "position", center_pos, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(shape.sprite, "scale", Vector2.ZERO, 0.6).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(shape.sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): shape.sprite.visible = false)

	# Create implosion wave
	_create_wave(secondary_color * 1.5, 300.0)

	# Clear active shapes after animation
	await get_tree().create_timer(0.7).timeout
	active_shapes.clear()
	is_returning = false

func _create_wave(color: Color, speed: float = 300.0):
	for wave in wave_pool:
		if not wave.ring.visible:
			wave.ring.visible = true
			wave.ring.position = center_pos
			wave.radius = 0.0
			wave.alpha = 0.8
			wave.speed = speed
			wave.ring.default_color = color
			wave.ring.modulate.a = wave.alpha
			active_waves.append(wave)
			break

func _process(delta):
	# Update shapes
	if not shapes_stopped and not is_returning:
		for shape in active_shapes:
			if is_exploding:
				# Apply velocity
				shape.sprite.position += shape.velocity * delta
				shape.velocity *= 0.96  # Gradual slowdown

			# Rotate shape
			shape.sprite.rotation += shape.rotation_speed * delta

			# Pulse with beat
			shape.sprite.scale = Vector2.ONE * shape.size * shape.pulse_scale

	# Update waves
	var waves_to_remove = []
	for wave in active_waves:
		wave.radius += wave.speed * delta
		wave.alpha -= delta * 0.5
		wave.ring.modulate.a = wave.alpha

		# Update ring scale
		wave.ring.scale = Vector2.ONE * (wave.radius / 100.0)

		if wave.alpha <= 0 or wave.radius > wave.max_radius:
			wave.ring.visible = false
			waves_to_remove.append(wave)

	for wave in waves_to_remove:
		active_waves.erase(wave)

	# Continuous wave generation
	wave_timer += delta
	if wave_timer >= wave_interval:
		wave_timer = 0.0
		# Create a subtle continuous wave
		var wave_color = primary_color * 0.5
		_create_wave(wave_color, randf_range(200, 250))

	# Beat detection
	_detect_beat(delta)

func _detect_beat(_delta):
	if not spectrum_analyzer:
		return

	# Get low frequency magnitude for beat detection
	var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(20, 200).length()

	var current_time = Time.get_ticks_msec() / 1000.0
	if magnitude > beat_threshold and current_time - last_beat_time > beat_cooldown:
		last_beat_time = current_time
		_on_beat_detected()

func _on_beat_detected():
	# Create wave on beat
	if randf() > 0.3:  # 70% chance to create wave on beat
		var wave_color = [primary_color, secondary_color, accent_color][randi() % 3]
		_create_wave(wave_color * 0.8, randf_range(250, 400))

	# Pulse shapes on beat
	for shape in active_shapes:
		var tween = create_tween()
		tween.tween_property(shape, "pulse_scale", 1.3, 0.05)
		tween.tween_property(shape, "pulse_scale", 1.0, 0.15).set_trans(Tween.TRANS_ELASTIC)

		# Slight position bounce if stopped
		if shapes_stopped:
			var bounce_dir = (shape.sprite.position - center_pos).normalized()
			var bounce_pos = shape.sprite.position + bounce_dir * 10
			tween.set_parallel(true)
			tween.tween_property(shape.sprite, "position", bounce_pos, 0.05)
			tween.tween_property(shape.sprite, "position", shape.target_pos, 0.15).set_trans(Tween.TRANS_BACK)

# Public interface for menu to call
func on_menu_opened():
	trigger_explosion()

func on_diamond_clicked(_menu_closing: bool = false):
	# Don't trigger return unless menu is actually closing
	# (not just toggling open/closed)
	pass
