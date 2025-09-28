extends Node2D

# This script creates a center mask that hides portions of track lines and notes
# while showing the background through

func create_mask(mask_width: float, mask_height: float):
	# Create the mask polygon
	var mask = Polygon2D.new()
	mask.name = "MaskPolygon"

	# Generate olive shape points
	var points = PackedVector2Array()
	var segments = 32

	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		var x = cos(angle) * mask_width
		var y = sin(angle) * mask_height
		points.append(Vector2(x, y))

	mask.polygon = points

	# Try to match the background appearance
	var gameplay_scene = get_tree().get_root().get_node_or_null("Gameplay3D")
	if gameplay_scene:
		var bg_layer = gameplay_scene.get_node_or_null("BackgroundLayer")
		if bg_layer:
			var blur_overlay = bg_layer.get_node_or_null("BlurOverlay")
			if blur_overlay and blur_overlay.visible:
				mask.color = blur_overlay.color
			else:
				mask.color = Color(0.05, 0.05, 0.08, 1.0)
	else:
		mask.color = Color(0.02, 0.02, 0.05, 1.0)

	add_child(mask)
	return mask
