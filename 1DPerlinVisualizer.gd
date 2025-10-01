extends Node2D

class Graph:
	var perlin: PerlinNoise
	var pixels_per_unit: float
	
	var screen_size: Vector2
	var graph_origin: Vector2
	
	func _init(pn: PerlinNoise, ppu: float, go: Vector2, viewport_size: Vector2):
		perlin = pn
		pixels_per_unit = ppu
		graph_origin = go
		screen_size = viewport_size
	
	func draw_integer_noise_values(canvas: CanvasItem):

		for i in range(screen_size.x / pixels_per_unit):
			var pos = Vector2(i*pixels_per_unit, screen_size.y/2)
			var graph_space_pos = _pixel_to_graph_space(pos)
			var noise_value = perlin.perlin1d(graph_space_pos.x)
			var pixel_space_pos = _graph_to_pixel_space(Vector2(graph_space_pos.x, noise_value))
			#draw a red blue dot with y equal to noise value 
			canvas.draw_circle(pixel_space_pos, 4, Color.BLUE)
		
		
	func draw_axes(canvas: CanvasItem):
		var axis_color = Color.WHITE
		var line_width = 2.0
		
		# Draw X-axis (horizontal line through center_y)
		canvas.draw_line(
			Vector2(0, graph_origin.y), 
			Vector2(screen_size.x, graph_origin.y), 
			axis_color, 
			line_width
		)
		
		# Draw Y-axis (vertical line at center_x)
		canvas.draw_line(
			Vector2(graph_origin.x, 0), 
			Vector2(graph_origin.x, screen_size.y), 
			axis_color, 
			line_width
		)
	
	func draw_ticks(canvas: CanvasItem):
		var tick_color = Color.WHITE
		var tick_length = 10.0
		var line_width = 1.0
		var font_size = 12
		
		# Calculate how many units fit on screen
		var units_left = int(graph_origin.x / pixels_per_unit)
		var units_right = int((screen_size.x - graph_origin.x) / pixels_per_unit)
		var units_up = int(graph_origin.y / pixels_per_unit)
		var units_down = int((screen_size.y - graph_origin.y) / pixels_per_unit)
		
		# Draw X-axis ticks and labels
		for i in range(-units_left, units_right + 1):
			if i == 0:
				continue  # Skip the origin tick
			
			var x_pos = graph_origin.x + i * pixels_per_unit
			if x_pos >= 0 and x_pos <= screen_size.x:
				# Draw tick mark
				canvas.draw_line(
					Vector2(x_pos, graph_origin.y - tick_length/2), 
					Vector2(x_pos, graph_origin.y + tick_length/2), 
					tick_color, 
					line_width
				)
				
				# Draw label
				var label_text = str(i)
				canvas.draw_string(
					ThemeDB.fallback_font,
					Vector2(x_pos - 5, graph_origin.y + 25),
					label_text,
					HORIZONTAL_ALIGNMENT_CENTER,
					-1,
					font_size,
					tick_color
				)
		
		# Draw Y-axis ticks and labels
		for i in range(-units_down, units_up + 1):
			if i == 0:
				continue  # Skip the origin tick
			
			var y_pos = graph_origin.y - i * pixels_per_unit  # Negative because Y increases downward
			if y_pos >= 0 and y_pos <= screen_size.y:
				# Draw tick mark
				canvas.draw_line(
					Vector2(graph_origin.x - tick_length/2, y_pos), 
					Vector2(graph_origin.x + tick_length/2, y_pos), 
					tick_color, 
					line_width
				)
				
				# Draw label
				var label_text = str(i)
				canvas.draw_string(
					ThemeDB.fallback_font,
					Vector2(graph_origin.x - 25, y_pos + 5),
					label_text,
					HORIZONTAL_ALIGNMENT_CENTER,
					-1,
					font_size,
					tick_color
				)
	
	func draw_noise_graph(canvas: CanvasItem):
		var line_color = Color.RED
		var line_width = 2.0
		var step_size = 2  # Sample every 2 pixels for smoother lines
		
		var points = PackedVector2Array()
		
		# Generate points for the noise graph
		for i in range(0, int(screen_size.x), step_size):
			var pos = Vector2(i, screen_size.y/2)
			var graph_space_pos = _pixel_to_graph_space(pos)
			var noise_value = perlin.perlin1d(graph_space_pos.x)
			var pixel_space_pos = _graph_to_pixel_space(Vector2(graph_space_pos.x, noise_value))
			points.append(pixel_space_pos)
		
		# Draw lines connecting the points
		for i in range(points.size() - 1):
			canvas.draw_line(points[i], points[i + 1], line_color, line_width)

	func _pixel_to_graph_space(point: Vector2) -> Vector2:
		# subtraction AND an sign flip of the y value
		var result = (point - graph_origin)
		result.y = -result.y
		return result / pixels_per_unit
	
	func _graph_to_pixel_space(point: Vector2) -> Vector2:
		var result = point * pixels_per_unit
		result.y = -result.y
		result += graph_origin
		return result

	func update_zoom(new_zoom: float):
		self.pixels_per_unit = new_zoom


