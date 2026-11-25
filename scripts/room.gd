extends RefCounted
## Builds the electronics repair workshop at real scale.
## Bench top at y = 0.92 m; player faces -Z towards the bench and pegboard.

const Kit = preload("res://scripts/kit.gd")

const ROOM_X := 2.6
const ROOM_BACK := -1.75
const ROOM_FRONT := 2.6
const ROOM_H := 2.8
const BENCH_Y := 0.92
const BENCH_Z := -1.325
const MAT_Y := 0.923
const I18n = preload("res://scripts/i18n.gd")
const COUNTER_Z := 1.55
const COUNTER_TOP := 1.02
const DOOR_X := 2.0

var root: Node3D
var env: Environment
var world_env: WorldEnvironment
var lamp_light: SpotLight3D
var sun: DirectionalLight3D
var probe: ReflectionProbe
var spot_lights: Array[Light3D] = []
var door: Node3D
var bell: Node3D
var door_sign: Label3D
var tablet_label: Label3D
var rng := RandomNumberGenerator.new()


func build(parent: Node3D) -> Node3D:
	rng.seed = 42
	root = Node3D.new()
	root.name = "Workshop"
	parent.add_child(root)
	_environment()
	_shell()
	_window()
	_bench()
	_pegboard()
	_sign()
	_shelving()
	_cabinets()
	_lamp()
	_ceiling()
	_plants()
	_decor()
	_floor_props()
	_counter()
	_door()
	return root


# -----------------------------------------------------------------------------
func _environment() -> void:
	world_env = WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("2a3d66")
	sm.sky_horizon_color = Color("f0a36b")
	sm.ground_horizon_color = Color("5a4a48")
	sm.ground_bottom_color = Color("1d1f26")
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b0f16")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("5b6d8f")
	env.ambient_light_energy = 0.42
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.08
	world_env.environment = env
	root.add_child(world_env)

	probe = ReflectionProbe.new()
	probe.size = Vector3(ROOM_X * 2.0, ROOM_H, ROOM_FRONT - ROOM_BACK)
	probe.position = Vector3(0, ROOM_H * 0.5, (ROOM_FRONT + ROOM_BACK) * 0.5)
	probe.origin_offset = Vector3(0, -0.2, -1.6)
	probe.box_projection = true
	probe.interior = true
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.8
	root.add_child(probe)

	# low warm sun coming through the window (back right)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("ffb36b")
	sun.light_energy = 2.4
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.directional_shadow_max_distance = 9.0
	root.add_child(sun)
	sun.basis = Basis.looking_at(Vector3(-0.55, -0.42, 0.72).normalized(), Vector3.UP)

	# cool fill from the room (front) so shadows never go pitch black
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.4, 2.3, 1.3)
	fill.light_color = Color("8fb2ff")
	fill.light_energy = 0.55
	fill.omni_range = 5.5
	root.add_child(fill)


func _shell() -> void:
	var floor_mat := Kit.pbr("concrete_pbr", 0.85, 0.0, Color("8a8f94"), Vector3(0.6, 0.6, 0.6), true, 0.5)
	Kit.box(root, Vector3(ROOM_X * 2.0, 0.1, ROOM_FRONT - ROOM_BACK), floor_mat, Vector3(0, -0.05, (ROOM_FRONT + ROOM_BACK) * 0.5))
	var wall := Kit.pbr("wall_pbr", 0.85, 0.0, Color("4a6283"), Vector3(0.7, 0.7, 0.7), true, 0.45)
	# back wall with a window opening (x 1.25..2.35, y 1.15..2.45)
	var z := ROOM_BACK - 0.05
	Kit.box(root, Vector3(3.85, ROOM_H, 0.1), wall, Vector3(-0.675, ROOM_H * 0.5, z))
	Kit.box(root, Vector3(0.25, ROOM_H, 0.1), wall, Vector3(2.475, ROOM_H * 0.5, z))
	Kit.box(root, Vector3(1.1, 1.15, 0.1), wall, Vector3(1.8, 0.575, z))
	Kit.box(root, Vector3(1.1, ROOM_H - 2.45, 0.1), wall, Vector3(1.8, 2.45 + (ROOM_H - 2.45) * 0.5, z))
	# side + front walls
	Kit.box(root, Vector3(0.1, ROOM_H, ROOM_FRONT - ROOM_BACK), wall, Vector3(-ROOM_X - 0.05, ROOM_H * 0.5, (ROOM_FRONT + ROOM_BACK) * 0.5))
	Kit.box(root, Vector3(0.1, ROOM_H, ROOM_FRONT - ROOM_BACK), wall, Vector3(ROOM_X + 0.05, ROOM_H * 0.5, (ROOM_FRONT + ROOM_BACK) * 0.5))
	# front wall with the shop door (x 1.55..2.45, h 2.1)
	var fz := ROOM_FRONT + 0.05
	Kit.box(root, Vector3(4.15, ROOM_H, 0.1), wall, Vector3(-0.525, ROOM_H * 0.5, fz))
	Kit.box(root, Vector3(0.15, ROOM_H, 0.1), wall, Vector3(2.525, ROOM_H * 0.5, fz))
	Kit.box(root, Vector3(0.9, ROOM_H - 2.1, 0.1), wall, Vector3(2.0, 2.1 + (ROOM_H - 2.1) * 0.5, fz))
	var ceil := Kit.mat(Color("1b222c"), 0.9)
	Kit.box(root, Vector3(ROOM_X * 2.0, 0.1, ROOM_FRONT - ROOM_BACK), ceil, Vector3(0, ROOM_H + 0.05, (ROOM_FRONT + ROOM_BACK) * 0.5))
	# skirting board
	var skirt := Kit.mat(Color("1d2633"), 0.6)
	Kit.box(root, Vector3(ROOM_X * 2.0, 0.08, 0.015), skirt, Vector3(0, 0.04, ROOM_BACK + 0.008))
	Kit.box(root, Vector3(0.015, 0.08, ROOM_FRONT - ROOM_BACK), skirt, Vector3(-ROOM_X + 0.008, 0.04, (ROOM_FRONT + ROOM_BACK) * 0.5))
	Kit.box(root, Vector3(0.015, 0.08, ROOM_FRONT - ROOM_BACK), skirt, Vector3(ROOM_X - 0.008, 0.04, (ROOM_FRONT + ROOM_BACK) * 0.5))
	# exposed conduit along the back wall
	var conduit := Kit.mat(Color("6c7681"), 0.4, 0.8)
	Kit.cyl(root, 0.012, ROOM_X * 2.0, conduit, Vector3(0, 2.62, ROOM_BACK + 0.03), Vector3(0, 0, 90))
	Kit.cyl(root, 0.012, 1.6, conduit, Vector3(-1.2, 1.82, ROOM_BACK + 0.03))
	Kit.box(root, Vector3(0.08, 0.12, 0.04), Kit.mat(Color("8a939c"), 0.5, 0.6), Vector3(-1.2, 1.0, ROOM_BACK + 0.03))


