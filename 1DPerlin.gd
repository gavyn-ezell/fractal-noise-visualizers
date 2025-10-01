extends Node2D

enum InterpolationType {
	LERP,
	SMOOTHSTEP
}

class PerlinNoise:
	var perlin_seed: int
	var interpolation_type: InterpolationType
	var octaves: int
	var persistence: float
	
	func _init(s:int=randi(), i:InterpolationType=InterpolationType.LERP, in_o: int=1, in_p=1.0):
		perlin_seed = s
		interpolation_type = i
		octaves = in_o
		persistence = in_p
	
	func random_hash(x: int) -> int:
		# Convert input to unsigned 32-bit integer
		var h = (x ^ perlin_seed) & 0xFFFFFFFF
		
		# Wang hash - simple and effective for Perlin noise
		h = (h ^ 61) ^ (h >> 16)
		h = h + (h << 3)
		h = h ^ (h >> 4)
		h = h * 0x27d4eb2d
		h = h ^ (h >> 15)
		
		# Ensure result is positive and within 32-bit unsigned range
		return h & 0xFFFFFFFF
	
	
	func perlin(x: float):
		var result = 0
		for i in range(octaves):
			result += pow(persistence, i) * noise(pow(2, i) * x)
		
		return result
	
	#this noise function returns some noise value between 0 and 1
	func noise(x: float) -> float:
		match interpolation_type:
			InterpolationType.LERP:
				return _lerp(x)
			InterpolationType.SMOOTHSTEP:
				return _smoothstep(x)
			_:
				return _lerp(x)
	
	func _lerp(x: float) -> float:
		var floor_x = floor(x)
		var frac_x = x - floor_x
		#get our hash values normalized to -1 to 1 range
		var floor_hash = (random_hash(floor_x) / 4294967295.0) * 2.0 - 1.0
		var ceil_hash = (random_hash(floor_x + 1) / 4294967295.0) * 2.0 - 1.0
		return floor_hash + frac_x * (ceil_hash - floor_hash)
	
	func _smoothstep(x: float) -> float:
		var floor_x = floor(x)
		var frac_x = x - floor_x
		#get our hash values normalized to -1 to 1 range
		var floor_hash = (random_hash(floor_x) / 4294967295.0) * 2.0 - 1.0
		var ceil_hash = (random_hash(floor_x + 1) / 4294967295.0) * 2.0 - 1.0
		var t = clamp(frac_x, 0.0, 1.0)
		return floor_hash + t * t * (3.0 - 2.0 * t) * (ceil_hash - floor_hash)
	
	func regenerate_seed():
		perlin_seed = randi()
	
	func set_persistence(new_persistence: float):
		persistence = clamp(new_persistence, 0.0, 1.0)
	
	func set_octaves(new_octaves: int):
		octaves = clamp(new_octaves, 1, 8)


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
			var noise_value = perlin.perlin(graph_space_pos.x)
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
var zoom_slider: HSlider
var persistence_slider: HSlider
var octaves_slider: HSlider

# Debug UI elements
var debug_panel: HBoxContainer
var perlin_section: VBoxContainer
var graph_section: VBoxContainer
var debug_labels: Dictionary = {}

# Control hints UI
var controls_panel: HBoxContainer

func _ready():
	perlin_noise = PerlinNoise.new(38082, InterpolationType.SMOOTHSTEP, 4, 0.5)
	graph = Graph.new(perlin_noise, 100.0, Vector2(100, get_viewport().size.y/2), get_viewport().size)  # 100 pixels = 1 unit
	
	# Create sliders in bottom right quadrant
	create_bottom_right_sliders()
	
	# Create debug UI
	create_debug_ui()
	update_debug_ui()
	
	# Create control hints UI
	create_controls_ui()