var perlin_noise: PerlinNoise
var graph: Graph

var debug_ui_container: VBoxContainer
var regenerate_label: Label
var regenerate_controls: Label
var zoom_label: Label
var zoom_controls: Label
var fade_label: Label
var fade_controls: Label

# Helper function to create labeled control rows
func create_control_row(text_content: String, control_text: String, text_color: Color = Color.WHITE, control_color: Color = Color.YELLOW, font_size: int = 24) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)

	var text_label = Label.new()
	text_label.text = text_content
	text_label.add_theme_font_size_override("font_size", font_size)
	text_label.add_theme_color_override("font_color", text_color)
	container.add_child(text_label)

	var control_label = Label.new()
	control_label.text = control_text
	control_label.add_theme_font_size_override("font_size", font_size)
	control_label.add_theme_color_override("font_color", control_color)
	container.add_child(control_label)

	return container

func _ready():
	perlin_noise = PerlinNoise.new(PerlinNoise.FadeType.SMOOTHSTEP)
	graph = Graph.new(perlin_noise, 100.0, Vector2(100, get_viewport().size.y/2), get_viewport().size)  # 100 pixels = 1 unit
	
	
	
	#UI RELATED SETUP
	#debug ui for Fadetype, n, and zoom
	debug_ui_container = VBoxContainer.new()
	debug_ui_container.position = Vector2(150.0, 25.0)
	add_child(debug_ui_container)

	# Header
	var header = Label.new()
	header.text = "[DEBUG]"
	header.add_theme_font_size_override("font_size", 36)
	header.add_theme_color_override("font_color", Color.LIME_GREEN)
	debug_ui_container.add_child(header)

	# Regenerate row
	var regenerate_row = create_control_row(
		"Regenerate noise ",
		"[R]",
		Color.WHITE,
		Color.YELLOW,
		24
	)
	debug_ui_container.add_child(regenerate_row)
	regenerate_label = regenerate_row.get_child(0)  # Reference to update later
	regenerate_controls = regenerate_row.get_child(1)
	# Zoom row
	var zoom_row = create_control_row(
		"Zoom: (" + str(graph.pixels_per_unit) + "px/graph unit): " + str(graph.pixels_per_unit / 100.0),
		"[+, -]",
		Color.WHITE,
		Color.YELLOW,
		24
	)
	debug_ui_container.add_child(zoom_row)
	zoom_label = zoom_row.get_child(0)  # Reference to update later
	zoom_controls = zoom_row.get_child(1)

	# Fade row
	var fade_row = create_control_row(
		"Fade function: " + PerlinNoise.FadeType.keys()[perlin_noise.fade_type],
		"[M]",
		Color.WHITE,
		Color.YELLOW,
		24
	)
	debug_ui_container.add_child(fade_row)
	fade_label = fade_row.get_child(0)  # Reference to update later
	fade_controls = fade_row.get_child(1)


func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_M:
				# Switch interpolation mode
				if perlin_noise.fade_type == PerlinNoise.FadeType.LERP:
					perlin_noise.fade_type = PerlinNoise.FadeType.SMOOTHSTEP
				else:
					perlin_noise.fade_type = PerlinNoise.FadeType.LERP
				update_debug_ui()
				print('switched fade type to ' + str(PerlinNoise.FadeType.keys()[perlin_noise.fade_type]))
			KEY_EQUAL:
				graph.pixels_per_unit = min(graph.pixels_per_unit + 50, 500)
				update_debug_ui()
				print('zoomed in to ' + str(graph.pixels_per_unit) + 'px/graph unit')
			KEY_MINUS:
				if graph.pixels_per_unit >= 150:
					graph.pixels_per_unit = max(graph.pixels_per_unit - 50, 10)
				else:
					graph.pixels_per_unit = max(graph.pixels_per_unit - 10, 10)
				update_debug_ui()
				print('zoomed out to ' + str(graph.pixels_per_unit) + 'px/graph unit')
			KEY_R:
				perlin_noise.shuffle_p()
			_:
				pass
		print("redrawing")
		queue_redraw()

func update_debug_ui():
	# Update zoom label and controls
	if zoom_label and zoom_controls:
		zoom_label.text = "Zoom ("+ str(graph.pixels_per_unit) + "px/graph unit): " + str(graph.pixels_per_unit / 100.0)

	if fade_label and fade_controls:
		fade_label.text = "Fade: " + PerlinNoise.FadeType.keys()[perlin_noise.fade_type]

func _draw():
	# Draw the graph axes and ticks
	graph.draw_integer_noise_values(self)
	graph.draw_axes(self)
	graph.draw_ticks(self)
	graph.draw_noise_graph(self)