func _window() -> void:
	var x0 := 1.25
	var x1 := 2.35
	var y0 := 1.15
	var y1 := 2.45
	var cx := (x0 + x1) * 0.5
	var cy := (y0 + y1) * 0.5
	var z := ROOM_BACK - 0.05
	# outside: dusk sky + city silhouettes
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("ffcf8a"), Color("f08a5a"), Color("8c4f7a"), Color("2c3263")])
	grad.offsets = PackedFloat32Array([0.0, 0.25, 0.55, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 1.0)
	gt.fill_to = Vector2(0.5, 0.0)
	var sky_mat := StandardMaterial3D.new()
	sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky_mat.albedo_texture = gt
	sky_mat.albedo_color = Color(1.35, 1.25, 1.2)
	var sky_plane := QuadMesh.new()
	sky_plane.size = Vector2(4.0, 2.6)
	Kit.mi(root, sky_plane, sky_mat, Vector3(cx, cy + 0.4, z - 1.6))
	var city := Kit.mat(Color("1b1d2e"), 0.9)
	for i in range(9):
		var w := rng.randf_range(0.25, 0.5)
		var h := rng.randf_range(0.3, 1.1)
		Kit.box(root, Vector3(w, h, 0.2), city, Vector3(cx - 1.4 + i * 0.36, 0.85 + h * 0.5, z - 1.3))
	# little lit windows on the buildings
	var lit := Kit.emissive(Color("ffd28a"), 2.0, true)
	for i in range(24):
		Kit.box(root, Vector3(0.03, 0.04, 0.005), lit, Vector3(cx - 1.4 + rng.randf() * 3.0, 0.95 + rng.randf() * 0.5, z - 1.19))
	# trees in front of the buildings
	var tree := Kit.mat(Color("23322a"), 0.9)
	for i in range(4):
		Kit.sphere(root, rng.randf_range(0.25, 0.4), tree, Vector3(cx - 0.9 + i * 0.6, 1.05 + rng.randf() * 0.2, z - 0.8), Vector3(1.0, 0.85, 0.6))
	# frame: black steel with a 3x3 grid
	var steel := Kit.mat(Color("15181c"), 0.45, 0.7)
	var t := 0.045
	Kit.box(root, Vector3(x1 - x0 + t, t, 0.08), steel, Vector3(cx, y0, z))
	Kit.box(root, Vector3(x1 - x0 + t, t, 0.08), steel, Vector3(cx, y1, z))
	Kit.box(root, Vector3(t, y1 - y0, 0.08), steel, Vector3(x0, cy, z))
	Kit.box(root, Vector3(t, y1 - y0, 0.08), steel, Vector3(x1, cy, z))
	for i in range(1, 3):
		Kit.box(root, Vector3(0.02, y1 - y0, 0.03), steel, Vector3(x0 + (x1 - x0) * i / 3.0, cy, z))
		Kit.box(root, Vector3(x1 - x0, 0.02, 0.03), steel, Vector3(cx, y0 + (y1 - y0) * i / 3.0, z))
	var glass := Kit.glass(Color(0.8, 0.9, 1.0), 0.02, 0.08)
	Kit.box(root, Vector3(x1 - x0, y1 - y0, 0.004), glass, Vector3(cx, cy, z - 0.01))
	# sill
	Kit.box(root, Vector3(x1 - x0 + 0.12, 0.03, 0.2), Kit.pbr("walnut_pbr", 0.6, 0.0, Color("c48a5c"), Vector3(2, 2, 2), true), Vector3(cx, y0 - 0.015, ROOM_BACK + 0.05))


func _bench() -> void:
	var wood := Kit.pbr("walnut_pbr", 0.55, 0.0, Color("c9b6a4"), Vector3(1.2, 1.2, 1.2), true, 0.5)
	wood.clearcoat_enabled = true
	wood.clearcoat = 0.35
	wood.clearcoat_roughness = 0.4
	Kit.slab(root, Vector3(2.2, 0.045, 0.75), 0.01, 0.006, wood, wood, wood, Vector3(0, BENCH_Y - 0.0225, BENCH_Z))
	var frame := Kit.mat(Color("2b3138"), 0.4, 0.8)
	for x in [-1.05, 1.05]:
		for z in [BENCH_Z - 0.32, BENCH_Z + 0.32]:
			Kit.box(root, Vector3(0.05, BENCH_Y - 0.045, 0.05), frame, Vector3(x, (BENCH_Y - 0.045) * 0.5, z))
		Kit.box(root, Vector3(0.04, 0.04, 0.64), frame, Vector3(x, 0.15, BENCH_Z))
	Kit.box(root, Vector3(2.1, 0.06, 0.03), frame, Vector3(0, BENCH_Y - 0.075, BENCH_Z + 0.33))
	Kit.box(root, Vector3(2.1, 0.06, 0.03), frame, Vector3(0, BENCH_Y - 0.075, BENCH_Z - 0.33))
	# lower shelf
	Kit.box(root, Vector3(2.1, 0.02, 0.6), Kit.mat(Color("333a42"), 0.6, 0.4), Vector3(0, 0.17, BENCH_Z))
	# power strip at the back edge
	var strip := Kit.plastic(Color("e9ecef"), 0.4)
	Kit.slab(root, Vector3(0.36, 0.035, 0.055), 0.008, 0.006, strip, null, null, Vector3(0.55, BENCH_Y + 0.0175, BENCH_Z - 0.32))
	for i in range(4):
		Kit.cyl(root, 0.013, 0.002, Kit.plastic(Color("cfd4d8"), 0.4), Vector3(0.43 + i * 0.075, BENCH_Y + 0.036, BENCH_Z - 0.32))
	Kit.box(root, Vector3(0.012, 0.006, 0.012), Kit.emissive(Color("ff3b30"), 3.0), Vector3(0.71, BENCH_Y + 0.036, BENCH_Z - 0.32))
	# self-healing cutting mat (A2)
	var mat := Kit.pbr("mat_pbr", 0.9, 0.0, Color.WHITE, Vector3(3.0, 1.0, 2.0), false, 0.3)
	Kit.slab(root, Vector3(0.90, 0.003, 0.60), 0.012, 0.001, mat, Kit.mat(Color("1f4a44"), 0.8), Kit.mat(Color("1f4a44"), 0.8), Vector3(0.0, BENCH_Y + 0.0015, -1.25))
	# bench collision for hand placement
	var b := Kit.static_body(root, Kit.box_shape(Vector3(2.2, 0.05, 0.75)), Vector3(0, BENCH_Y - 0.025, BENCH_Z))
	b.collision_layer = 2


func _pegboard() -> void:
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	img.fill(Color("2c3e55"))
	for gx in range(8):
		for gy in range(8):
			var c := Vector2(16 + gx * 32, 16 + gy * 32)
			for dx in range(-4, 5):
				for dy in range(-4, 5):
					if dx * dx + dy * dy <= 14:
						img.set_pixel(int(c.x) + dx, int(c.y) + dy, Color("0c121a"))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	var m := Kit.mat(Color.WHITE, 0.75)
	m.albedo_texture = tex
	m.uv1_scale = Vector3(16, 9, 1)
	var board := BoxMesh.new()
	board.size = Vector3(2.1, 0.95, 0.015)
	Kit.mi(root, board, m, Vector3(0, 1.48, ROOM_BACK + 0.012))
	var z := ROOM_BACK + 0.03
	# hanging tools
	var colors := [Color("e74c3c"), Color("f1c40f"), Color("2e86de"), Color("27ae60"), Color("e67e22"), Color("8e44ad")]
	for i in range(6):
		_hang_screwdriver(Vector3(-0.85 + i * 0.07, 1.62, z), colors[i], 0.15 + 0.03 * (i % 3))
	for i in range(5):
		_hang_wrench(Vector3(-0.32 + i * 0.075, 1.67, z), 0.15 + i * 0.025)
	_hang_pliers(Vector3(0.15, 1.65, z), Color("d63031"))
	_hang_pliers(Vector3(0.27, 1.65, z), Color("0984e3"))
	_hang_pliers(Vector3(0.39, 1.65, z), Color("fdcb6e"))
	# soldering station + headphones + spool on the board shelf
	var shelf := Kit.pbr("walnut_pbr", 0.6, 0.0, Color("c48a5c"), Vector3(2, 2, 2), true)
	Kit.box(root, Vector3(0.62, 0.02, 0.16), shelf, Vector3(0.68, 1.30, ROOM_BACK + 0.09))
	for x in [0.42, 0.94]:
		Kit.box(root, Vector3(0.015, 0.08, 0.12), Kit.mat(Color("20262d"), 0.4, 0.7), Vector3(x, 1.26, ROOM_BACK + 0.07))
	for i in range(3):
		var bin := Kit.plastic([Color("2d6cdf"), Color("e1b12c"), Color("c0392b")][i], 0.45)
		Kit.slab(root, Vector3(0.14, 0.075, 0.12), 0.01, 0.004, bin, null, null, Vector3(0.48 + i * 0.17, 1.35, ROOM_BACK + 0.09))
	# headphones on a hook
	var hp := Kit.plastic(Color("1b1e22"), 0.4)
	var band := Kit.torus(root, 0.075, 0.088, hp, Vector3(0.88, 1.75, z + 0.02), Vector3(90, 0, 0))
	band.scale = Vector3(1, 1, 1.1)
	Kit.cyl(root, 0.035, 0.03, hp, Vector3(0.80, 1.68, z + 0.035), Vector3(90, 0, 0))
	Kit.cyl(root, 0.035, 0.03, hp, Vector3(0.96, 1.68, z + 0.035), Vector3(90, 0, 0))
	# cable coils
	for i in range(3):
		var coil := Kit.torus(root, 0.05, 0.058, Kit.plastic([Color("111111"), Color("e8e8e8"), Color("c0392b")][i], 0.5), Vector3(-0.88 + i * 0.13, 1.25, z + 0.015), Vector3(90, 0, 0))
		coil.scale = Vector3(1, 1, 1.25)


func _hang_screwdriver(pos: Vector3, color: Color, length: float) -> void:
	var p := Kit.plastic(color, 0.35)
	Kit.cyl(root, 0.011, 0.085, p, pos + Vector3(0, 0.0, 0.012))
	Kit.cyl(root, 0.003, length, Kit.chrome(), pos + Vector3(0, -0.04 - length * 0.5, 0.012))
	Kit.cyl(root, 0.0025, 0.03, Kit.chrome(), pos + Vector3(0, 0.05, 0.004), Vector3(90, 0, 0))


func _hang_wrench(pos: Vector3, length: float) -> void:
	var steel := Kit.chrome(Color("c3c8ce"))
	steel.roughness = 0.25
	Kit.box(root, Vector3(0.014, length, 0.004), steel, pos + Vector3(0, -length * 0.5, 0.01))
	var r := Kit.torus(root, 0.01, 0.019, steel, pos + Vector3(0, 0.004, 0.01), Vector3(90, 0, 0))
	r.scale = Vector3(1, 0.3, 1)
	var head := Kit.torus(root, 0.008, 0.02, steel, pos + Vector3(0, -length - 0.006, 0.01), Vector3(90, 0, 0))
	head.scale = Vector3(1, 0.3, 1)


func _hang_pliers(pos: Vector3, color: Color) -> void:
	var steel := Kit.mat(Color("6e7781"), 0.35, 0.9)
	var grip := Kit.plastic(color, 0.5)
	for s in [-1.0, 1.0]:
		var arm := Kit.capsule(root, 0.008, 0.11, grip, pos + Vector3(s * 0.016, -0.075, 0.012), Vector3(0, 0, s * 8.0))
		arm.scale = Vector3(1, 1, 0.7)
	Kit.box(root, Vector3(0.02, 0.06, 0.008), steel, pos + Vector3(0, 0.0, 0.012))
	Kit.cyl(root, 0.007, 0.012, steel, pos + Vector3(0, -0.02, 0.012), Vector3(90, 0, 0))


func _sign() -> void:
	var z := ROOM_BACK + 0.02
	var plate := Kit.mat(Color("0d141e"), 0.5, 0.2)
	Kit.slab(root, Vector3(1.25, 0.012, 0.48), 0.04, 0.004, plate, plate, plate, Vector3(0, 2.25, z + 0.006), Vector3(90, 0, 0))
	var tube := Kit.emissive(Color("3aa8ff"), 4.0, true)
	# neon border
	var hw := 0.6
	var hh := 0.22
	Kit.cyl(root, 0.004, hw * 2.0, tube, Vector3(0, 2.25 + hh, z + 0.02), Vector3(0, 0, 90))
	Kit.cyl(root, 0.004, hw * 2.0, tube, Vector3(0, 2.25 - hh, z + 0.02), Vector3(0, 0, 90))
	Kit.cyl(root, 0.004, hh * 2.0, tube, Vector3(-hw, 2.25, z + 0.02))
	Kit.cyl(root, 0.004, hh * 2.0, tube, Vector3(hw, 2.25, z + 0.02))
	for txt in [["FIX & FLIP", 2.32, 150], ["TECH", 2.15, 150]]:
		var glow := Label3D.new()
		glow.text = txt[0]
		glow.font_size = txt[2]
		glow.pixel_size = 0.00092
		glow.modulate = Color(0.55, 0.85, 2.6)
		glow.outline_modulate = Color(0.05, 0.35, 1.0, 0.85)
		glow.outline_size = 22
		glow.shaded = false
		glow.position = Vector3(0, txt[1], z + 0.026)
		var f := load("res://assets/fonts/Nunito-ExtraBold.ttf")
		if f:
			glow.font = f
		root.add_child(glow)
	var neon := OmniLight3D.new()
	neon.light_color = Color("3d9bff")
	neon.light_energy = 1.4
	neon.omni_range = 1.7
	neon.position = Vector3(0, 2.25, z + 0.35)
	root.add_child(neon)


func _shelving() -> void:
	# tall steel shelving unit on the left of the bench
	var steel := Kit.mat(Color("38414b"), 0.45, 0.75)
	var x0 := -2.25
	var x1 := -1.3
	var z := ROOM_BACK + 0.24
	for x in [x0, x1]:
		for dz in [-0.2, 0.2]:
			Kit.box(root, Vector3(0.035, 2.1, 0.035), steel, Vector3(x, 1.05, z + dz))
	var wood := Kit.pbr("walnut_pbr", 0.6, 0.0, Color("b07a4e"), Vector3(2, 2, 2), true)
	var levels := [0.35, 0.85, 1.35, 1.85]
	for y in levels:
		Kit.box(root, Vector3(x1 - x0 + 0.04, 0.025, 0.44), wood, Vector3((x0 + x1) * 0.5, y, z))
	# LED strip under the top shelf
	Kit.box(root, Vector3(x1 - x0 - 0.1, 0.008, 0.012), Kit.emissive(Color("39d5ff"), 4.0, true), Vector3((x0 + x1) * 0.5, 1.83, z + 0.15))
	var led := OmniLight3D.new()
	led.light_color = Color("39d5ff")
	led.light_energy = 0.7
	led.omni_range = 0.9
	led.position = Vector3((x0 + x1) * 0.5, 1.75, z + 0.2)
	root.add_child(led)
	# storage bins + boxes + old electronics
	for i in range(3):
		_bin(Vector3(x0 + 0.17 + i * 0.3, 0.85 + 0.0125, z), [Color("2d6cdf"), Color("2d6cdf"), Color("e1b12c")][i])
	for i in range(2):
		_cardboard(Vector3(x0 + 0.22 + i * 0.42, 0.35 + 0.0125, z), Vector3(0.36, 0.3, 0.34))
	_cardboard(Vector3(x0 + 0.25, 1.85 + 0.0125, z), Vector3(0.3, 0.22, 0.3))
	_bin(Vector3(x0 + 0.66, 1.85 + 0.0125, z), Color("c0392b"))
	# old CRT-ish monitor and a radio on the middle shelf
	var plastic := Kit.plastic(Color("cfc6b4"), 0.5)
	Kit.slab(root, Vector3(0.32, 0.27, 0.26), 0.02, 0.012, plastic, null, null, Vector3(x0 + 0.24, 1.35 + 0.0125 + 0.135, z), Vector3(90, 0, 0))
	var scr := Kit.mat(Color("1a2a2a"), 0.15, 0.1)
	Kit.box(root, Vector3(0.25, 0.19, 0.01), scr, Vector3(x0 + 0.24, 1.35 + 0.15, z + 0.13))
	var radio := Kit.plastic(Color("2b2b2b"), 0.45)
	Kit.slab(root, Vector3(0.3, 0.16, 0.12), 0.015, 0.006, radio, null, null, Vector3(x0 + 0.68, 1.35 + 0.0125 + 0.08, z), Vector3(90, 0, 0))
	Kit.cyl(root, 0.045, 0.01, Kit.mat(Color("6d6d6d"), 0.6, 0.6), Vector3(x0 + 0.62, 1.35 + 0.09, z + 0.065), Vector3(90, 0, 0))
	Kit.box(root, Vector3(0.08, 0.03, 0.004), Kit.emissive(Color("ffb347"), 1.5), Vector3(x0 + 0.75, 1.35 + 0.12, z + 0.063))
	# small parts drawer cabinet on the right side of the bench, on the wall
	var cab := Kit.plastic(Color("7f8c8d"), 0.5)
	Kit.box(root, Vector3(0.36, 0.3, 0.16), cab, Vector3(-0.85, 1.12, ROOM_BACK + 0.09))
	for r in range(4):
		for c in range(3):
			Kit.box(root, Vector3(0.1, 0.055, 0.01), Kit.plastic(Color("c8d6e5"), 0.3), Vector3(-0.96 + c * 0.11, 1.02 + r * 0.068, ROOM_BACK + 0.17))
			Kit.box(root, Vector3(0.03, 0.008, 0.008), Kit.plastic(Color("222f3e"), 0.3), Vector3(-0.96 + c * 0.11, 1.01 + r * 0.068, ROOM_BACK + 0.178))


func _bin(pos: Vector3, color: Color) -> void:
	var p := Kit.plastic(color, 0.45)
	Kit.slab(root, Vector3(0.26, 0.15, 0.36), 0.015, 0.005, p, null, null, pos + Vector3(0, 0.075, 0))
	Kit.box(root, Vector3(0.1, 0.04, 0.003), Kit.plastic(Color("f5f6fa"), 0.6), pos + Vector3(0, 0.09, 0.182))


func _cardboard(pos: Vector3, size: Vector3) -> void:
	var c := Kit.plastic(Color("b98b55"), 0.9, 0.3)
	Kit.slab(root, size, 0.004, 0.003, c, null, null, pos + Vector3(0, size.y * 0.5, 0), Vector3(0, rng.randf_range(-6, 6), 0))
	Kit.box(root, Vector3(size.x + 0.002, 0.004, 0.05), Kit.plastic(Color("c9a26f"), 0.4), pos + Vector3(0, size.y + 0.001, 0))


func _cabinets() -> void:
	# red rolling tool chests either side of the bench
	for x in [-1.48, 1.62]:
		var red := Kit.mat(Color("b3261e"), 0.32, 0.55)
		red.clearcoat_enabled = true
		red.clearcoat = 0.6
		var h := 0.86
		Kit.slab(root, Vector3(0.6, 0.5, h), 0.02, 0.01, red, null, null, Vector3(x, 0.08 + h * 0.5, -1.47), Vector3(90, 0, 0))
		Kit.slab(root, Vector3(0.62, 0.02, 0.52), 0.015, 0.006, Kit.rubber(Color("1b1b1b")), null, null, Vector3(x, 0.08 + h + 0.01, -1.47))
		var handle := Kit.chrome()
		for i in range(5):
			var dy := 0.17 + i * 0.15
			Kit.box(root, Vector3(0.56, 0.004, 0.004), Kit.mat(Color("5c1410"), 0.5), Vector3(x, 0.08 + dy + 0.07, -1.22 + 0.002))
			Kit.cyl(root, 0.007, 0.36, handle, Vector3(x, 0.08 + dy, -1.205), Vector3(0, 0, 90))
		for cx in [-0.25, 0.25]:
			for cz in [-0.2, 0.2]:
				Kit.cyl(root, 0.035, 0.03, Kit.rubber(), Vector3(x + cx, 0.04, -1.47 + cz), Vector3(0, 0, 90))
	# props on top of the chests
	_cardboard(Vector3(-1.48, 0.95, -1.5), Vector3(0.34, 0.2, 0.3))
	var printer := Kit.plastic(Color("e5e7ea"), 0.45)
	Kit.slab(root, Vector3(0.42, 0.16, 0.32), 0.02, 0.01, printer, null, null, Vector3(1.62, 0.95 + 0.08, -1.5))
	Kit.box(root, Vector3(0.3, 0.01, 0.06), Kit.plastic(Color("2d3436"), 0.4), Vector3(1.62, 1.1, -1.36))


func _lamp() -> void:
	# articulated desk lamp, base at the back-left of the bench
	var black := Kit.mat(Color("1d2126"), 0.38, 0.6)
	var joint := Kit.mat(Color("2f353c"), 0.35, 0.7)
	var base := Vector3(-0.78, BENCH_Y, -1.55)
	Kit.cyl(root, 0.075, 0.02, black, base + Vector3(0, 0.01, 0), Vector3.ZERO, 0.068)
	var p1 := base + Vector3(0, 0.03, 0)
	var p2 := base + Vector3(0.06, 0.44, 0.05)
	var p3 := Vector3(-0.42, 1.38, -1.22)
	for seg in [[p1, p2], [p2, p3]]:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		for off in [-0.012, 0.012]:
			var o := Vector3(off, 0, 0)
			Kit.mi(root, Kit.tube_mesh(PackedVector3Array([a + o, b + o]), 0.0065, 10), black)
		Kit.sphere(root, 0.018, joint, b)
	Kit.sphere(root, 0.02, joint, p1)
	# springs
	Kit.mi(root, Kit.tube_mesh(PackedVector3Array([p1 + Vector3(0, 0.05, -0.02), p2 + Vector3(0, -0.08, -0.02)]), 0.003, 6), Kit.chrome())
	# shade pointing down at the mat
	var head := Node3D.new()
	head.position = p3
	root.add_child(head)
	head.look_at_from_position(p3, Vector3(-0.1, BENCH_Y, -1.2), Vector3.UP)
	var shade_mat := Kit.mat(Color("1d2126"), 0.4, 0.5)
	var inner := Kit.mat(Color("efe7da"), 0.6)
	var shade := Kit.cyl(head, 0.03, 0.14, shade_mat, Vector3(0, 0, -0.06), Vector3(-90, 0, 0), 0.085, 40)
	shade.name = "Shade"
	Kit.cyl(head, 0.082, 0.004, inner, Vector3(0, 0, -0.128), Vector3(-90, 0, 0))
	Kit.sphere(head, 0.03, Kit.emissive(Color("fff1d6"), 6.0, true), Vector3(0, 0, -0.10), Vector3(1, 1, 0.7))
	lamp_light = SpotLight3D.new()
	lamp_light.light_color = Color("ffe2b5")
	lamp_light.light_energy = 3.4
	lamp_light.spot_range = 2.6
	lamp_light.spot_angle = 48.0
	lamp_light.spot_attenuation = 0.8
	lamp_light.shadow_enabled = true
	lamp_light.shadow_bias = 0.02
	lamp_light.position = Vector3(0, 0, -0.11)
	head.add_child(lamp_light)
	spot_lights.append(lamp_light)


func _ceiling() -> void:
	for x in [-0.55, 0.55]:
		var top := Vector3(x, ROOM_H, -1.15)
		var cord := Kit.mat(Color("111111"), 0.6)
		top.y += 0.22
		Kit.cyl(root, 0.003, 0.55, cord, top + Vector3(0, -0.275, 0))
		var shade := Kit.mat(Color("23312b"), 0.35, 0.6)
		Kit.cyl(root, 0.035, 0.12, shade, top + Vector3(0, -0.6, 0), Vector3.ZERO, 0.035, 24)
		Kit.cyl(root, 0.17, 0.16, shade, top + Vector3(0, -0.72, 0), Vector3.ZERO, 0.04, 40)
		Kit.cyl(root, 0.165, 0.004, Kit.mat(Color("f2eee6"), 0.6), top + Vector3(0, -0.799, 0))
		Kit.sphere(root, 0.05, Kit.emissive(Color("fff0d2"), 5.0, true), top + Vector3(0, -0.77, 0))
		var s := SpotLight3D.new()
		s.position = top + Vector3(0, -0.78, 0)
		s.rotation_degrees = Vector3(-90, 0, 0)
		s.light_color = Color("ffdcae")
		s.light_energy = 3.2
		s.spot_range = 3.4
		s.spot_angle = 58.0
		s.shadow_enabled = true
		root.add_child(s)
		spot_lights.append(s)
	# HVAC duct
	var duct := Kit.mat(Color("8f98a1"), 0.35, 0.8)
	Kit.box(root, Vector3(0.32, 0.22, ROOM_FRONT - ROOM_BACK), duct, Vector3(-1.9, ROOM_H - 0.15, (ROOM_FRONT + ROOM_BACK) * 0.5))


func _plants() -> void:
	var leaf_mesh := Kit.leaf_mesh(0.07, 0.05, 0.3)
	var leaf_mats := [Kit.mat(Color("3f8f3a"), 0.5), Kit.mat(Color("5aa845"), 0.5), Kit.mat(Color("2f7a35"), 0.5)]
	for lm in leaf_mats:
		lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	# hanging pothos above the left of the bench
	var hang := Vector3(-1.05, 2.25, -1.45)
	Kit.cyl(root, 0.002, 0.5, Kit.mat(Color("8a7a63"), 0.8), hang + Vector3(0, 0.3, 0))
	var pot := Kit.mat(Color("e6dfd3"), 0.6)
	Kit.cyl(root, 0.11, 0.14, pot, hang, Vector3.ZERO, 0.085, 32)
	_bush(hang + Vector3(0, 0.08, 0), 0.12, 28, leaf_mesh, leaf_mats)
	for v in range(6):
		var a := TAU * v / 6.0 + 0.3
		var start := hang + Vector3(cos(a) * 0.09, 0.05, sin(a) * 0.09)
		var length := rng.randf_range(0.35, 0.8)
		_vine(start, Vector3(cos(a) * 0.12, -length, sin(a) * 0.12), leaf_mesh, leaf_mats)
	# window-sill plant
	var sill := Vector3(1.55, 1.15 + 0.015, ROOM_BACK + 0.06)
	Kit.cyl(root, 0.07, 0.11, Kit.mat(Color("c0703f"), 0.7), sill + Vector3(0, 0.055, 0), Vector3.ZERO, 0.055)
	_bush(sill + Vector3(0, 0.12, 0), 0.1, 22, leaf_mesh, leaf_mats)
	# bench succulent
	var bp := Vector3(0.92, BENCH_Y, -1.6)
	Kit.cyl(root, 0.045, 0.07, Kit.mat(Color("2f3640"), 0.6), bp + Vector3(0, 0.035, 0), Vector3.ZERO, 0.038)
	_bush(bp + Vector3(0, 0.075, 0), 0.05, 14, leaf_mesh, leaf_mats)
	# floor plant in the corner
	var fp := Vector3(2.25, 0, 0.0)
	Kit.cyl(root, 0.18, 0.4, Kit.mat(Color("2b2f36"), 0.5), fp + Vector3(0, 0.2, 0), Vector3.ZERO, 0.14)
	for i in range(9):
		var a := TAU * i / 9.0
		var stem_top := fp + Vector3(cos(a) * 0.25, 0.9 + rng.randf() * 0.5, sin(a) * 0.25)
		Kit.mi(root, Kit.tube_mesh(Kit.bezier(fp + Vector3(0, 0.4, 0), fp + Vector3(cos(a) * 0.05, 0.7, sin(a) * 0.05), stem_top - Vector3(cos(a) * 0.1, 0.1, sin(a) * 0.1), stem_top, 10), 0.006, 6), Kit.mat(Color("4a6b2f"), 0.7))
		var big := Kit.mi(root, Kit.leaf_mesh(0.32, 0.24, 0.2), leaf_mats[i % 3], stem_top)
		big.look_at_from_position(stem_top, stem_top + Vector3(cos(a), -0.4, sin(a)), Vector3.UP)


func _bush(center: Vector3, radius: float, count: int, mesh: Mesh, mats: Array) -> void:
	for i in range(count):
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.0, 1.0), rng.randf_range(-1, 1)).normalized()
		var p := center + dir * radius * rng.randf_range(0.3, 1.0)
		var l := Kit.mi(root, mesh, mats[i % mats.size()], p)
		l.look_at_from_position(p, p + dir + Vector3(0, -0.3, 0), Vector3.UP)
		l.scale = Vector3.ONE * rng.randf_range(0.7, 1.2)