func create_bottom_right_sliders():
	var viewport_size = get_viewport().size
	
	# Calculate bottom right quadrant position
	var start_x = viewport_size.x - 280  # 280px from right edge
	var start_y = viewport_size.y - 170  # 170px from bottom (moved up 20px)
	
	# Create container for better organization
	var slider_container = VBoxContainer.new()
	slider_container.position = Vector2(start_x, start_y)
	slider_container.size = Vector2(260, 130)
	
	# Title for the slider section
	var title_label = Label.new()
	title_label.text = "CONTROLS"
	title_label.modulate = Color.YELLOW
	title_label.add_theme_font_size_override("font_size", 12)
	slider_container.add_child(title_label)
	
	# Zoom slider
	var zoom_container = VBoxContainer.new()
	var zoom_label = Label.new()
	zoom_label.text = "Zoom"
	zoom_label.modulate = Color.WHITE
	zoom_container.add_child(zoom_label)
	
	zoom_slider = HSlider.new()
	zoom_slider.min_value = 0.5
	zoom_slider.max_value = 5.0
	zoom_slider.step = 0.1
	zoom_slider.value = 1.0
	zoom_slider.size = Vector2(200, 20)
	zoom_container.add_child(zoom_slider)
	slider_container.add_child(zoom_container)
	
	# Persistence slider
	var persistence_container = VBoxContainer.new()
	var persistence_label = Label.new()
	persistence_label.text = "Persistence"
	persistence_label.modulate = Color.WHITE
	persistence_container.add_child(persistence_label)
	
	persistence_slider = HSlider.new()
	persistence_slider.min_value = 0.0
	persistence_slider.max_value = 1.0
	persistence_slider.step = 0.01
	persistence_slider.value = 0.5
	persistence_slider.size = Vector2(200, 20)
	persistence_container.add_child(persistence_slider)
	slider_container.add_child(persistence_container)
	
	# Octaves slider
	var octaves_container = VBoxContainer.new()
	var octaves_label = Label.new()
	octaves_label.text = "Octaves"
	octaves_label.modulate = Color.WHITE
	octaves_container.add_child(octaves_label)
	
	octaves_slider = HSlider.new()
	octaves_slider.min_value = 1
	octaves_slider.max_value = 8
	octaves_slider.step = 1
	octaves_slider.value = 4
	octaves_slider.size = Vector2(200, 20)
	octaves_container.add_child(octaves_slider)
	slider_container.add_child(octaves_container)
	
	# Connect slider signals
	zoom_slider.value_changed.connect(_on_zoom_changed)
	persistence_slider.value_changed.connect(_on_persistence_changed)
	octaves_slider.value_changed.connect(_on_octaves_changed)
	
	# Add to scene
	add_child(slider_container)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				# Regenerate seed and redraw
				perlin_noise.regenerate_seed()
				update_debug_ui()
				queue_redraw()
			KEY_M:
				# Switch interpolation mode
				if perlin_noise.interpolation_type == InterpolationType.LERP:
					perlin_noise.interpolation_type = InterpolationType.SMOOTHSTEP
				else:
					perlin_noise.interpolation_type = InterpolationType.LERP
				update_debug_ui()
				queue_redraw()

func _draw():
	# Draw the graph axes and ticks
	graph.draw_axes(self)
	graph.draw_ticks(self)
	graph.draw_noise_graph(self)

func create_debug_ui():
	# Create main debug panel (horizontal layout)
	debug_panel = HBoxContainer.new()
	debug_panel.position = Vector2(get_viewport().size.x - 400, 20)
	debug_panel.size = Vector2(380, 200)
	debug_panel.modulate = Color.WHITE
	
	# Perlin Noise section (left side)
	var perlin_container = VBoxContainer.new()
	perlin_container.size = Vector2(180, 200)
	
	var perlin_title = Label.new()
	perlin_title.text = "=== PERLIN NOISE ==="
	perlin_title.modulate = Color.YELLOW
	perlin_container.add_child(perlin_title)
	
	perlin_section = VBoxContainer.new()
	perlin_container.add_child(perlin_section)
	
	# Create Perlin parameter labels
	debug_labels["perlin_seed"] = Label.new()
	debug_labels["perlin_interpolation"] = Label.new()
	debug_labels["perlin_octaves"] = Label.new()
	debug_labels["perlin_persistence"] = Label.new()
	
	perlin_section.add_child(debug_labels["perlin_seed"])
	perlin_section.add_child(debug_labels["perlin_interpolation"])
	perlin_section.add_child(debug_labels["perlin_octaves"])
	perlin_section.add_child(debug_labels["perlin_persistence"])
	
	debug_panel.add_child(perlin_container)
	
	# Graph section (right side)
	var graph_container = VBoxContainer.new()
	graph_container.size = Vector2(180, 200)
	
	var graph_title = Label.new()
	graph_title.text = "=== GRAPH ==="
	graph_title.modulate = Color.CYAN
	graph_container.add_child(graph_title)
	
	graph_section = VBoxContainer.new()
	graph_container.add_child(graph_section)
	
	# Create Graph parameter labels
	debug_labels["graph_zoom"] = Label.new()
	debug_labels["graph_origin_x"] = Label.new()
	debug_labels["graph_origin_y"] = Label.new()
	debug_labels["graph_screen_size"] = Label.new()
	debug_labels["slider_value"] = Label.new()
	
	graph_section.add_child(debug_labels["graph_zoom"])
	graph_section.add_child(debug_labels["graph_origin_x"])
	graph_section.add_child(debug_labels["graph_origin_y"])
	graph_section.add_child(debug_labels["graph_screen_size"])
	graph_section.add_child(debug_labels["slider_value"])
	
	debug_panel.add_child(graph_container)
	
	# Add debug panel to scene
	add_child(debug_panel)

