extends Node2D

# Simple single-octave 2D Perlin noise visualizer.
# Generates an image matching the viewport size and draws it to the window.

@export var noise_scale: float = 0.015

var _noise_image: Image
var _noise_texture: ImageTexture


class Perlin2D:
	# Ken Perlin's base permutation table
	var _perm_base := [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
		190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
		88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,
		77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
		102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,
		135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,
		5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
		223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
		129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,
		251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,
		49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,
		138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180]

	var _p := []

	func _init():
		_p.resize(512)
		for i in 512:
			_p[i] = _perm_base[i % 256]

	func _fade(t: float) -> float:
		# Smoothstep-like easing used by Perlin
		return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

	func _grad(hashval: int, x: float, y: float) -> float:
		# Map hash to a unit vector angle in [0, 2π)
		var angle := (hashval & 255) * TAU / 256.0
		return x * cos(angle) + y * sin(angle)

	func _inc(v: int) -> int:
		return (v + 1) & 255

	func sample(x: float, y: float) -> float:
		# Lattice coordinates and fractional part
		var xi0 := int(floor(x))
		var yi0 := int(floor(y))
		var xf := x - xi0
		var yf := y - yi0

		var xi := xi0 & 255
		var yi := yi0 & 255

		var u := _fade(xf)
		var v := _fade(yf)

		# Hash to gradient indices at the 4 corners
		var a := _p[_p[xi] + yi]
		var b := _p[_p[xi] + _inc(yi)]
		var c := _p[_p[_inc(xi)] + yi]
		var d := _p[_p[_inc(xi)] + _inc(yi)]

		# Dot with offset vectors
		var g00 := _grad(a, xf, yf)
		var g01 := _grad(b, xf, yf - 1.0)
		var g10 := _grad(c, xf - 1.0, yf)
		var g11 := _grad(d, xf - 1.0, yf - 1.0)

		var x1 := lerp(g00, g01, u)
		var x2 := lerp(g10, g11, u)
		return lerp(x1, x2, v) # ~[-1, 1]


var _perlin := Perlin2D.new()


func _ready() -> void:
	_generate_and_upload(get_viewport_rect().size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_generate_and_upload(get_viewport_rect().size)


func _generate_and_upload(size: Vector2) -> void:
	var w := int(max(1.0, size.x))
	var h := int(max(1.0, size.y))

	_noise_image = Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var nx := float(x) * noise_scale
			var ny := float(y) * noise_scale
			var v := _perlin.sample(nx, ny)
			# Normalize from [-1, 1] to [0, 1]
			v = (v + 1.0) * 0.5
			_noise_image.set_pixel(x, y, Color(v, v, v, 1.0))

	_noise_texture = ImageTexture.create_from_image(_noise_image)
	queue_redraw()


func _draw() -> void:
	if _noise_texture:
		draw_texture_rect(_noise_texture, Rect2(Vector2.ZERO, get_viewport_rect().size), false)