func _vine(start: Vector3, extent: Vector3, mesh: Mesh, mats: Array) -> void:
	var pts := Kit.bezier(start, start + Vector3(extent.x * 0.8, 0.02, extent.z * 0.8), start + Vector3(extent.x, extent.y * 0.6, extent.z), start + extent, 14)
	Kit.mi(root, Kit.tube_mesh(pts, 0.0025, 5), Kit.mat(Color("4d7a32"), 0.7))
	for i in range(2, pts.size()):
		var p: Vector3 = pts[i]
		var side := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.2), rng.randf_range(-1, 1)).normalized()
		var l := Kit.mi(root, mesh, mats[i % mats.size()], p)
		l.look_at_from_position(p, p + side + Vector3(0, -0.6, 0), Vector3.UP)
		l.scale = Vector3.ONE * rng.randf_range(0.8, 1.25)


func _decor() -> void:
	# coffee mug with steam
	var mug := Kit.plastic(Color("f2efe9"), 0.25, 0.05)
	var mp := Vector3(-0.58, BENCH_Y, -1.55)
	Kit.cyl(root, 0.042, 0.095, mug, mp + Vector3(0, 0.0475, 0), Vector3.ZERO, -1.0, 32)
	Kit.cyl(root, 0.038, 0.002, Kit.mat(Color("3b2416"), 0.2), mp + Vector3(0, 0.088, 0))
	var handle := Kit.torus(root, 0.022, 0.03, mug, mp + Vector3(0.045, 0.05, 0), Vector3(90, 0, 0))
	handle.scale = Vector3(0.9, 1, 1.1)
	label3d_root("F&F", mp + Vector3(0, 0.05, 0.0425), 0.0008)
	# solder spool + parts organiser on the bench
	var org := Kit.plastic(Color("3c4b5c"), 0.45)
	Kit.slab(root, Vector3(0.26, 0.04, 0.16), 0.01, 0.004, org, null, null, Vector3(0.62, BENCH_Y + 0.02, -1.6))
	for i in range(4):
		for j in range(2):
			Kit.box(root, Vector3(0.055, 0.03, 0.065), Kit.plastic(Color("1f2a36"), 0.6), Vector3(0.53 + i * 0.062, BENCH_Y + 0.028, -1.635 + j * 0.072))
	for i in range(14):
		Kit.cyl(root, 0.003, 0.004, Kit.chrome(), Vector3(0.53 + rng.randf() * 0.18, BENCH_Y + 0.016, -1.64 + rng.randf() * 0.08))
	Kit.cyl(root, 0.03, 0.03, Kit.mat(Color("b0b6bc"), 0.3, 0.9), Vector3(0.84, BENCH_Y + 0.015, -1.42), Vector3(0, 0, 0), -1.0, 24)
	Kit.cyl(root, 0.034, 0.004, Kit.plastic(Color("1a1a1a"), 0.4), Vector3(0.84, BENCH_Y + 0.032, -1.42))
	# charger cable curling across the bench
	var cable := Kit.tube_mesh(Kit.bezier(Vector3(0.55, BENCH_Y + 0.003, -1.6), Vector3(0.35, BENCH_Y + 0.003, -1.62), Vector3(0.62, BENCH_Y + 0.003, -1.45), Vector3(0.44, BENCH_Y + 0.003, -1.48), 20), 0.0025, 8)
	Kit.mi(root, cable, Kit.plastic(Color("ecf0f1"), 0.4))
	# whiteboard with job tickets on the left wall
	var wb := Kit.mat(Color("f4f6f8"), 0.2)
	Kit.box(root, Vector3(0.02, 0.7, 1.1), Kit.mat(Color("9aa5b1"), 0.4, 0.6), Vector3(-ROOM_X + 0.01, 1.55, 0.2))
	Kit.box(root, Vector3(0.012, 0.66, 1.06), wb, Vector3(-ROOM_X + 0.02, 1.55, 0.2))
	var note_colors := [Color("ffeaa7"), Color("fab1a0"), Color("81ecec"), Color("ffeaa7")]
	for i in range(4):
		Kit.box(root, Vector3(0.004, 0.12, 0.12), Kit.mat(note_colors[i], 0.8), Vector3(-ROOM_X + 0.028, 1.65 - (i / 2) * 0.2, -0.1 + (i % 2) * 0.18 + i * 0.12))
	var title := Label3D.new()
	title.text = "ORDENS DE REPARAÇÃO"
	title.font_size = 40
	title.pixel_size = 0.0012
	title.modulate = Color("2d3436")
	title.outline_size = 0
	title.position = Vector3(-ROOM_X + 0.03, 1.82, 0.2)
	title.rotation_degrees = Vector3(0, 90, 0)
	root.add_child(title)


