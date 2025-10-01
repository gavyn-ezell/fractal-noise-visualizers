extends Node2D

enum InterpolationType {
	LERP,
	SMOOTHSTEP
}


class PerlinNoise2D:
	# Ken Perlin's base permutation table
	# taken from https://mrl.cs.nyu.edu/~perlin/noise/
	var permutation = [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
		190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
		88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
		77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
		102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
		135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
		5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
		223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
		129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
		251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
		49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
		138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180]
	
	var interpolation_type: InterpolationType
	var p
	var n
	
	func _init(i:InterpolationType=InterpolationType.SMOOTHSTEP, in_n: int = 256):
		interpolation_type = i
		p = []
		for idx in range(512):
			p.append(permutation[idx % 256])
		n = in_n
	
	func _fade(t: float) -> float:
		match interpolation_type:
			InterpolationType.LERP:
				return t
			InterpolationType.SMOOTHSTEP:
				return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
			_:
				return t

	func _inc(to_inc: int):
		to_inc += 1
		return to_inc & 255
	
	# Random unit-circle gradient (angle from hash)
	func _gradient(hashval: int, x: float, y: float) -> float:
		var angle = (hashval & 255) * TAU / 256.0
		return x * cos(angle) + y * sin(angle)
	
	func perlin(x: float, y: float):
		# Integer lattice coordinates and fractional parts
		var xi0 = int(floor(x))
		var yi0 = int(floor(y))
		var xf = x - xi0
		var yf = y - yi0
		
		# Wrap to [0,255] for permutation indexing
		var xi = xi0 & 255
		var yi = yi0 & 255
		
		var u = _fade(xf)
		var v = _fade(yf)

		# Hash corners
		var a = p[p[xi] + yi]
		var b = p[p[xi] + _inc(yi)]
		var c = p[p[_inc(xi)] + yi]
		var d = p[p[_inc(xi)] + _inc(yi)]

		# Gradient dot products from each corner
		var g1 = _gradient(a, xf, yf)
		var g2 = _gradient(b, xf, yf - 1.0)
		var g3 = _gradient(c, xf - 1.0, yf)
		var g4 = _gradient(d, xf - 1.0, yf - 1.0)

		var x1 = lerp(g1, g2, u)
		var x2 = lerp(g3, g4, u)

		return lerp(x1, x2, v)





var perlin_noise_2d: PerlinNoise2D
var perlin_image: Image

func _ready():
	perlin_noise_2d = PerlinNoise2D.new(InterpolationType.SMOOTHSTEP, 255)
	perlin_image = Image.create(512, 512, false, Image.FORMAT_RGB8)
	for i in range(512):
		for j in range(512):
				var noise_value = perlin_noise_2d.perlin(i*0.0625, j*0.0625)
				var v = clamp(noise_value, -1.0, 1.0)
				#normalize to 0 to 1 range
				v = (v + 1.0) / 2.0

				perlin_image.set_pixel(i, j, Color(v, v, v))
	perlin_image.save_png("res://noise.png")