func create_controls_ui():
	# Create control hints panel at bottom of screen
	controls_panel = HBoxContainer.new()
	controls_panel.position = Vector2(20, get_viewport().size.y - 60)
	controls_panel.size = Vector2(get_viewport().size.x - 40, 40)
	controls_panel.modulate = Color.WHITE
	
	# Create title label
	var title_label = Label.new()
	title_label.text = "CONTROLS: "
	title_label.modulate = Color.YELLOW
	title_label.add_theme_font_size_override("font_size", 14)
	controls_panel.add_child(title_label)
	
	# Add some spacing
	var spacer1 = Control.new()
	spacer1.size = Vector2(20, 1)
	controls_panel.add_child(spacer1)
	
	# Create S key hint
	var s_label = Label.new()
	s_label.text = "[S] Regenerate Seed"
	s_label.modulate = Color.CYAN
	s_label.add_theme_font_size_override("font_size", 12)
	controls_panel.add_child(s_label)
	
	# Add spacing
	var spacer2 = Control.new()
	spacer2.size = Vector2(30, 1)
	controls_panel.add_child(spacer2)
	
	# Create M key hint
	var m_label = Label.new()
	m_label.text = "[M] Switch Interpolation Mode"
	m_label.modulate = Color.CYAN
	m_label.add_theme_font_size_override("font_size", 12)
	controls_panel.add_child(m_label)
	
	# Add spacing
	var spacer3 = Control.new()
	spacer3.size = Vector2(30, 1)
	controls_panel.add_child(spacer3)
	
	# Create slider hints
	var sliders_label = Label.new()
	sliders_label.text = "Sliders: Bottom Right Corner"
	sliders_label.modulate = Color.LIGHT_GRAY
	sliders_label.add_theme_font_size_override("font_size", 12)
	controls_panel.add_child(sliders_label)
	
	# Add controls panel to scene
	add_child(controls_panel)

func update_debug_ui():
	# Update Perlin Noise parameters
	debug_labels["perlin_seed"].text = "Seed: " + str(perlin_noise.perlin_seed)
	
	var interp_name = "LERP" if perlin_noise.interpolation_type == InterpolationType.LERP else "SMOOTHSTEP"
	debug_labels["perlin_interpolation"].text = "Interpolation: " + interp_name
	debug_labels["perlin_octaves"].text = "Octaves: " + str(perlin_noise.octaves)
	debug_labels["perlin_persistence"].text = "Persistence: " + str("%.2f" % perlin_noise.persistence)
	
	# Update Graph parameters
	debug_labels["graph_zoom"].text = "Zoom: " + str(graph.pixels_per_unit) + " px/unit"
	debug_labels["graph_origin_x"].text = "Origin X: " + str(graph.graph_origin.x)
	debug_labels["graph_origin_y"].text = "Origin Y: " + str(int(graph.graph_origin.y))
	debug_labels["graph_screen_size"].text = "Screen: " + str(int(graph.screen_size.x)) + "x" + str(int(graph.screen_size.y))
	debug_labels["slider_value"].text = "Zoom: " + str(zoom_slider.value)

func _on_zoom_changed(value: float):
	# Update graph zoom (convert slider value to pixels per unit)
	var pixels_per_unit = value * 100.0  # Base 100 pixels = 1 unit
	graph.update_zoom(pixels_per_unit)
	update_debug_ui()  # Update debug display
	queue_redraw()  # Trigger a redraw

func _on_persistence_changed(value: float):
	# Update persistence value
	perlin_noise.set_persistence(value)
	update_debug_ui()  # Update debug display
	queue_redraw()  # Trigger a redraw

func _on_octaves_changed(value: float):
	# Update octaves value (convert float to int)
	perlin_noise.set_octaves(int(value))
	update_debug_ui()  # Update debug display
	queue_redraw()  # Trigger a redraw
	