func label3d_root(text: String, pos: Vector3, pixel: float) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 32
	l.pixel_size = pixel
	l.modulate = Color("1f6fd1")
	l.outline_size = 0
	l.position = pos
	root.add_child(l)


func _floor_props() -> void:
	# stool
	var seat := Kit.mat(Color("17191c"), 0.55)
	var sp := Vector3(-1.0, 0, -0.25)
	Kit.cyl(root, 0.19, 0.06, seat, sp + Vector3(0, 0.62, 0), Vector3.ZERO, 0.18, 40)
	Kit.cyl(root, 0.025, 0.5, Kit.chrome(), sp + Vector3(0, 0.35, 0))
	Kit.torus(root, 0.15, 0.165, Kit.chrome(), sp + Vector3(0, 0.25, 0))
	for i in range(4):
		var a := TAU * i / 4.0 + 0.4
		Kit.mi(root, Kit.tube_mesh(PackedVector3Array([sp + Vector3(0, 0.12, 0), sp + Vector3(cos(a) * 0.24, 0.0, sin(a) * 0.24)]), 0.012, 8), Kit.chrome())
	# anti-fatigue floor mat
	Kit.slab(root, Vector3(1.2, 0.012, 0.6), 0.03, 0.005, Kit.rubber(Color("202429")), null, null, Vector3(0, 0.006, -0.6))
	# stack of boxes in the back right corner
	_cardboard(Vector3(2.2, 0, -1.2), Vector3(0.45, 0.4, 0.4))
	_cardboard(Vector3(2.18, 0.4, -1.22), Vector3(0.38, 0.32, 0.36))
	_cardboard(Vector3(2.25, 0, -0.7), Vector3(0.4, 0.35, 0.38))
	# small trash/recycling bin for old parts
	Kit.cyl(root, 0.15, 0.4, Kit.plastic(Color("2e7d32"), 0.5), Vector3(-1.7, 0.2, -0.3), Vector3.ZERO, 0.13, 32)
	Kit.cyl(root, 0.155, 0.02, Kit.plastic(Color("1b5e20"), 0.5), Vector3(-1.7, 0.41, -0.3))


