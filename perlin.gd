extends Node
class_name PerlinNoise

enum FadeType {
	LERP,
	SMOOTHSTEP,
	SMOOTHERSTEP,
	EASEINOUTEXPO,
	EASEINOUTCIRC,
}

var base_permutation = [ 151,160,137,91,90,15,
   131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
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
   138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
   ];

var p: Array[int] 
var lacunarity: int = 2 #fixed value
var persistence: float = 0.5 #fixed value

var fade_type: FadeType
var n: int
var octaves: int

func _init(in_fade_type: FadeType = FadeType.LERP, in_n: int = 255, in_octaves:int = 1) -> void:
	fade_type = in_fade_type
	for idx in range(512):
		p.append(base_permutation[idx % 256])
	n = in_n
	octaves = clamp(in_octaves, 1, 4)
	
func shuffle_p():
	p.shuffle()

func _hash1d(x: int) -> float:
	var h = p[x % n]
	#should return random value from -1 to 1
	return lerp(-1.0, 1.0, h / 255.0)

func _noise1d(x:float) -> float:
	var xi = int(floor(x))
	var xf = x - xi

	match fade_type:
		FadeType.LERP:
			pass
		FadeType.SMOOTHSTEP:
			xf = xf * xf * (3.0 - 2.0 * xf);
		FadeType.SMOOTHERSTEP:
			xf = xf * xf * xf * (xf * (xf * 6.0 - 15.0) + 10.0);
		FadeType.EASEINOUTEXPO:
			var result = 0
			if xf == 0:
				result = 0
			elif xf == 1:
				result = 1
			elif xf < 0.5:
				result = pow(2.0, 20.0 * xf - 10.0) / 2.0
			else:
				result = (2.0 - pow(2.0, -20.0 * xf + 10.0)) / 2.0
			xf = result
		FadeType.EASEINOUTCIRC:
			var result = 0
			if xf < 0.5:
				result = (1.0 - sqrt(1.0 - pow(2.0 * xf, 2.0))) / 2.0
			else:
				result = (sqrt(1.0 - pow(-2.0 * xf + 2.0, 2.0)) + 1.0) / 2.0
			xf = result
		_:
			pass
	return lerp(_hash1d(xi), _hash1d(xi + 1), xf)
	
func perlin1d(x: float) -> float:
	var final_noise = 0
	for s in range(octaves):
		#persistence affects amplitude change at each level
		#lacunarity effects frequency change at each level
		final_noise += pow(persistence, s) * _noise1d(pow(lacunarity, s) * x)
	return final_noise
