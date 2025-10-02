extends Node2D

var DEBUG_FONT_SIZE: int = 36
var DEBUG_ITEM_FONT_SIZE: int = 24

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
		# Scale tick length and font size based on zoom level
		var base_tick_length = 10.0
		var base_font_size = 12
		var tick_length = base_tick_length * (pixels_per_unit / 100.0)  # Scale with zoom
		var font_size = max(8, base_font_size * (pixels_per_unit / 100.0))  # Scale with zoom, min 8px
		var line_width = 1.0
		
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
				
				# Draw label (scale offset based on font size)
				var label_text = str(i)
				var label_offset = 15 + (font_size / 2)  # Scale offset with font size
				canvas.draw_string(
					ThemeDB.fallback_font,
					Vector2(x_pos - 5, graph_origin.y + label_offset),
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
				
				# Draw label (scale offset based on font size)
				var label_text = str(i)
				var label_offset = 5 + (font_size / 2)  # Scale offset with font size
				canvas.draw_string(
					ThemeDB.fallback_font,
					Vector2(graph_origin.x - (15 + font_size), y_pos + label_offset),
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
var octaves_label: Label
var octaves_controls: Label

# Sliders for noise parameters
var base_frequency_slider: HSlider
var base_frequency_label: Label
var lacunarity_slider: HSlider
var persistence_slider: HSlider
var lacunarity_label: Label
var persistence_label: Label

# Helper function to create labeled control rows
func create_control_row(text_content: String, control_text: String, text_color: Color = Color.WHITE, control_color: Color = Color.YELLOW, font_size: int = DEBUG_ITEM_FONT_SIZE) -> HBoxContainer:
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

func create_slider_row(label_text: String, min_val: float, max_val: float, step: float, default_val: float, font_size: int = DEBUG_ITEM_FONT_SIZE) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 15)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = default_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(slider)
	
	return container

func _ready():
	perlin_noise = PerlinNoise.new()
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
		DEBUG_ITEM_FONT_SIZE
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
		DEBUG_ITEM_FONT_SIZE
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
		DEBUG_ITEM_FONT_SIZE
	)
	debug_ui_container.add_child(fade_row)
	fade_label = fade_row.get_child(0)  # Reference to update later
	fade_controls = fade_row.get_child(1)


	#octaves row
	var octaves_row = create_control_row(
		"Octaves: " + str(perlin_noise.octaves),
		"[O]",
		Color.WHITE,
		Color.YELLOW,
		DEBUG_ITEM_FONT_SIZE
	)
	debug_ui_container.add_child(octaves_row)
	octaves_label = octaves_row.get_child(0)  # Reference to update later
	octaves_controls = octaves_row.get_child(1)

	# base frequency slider row
	var base_frequency_container = create_slider_row("Base Frequency: %.2f" % perlin_noise.base_frequency, 0.5, 2.0, 0.1, perlin_noise.base_frequency)
	debug_ui_container.add_child(base_frequency_container)
	base_frequency_label = base_frequency_container.get_child(0)
	base_frequency_slider = base_frequency_container.get_child(1)
	
	

	# Lacunarity slider row
	var lacunarity_container = create_slider_row("Lacunarity: %.2f" % perlin_noise.lacunarity, 0.5, 2.0, 0.1, perlin_noise.lacunarity)
	debug_ui_container.add_child(lacunarity_container)
	lacunarity_label = lacunarity_container.get_child(0)
	lacunarity_slider = lacunarity_container.get_child(1)

	# Persistence slider row
	var persistence_container = create_slider_row("Persistence: %.2f" % perlin_noise.persistence, 0.0, 1.0, 0.05, perlin_noise.persistence)
	debug_ui_container.add_child(persistence_container)
	persistence_label = persistence_container.get_child(0)
	persistence_slider = persistence_container.get_child(1)

	# Connect slider signals
	base_frequency_slider.value_changed.connect(_on_base_frequency_changed)
	lacunarity_slider.value_changed.connect(_on_lacunarity_changed)
	persistence_slider.value_changed.connect(_on_persistence_changed)


func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_M:
				# circular movement switch between fade types
				perlin_noise.fade_type = PerlinNoise.FadeType.values()[
					(PerlinNoise.FadeType.values().find(perlin_noise.fade_type) + 1) % PerlinNoise.FadeType.values().size()
				]
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
			KEY_O:
				#circular movement switch between octaves (1-4)
				perlin_noise.octaves += 1
				if perlin_noise.octaves > 4:
					perlin_noise.octaves = 1
				update_debug_ui()
				print('switched octaves to ' + str(perlin_noise.octaves))
			_:
				pass
		print("redrawing")
		queue_redraw()

func _on_base_frequency_changed(value: float):
	perlin_noise.base_frequency = value
	base_frequency_label.text = "Base Frequency: %.2f" % value
	queue_redraw()

func _on_lacunarity_changed(value: float):
	perlin_noise.lacunarity = value
	lacunarity_label.text = "Lacunarity: %.2f" % value
	queue_redraw()

func _on_persistence_changed(value: float):
	perlin_noise.persistence = value
	persistence_label.text = "Persistence: %.2f" % value
	queue_redraw()

func update_debug_ui():
	# Update zoom label and controls
	if zoom_label and zoom_controls:
		zoom_label.text = "Zoom ("+ str(graph.pixels_per_unit) + "px/graph unit): " + str(graph.pixels_per_unit / 100.0)

	if fade_label and fade_controls:
		fade_label.text = "Fade: " + PerlinNoise.FadeType.keys()[perlin_noise.fade_type]
	if octaves_label and octaves_controls:
		octaves_label.text = "Octaves: " + str(perlin_noise.octaves)

	if lacunarity_label and lacunarity_slider:
		lacunarity_label.text = "Lacunarity: %.2f" % perlin_noise.lacunarity
		lacunarity_slider.value = perlin_noise.lacunarity

	if persistence_label and persistence_slider:
		persistence_label.text = "Persistence: %.2f" % perlin_noise.persistence
		persistence_slider.value = perlin_noise.persistence

func _draw():
	# Draw the graph axes and ticks
	graph.draw_integer_noise_values(self)
	graph.draw_axes(self)
	graph.draw_ticks(self)
	graph.draw_noise_graph(self)