# -----------------------------------------------------------------------------
# Shop counter + entrance (customers come in through the door)
# -----------------------------------------------------------------------------
func _counter() -> void:
	var z := COUNTER_Z
	var x0 := -0.5
	var x1 := 1.5
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	var wood := Kit.pbr("walnut_pbr", 0.5, 0.0, Color("caa27c"), Vector3(1.4, 1.4, 1.4), true, 0.5)
	wood.clearcoat_enabled = true
	wood.clearcoat = 0.4
	var front := Kit.mat(Color("1f3550"), 0.55, 0.1)
	# body: customer side panel faces +Z
	Kit.box(root, Vector3(w, COUNTER_TOP - 0.05, 0.5), front, Vector3(cx, (COUNTER_TOP - 0.05) * 0.5, z))
	Kit.slab(root, Vector3(w + 0.08, 0.05, 0.62), 0.012, 0.008, wood, wood, wood, Vector3(cx, COUNTER_TOP - 0.025, z))
	# slatted wood front + kick plate + LED strip
	for i in range(18):
		Kit.box(root, Vector3(0.07, 0.82, 0.02), Kit.pbr("walnut_pbr", 0.6, 0.0, Color("b98a62"), Vector3(2, 2, 2), true), Vector3(x0 + 0.06 + i * (w - 0.12) / 17.0, 0.5, z + 0.26))
	Kit.box(root, Vector3(w, 0.08, 0.02), Kit.mat(Color("15181c"), 0.5, 0.4), Vector3(cx, 0.04, z + 0.265))
	Kit.box(root, Vector3(w - 0.04, 0.012, 0.012), Kit.emissive(Color("3aa8ff"), 3.0, true), Vector3(cx, COUNTER_TOP - 0.06, z + 0.27))
	# neon logo on the front
	var logo := Label3D.new()
	logo.text = "FIX & FLIP"
	logo.font_size = 96
	logo.pixel_size = 0.0011
	logo.modulate = Color(0.55, 0.85, 2.4)
	logo.outline_modulate = Color(0.05, 0.35, 1.0, 0.8)
	logo.outline_size = 16
	logo.shaded = false
	var f := load("res://assets/fonts/Nunito-ExtraBold.ttf")
	if f:
		logo.font = f
	logo.position = Vector3(cx, 0.62, z + 0.285)
	root.add_child(logo)
	# cash register
	var reg := Kit.plastic(Color("2b2f36"), 0.4)
	var rp := Vector3(x0 + 0.35, COUNTER_TOP, z - 0.08)
	Kit.slab(root, Vector3(0.34, 0.09, 0.3), 0.02, 0.01, reg, null, null, rp + Vector3(0, 0.045, 0))
	Kit.slab(root, Vector3(0.24, 0.02, 0.14), 0.01, 0.005, Kit.plastic(Color("d9dde2"), 0.4), null, null, rp + Vector3(0, 0.1, 0.05), Vector3(-15, 0, 0))
	var scr := Kit.slab(root, Vector3(0.22, 0.14, 0.015), 0.008, 0.005, reg, null, null, rp + Vector3(0, 0.2, -0.08), Vector3(-12, 0, 0))
	scr.name = "RegisterScreen"
	Kit.box(root, Vector3(0.19, 0.11, 0.002), Kit.emissive(Color("2ecc71"), 1.2, true), rp + Vector3(0, 0.2, -0.071)).rotation_degrees.x = -12
	# card terminal + service bell + business cards + tablet
	Kit.slab(root, Vector3(0.075, 0.03, 0.14), 0.012, 0.008, Kit.plastic(Color("1b1d21"), 0.4), null, null, Vector3(x0 + 0.68, COUNTER_TOP + 0.015, z + 0.14), Vector3(0, 15, 0))
	Kit.box(root, Vector3(0.055, 0.003, 0.04), Kit.emissive(Color("6ec6ff"), 0.8, true), Vector3(x0 + 0.68, COUNTER_TOP + 0.031, z + 0.12)).rotation_degrees.y = 15
	bell = Node3D.new()
	bell.position = Vector3(cx + 0.35, COUNTER_TOP, z + 0.16)
	root.add_child(bell)
	Kit.cyl(bell, 0.045, 0.012, Kit.mat(Color("2a2a2a"), 0.4, 0.6), Vector3(0, 0.006, 0))
	Kit.sphere(bell, 0.04, Kit.chrome(Color("e6c56a")), Vector3(0, 0.02, 0), Vector3(1, 0.85, 1))
	Kit.cyl(bell, 0.005, 0.015, Kit.chrome(), Vector3(0, 0.06, 0))
	for i in range(5):
		Kit.box(root, Vector3(0.085, 0.002, 0.055), Kit.mat(Color("f4f1ea"), 0.7), Vector3(cx + 0.12, COUNTER_TOP + 0.001 + i * 0.002, z + 0.18)).rotation_degrees.y = randf_range(-6, 6)
	var tab := Kit.slab(root, Vector3(0.2, 0.012, 0.28), 0.015, 0.005, Kit.plastic(Color("17191c"), 0.3), null, null, Vector3(x1 - 0.3, COUNTER_TOP + 0.015, z - 0.05), Vector3(10, -20, 0))
	tab.name = "OrdersTablet"
	var tl := Label3D.new()
	tl.text = I18n.t("PEDIDOS  [P]")
	tl.font_size = 40
	tl.pixel_size = 0.0007
	tl.modulate = Color("f5b82e")
	tl.shaded = false
	tl.position = Vector3(x1 - 0.3, COUNTER_TOP + 0.03, z - 0.05)
	tl.rotation_degrees = Vector3(-80, -20, 0)
	root.add_child(tl)
	tablet_label = tl
	# small plant + "repaired devices" shelf behind the counter
	Kit.cyl(root, 0.05, 0.08, Kit.mat(Color("e8e1d6"), 0.6), Vector3(x1 - 0.08, COUNTER_TOP + 0.04, z + 0.18), Vector3.ZERO, 0.04)
	var leaf := Kit.leaf_mesh(0.06, 0.04, 0.3)
	var lm := Kit.mat(Color("4f9a45"), 0.5)
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(10):
		var a := TAU * i / 10.0
		var p := Vector3(x1 - 0.08 + cos(a) * 0.02, COUNTER_TOP + 0.09, z + 0.18 + sin(a) * 0.02)
		var l := Kit.mi(root, leaf, lm, p)
		l.look_at_from_position(p, p + Vector3(cos(a), 0.6, sin(a)), Vector3.UP)
	# pendant lamp above the counter
	var top := Vector3(cx, ROOM_H, z)
	Kit.cyl(root, 0.003, 0.5, Kit.mat(Color("111111"), 0.6), top + Vector3(0, -0.25, 0))
	var shade := Kit.mat(Color("d9a441"), 0.35, 0.6)
	Kit.cyl(root, 0.2, 0.18, shade, top + Vector3(0, -0.6, 0), Vector3.ZERO, 0.05, 40)
	Kit.sphere(root, 0.05, Kit.emissive(Color("fff0d2"), 5.0, true), top + Vector3(0, -0.66, 0))
	var sp := SpotLight3D.new()
	sp.position = top + Vector3(0, -0.68, 0)
	sp.rotation_degrees = Vector3(-90, 0, 0)
	sp.light_color = Color("ffdcae")
	sp.light_energy = 3.0
	sp.spot_range = 3.2
	sp.spot_angle = 60.0
	sp.shadow_enabled = true
	root.add_child(sp)
	spot_lights.append(sp)
	# shop-side lighting
	var o := OmniLight3D.new()
	o.position = Vector3(1.0, 2.2, 1.9)
	o.light_color = Color("ffe0b8")
	o.light_energy = 1.3
	o.omni_range = 3.5
	root.add_child(o)
	# collision so the hand ray / props behave
	var b := Kit.static_body(root, Kit.box_shape(Vector3(w, COUNTER_TOP, 0.6)), Vector3(cx, COUNTER_TOP * 0.5, z))
	b.collision_layer = 2


func _door() -> void:
	var fz := ROOM_FRONT + 0.05
	var frame := Kit.mat(Color("15181c"), 0.4, 0.6)
	Kit.box(root, Vector3(0.06, 2.12, 0.14), frame, Vector3(DOOR_X - 0.45, 1.06, fz))
	Kit.box(root, Vector3(0.06, 2.12, 0.14), frame, Vector3(DOOR_X + 0.45, 1.06, fz))
	Kit.box(root, Vector3(0.96, 0.06, 0.14), frame, Vector3(DOOR_X, 2.12, fz))
	door = Node3D.new()
	door.name = "Door"
	door.position = Vector3(DOOR_X - 0.42, 0, fz)
	root.add_child(door)
	var leaf := Kit.mat(Color("1d2a38"), 0.4, 0.4)
	Kit.box(door, Vector3(0.84, 2.06, 0.04), leaf, Vector3(0.42, 1.03, 0))
	Kit.box(door, Vector3(0.6, 1.1, 0.012), Kit.glass(Color(0.8, 0.9, 1.0), 0.05, 0.25), Vector3(0.42, 1.35, 0))
	Kit.cyl(door, 0.012, 0.3, Kit.chrome(), Vector3(0.74, 1.05, -0.05))
	var sign := Label3D.new()
	sign.text = I18n.t("ABERTO")
	sign.font_size = 64
	sign.pixel_size = 0.0012
	sign.modulate = Color(2.2, 0.6, 0.4)
	sign.outline_size = 10
	sign.outline_modulate = Color(1, 0.2, 0.1, 0.7)
	sign.shaded = false
	sign.position = Vector3(0.42, 1.55, -0.03)
	sign.rotation_degrees = Vector3(0, 180, 0)
	door.add_child(sign)
	door_sign = sign
	# street outside the door (simple, lit)
	Kit.box(root, Vector3(3.0, 0.05, 2.0), Kit.pbr("concrete_pbr", 0.9, 0.0, Color("6c6f74"), Vector3(1, 1, 1), true), Vector3(DOOR_X, -0.025, fz + 1.05))
	var street := QuadMesh.new()
	street.size = Vector2(4.0, 3.0)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color("3b4766")
	Kit.mi(root, street, sm, Vector3(DOOR_X, 1.5, fz + 2.0), Vector3(0, 180, 0))
	# doormat
	Kit.slab(root, Vector3(0.8, 0.012, 0.5), 0.02, 0.004, Kit.rubber(Color("2b2f36")), null, null, Vector3(DOOR_X, 0.006, ROOM_FRONT - 0.35))


func open_door() -> void:
	if door == null:
		return
	var t := door.create_tween()
	t.tween_property(door, "rotation:y", deg_to_rad(-80), 0.35)
	t.tween_interval(1.0)
	t.tween_property(door, "rotation:y", 0.0, 0.5)


func ring_bell() -> void:
	if bell == null:
		return
	var t := bell.create_tween()
	t.tween_property(bell, "scale", Vector3(1.1, 0.85, 1.1), 0.06)
	t.tween_property(bell, "scale", Vector3.ONE, 0.12)


## Re-applies translated texts after a language change.
func relabel() -> void:
	if door_sign:
		door_sign.text = I18n.t("ABERTO")
	if tablet_label:
		tablet_label.text = I18n.t("PEDIDOS  [P]")


# -----------------------------------------------------------------------------
# Upgrade props
# -----------------------------------------------------------------------------
var upgrade_nodes: Dictionary = {}


func add_upgrade(id: String) -> void:
	if upgrade_nodes.has(id):
		return
	var n := Node3D.new()
	n.name = "Upgrade_" + id
	root.add_child(n)
	upgrade_nodes[id] = n
	match id:
		"screwdriver":
			# electric screwdriver on a charging dock (bench, back right)
			n.position = Vector3(0.36, BENCH_Y, -1.62)
			Kit.slab(n, Vector3(0.07, 0.025, 0.07), 0.015, 0.008, Kit.plastic(Color("1b1d21"), 0.4), null, null, Vector3(0, 0.0125, 0))
			Kit.cyl(n, 0.017, 0.12, Kit.plastic(Color("f2b316"), 0.35), Vector3(0, 0.085, 0))
			Kit.cyl(n, 0.019, 0.04, Kit.rubber(), Vector3(0, 0.1, 0))
			Kit.cyl(n, 0.003, 0.05, Kit.chrome(), Vector3(0, 0.17, 0))
			Kit.box(n, Vector3(0.012, 0.004, 0.003), Kit.emissive(Color("2ecc71"), 2.0), Vector3(0, 0.02, 0.036))
		"lamp":
			if lamp_light:
				lamp_light.light_color = Color("f4f8ff")
				lamp_light.light_energy = 4.6
			n.position = Vector3(-0.42, 1.38, -1.22)
			Kit.torus(n, 0.07, 0.078, Kit.emissive(Color("eaf4ff"), 4.0, true), Vector3(0, -0.12, 0)).scale = Vector3(1, 0.3, 1)
		"coffee":
			n.position = Vector3(-0.2, COUNTER_TOP, COUNTER_Z - 0.18)
			var m := Kit.mat(Color("2b2f36"), 0.35, 0.6)
			Kit.slab(n, Vector3(0.18, 0.28, 0.22), 0.02, 0.01, m, null, null, Vector3(0, 0.14, 0))
			Kit.slab(n, Vector3(0.14, 0.02, 0.12), 0.01, 0.005, Kit.chrome(), null, null, Vector3(0, 0.01, 0.05))
			Kit.cyl(n, 0.03, 0.06, Kit.plastic(Color("f2efe9"), 0.3), Vector3(0, 0.05, 0.07))
			Kit.box(n, Vector3(0.05, 0.02, 0.01), Kit.emissive(Color("ff8a3c"), 2.0), Vector3(0, 0.24, 0.111))
			Kit.cyl(n, 0.02, 0.03, Kit.chrome(), Vector3(0, 0.1, 0.09))
		"speaker":
			n.position = Vector3(1.25, COUNTER_TOP, COUNTER_Z - 0.2)
			var sp := Kit.fabric(Color("2a2e35"), 0.9, 0.5, 60.0)
			Kit.slab(n, Vector3(0.14, 0.24, 0.13), 0.03, 0.02, sp, null, null, Vector3(0, 0.12, 0), Vector3(0, -25, 0))
			Kit.cyl(n, 0.045, 0.004, Kit.mat(Color("15171a"), 0.5), Vector3(0.0, 0.15, 0.06), Vector3(90, -25, 0))
			Kit.box(n, Vector3(0.08, 0.005, 0.004), Kit.emissive(Color("3aa8ff"), 3.0), Vector3(0.0, 0.03, 0.058))
		"display":
			# glass display cabinet next to the door with repaired gadgets
			n.position = Vector3(-1.9, 0, 2.15)
			var frame := Kit.mat(Color("1d2a38"), 0.4, 0.5)
			Kit.box(n, Vector3(0.9, 0.8, 0.45), frame, Vector3(0, 0.4, 0))
			Kit.box(n, Vector3(0.86, 0.9, 0.41), Kit.glass(Color(0.85, 0.92, 1.0), 0.03, 0.15), Vector3(0, 1.25, 0))
			for y in [0.82, 1.2, 1.6]:
				Kit.box(n, Vector3(0.86, 0.012, 0.41), Kit.glass(Color(0.9, 0.95, 1.0), 0.03, 0.3), Vector3(0, y, 0))
			Kit.box(n, Vector3(0.9, 0.04, 0.45), frame, Vector3(0, 1.72, 0))
			Kit.box(n, Vector3(0.8, 0.01, 0.01), Kit.emissive(Color("fff0d2"), 3.0, true), Vector3(0, 1.69, 0.18))
			Kit.slab(n, Vector3(0.28, 0.015, 0.2), 0.01, 0.004, Kit.aluminium(Color("7a8189"), 0.34), null, null, Vector3(-0.2, 0.84, 0))
			Kit.slab(n, Vector3(0.07, 0.008, 0.14), 0.01, 0.002, Kit.black_glass(), Kit.aluminium(Color("4a5a6e"), 0.22), null, Vector3(0.2, 0.84, 0), Vector3(0, 20, 0))
			Kit.slab(n, Vector3(0.12, 0.024, 0.068), 0.026, 0.008, Kit.plastic(Color("e9ecef"), 0.4), null, null, Vector3(0.0, 1.22, 0))
			Kit.slab(n, Vector3(0.26, 0.17, 0.12), 0.02, 0.01, Kit.pbr("walnut_pbr", 0.4, 0.0, Color("c88f5c"), Vector3(3, 3, 3), true), null, null, Vector3(-0.1, 1.29, 0), Vector3(90, 0, 0))
			var light := OmniLight3D.new()
			light.position = Vector3(0, 1.5, 0.4)
			light.light_color = Color("fff0d2")
			light.light_energy = 0.7
			light.omni_range = 1.4
			n.add_child(light)
		"neon":
			n.position = Vector3(-0.9, 2.15, ROOM_FRONT - 0.03)
			var l := Label3D.new()
			l.text = I18n.t("REPARAÇÕES")
			l.font_size = 120
			l.pixel_size = 0.0011
			l.modulate = Color(2.4, 0.5, 1.6)
			l.outline_modulate = Color(1.0, 0.1, 0.6, 0.85)
			l.outline_size = 18
			l.shaded = false
			l.rotation_degrees = Vector3(0, 180, 0)
			var f := load("res://assets/fonts/Nunito-ExtraBold.ttf")
			if f:
				l.font = f
			n.add_child(l)
			var o := OmniLight3D.new()
			o.light_color = Color("ff4fb3")
			o.light_energy = 1.2
			o.omni_range = 2.0
			o.position = Vector3(0, 0, -0.3)
			n.add_child(o)


func clear_upgrades() -> void:
	for n in upgrade_nodes.values():
		if is_instance_valid(n):
			n.queue_free()
	upgrade_nodes.clear()
	if lamp_light:
		lamp_light.light_color = Color("ffe2b5")
		lamp_light.light_energy = 3.4
