extends "res://scripts/device_base.gd"
## 14" aluminium ultrabook at real scale (312 x 221 x 18 mm).
## Body frame: origin = centre of the closed laptop, +Z = front edge, +Y = keyboard side.

const W := 0.312
const D := 0.221
const TB := 0.0125          # base (chassis + bottom cover)
const TL := 0.0055          # lid
const H := TB + TL
const FEET := 0.0015
const CT := 0.0042          # bottom cover depth (interior space)

var chassis: MeshInstance3D
var cover: Node3D
var cover_mesh: MeshInstance3D
var lid_pivot: Node3D
var lid_mesh: MeshInstance3D
var screen_mat: StandardMaterial3D
var screen_vp: SubViewport
var screen_state := "off"
var screws: Array[Node3D] = []
var screw_local: Array[Vector3] = []
var battery: Node3D
var new_battery: Node3D
var fan_dust: MeshInstance3D
var fan_blades: Node3D
var dust_level := 1.0
var flipped := false
var lid_angle := 0.0
var _boot_screen: Control
var _desk_screen: Control
var _dead_screen: Control

var y_top := -H * 0.5 + TB        # top of the base (deck)
var y_bot := -H * 0.5             # bottom of the cover
var y_inner := -H * 0.5 + CT      # chassis bottom face (interior floor)


func _init() -> void:
	super._init()
	device_id = "laptop"
	display_name = "Portátil"
	name = "Laptop"
	body.position = Vector3(0, H * 0.5 + FEET, 0)
	_build()


func _build() -> void:
	var alu := Kit.aluminium(Color("7a8189"), 0.34)
	var alu_dark := Kit.aluminium(Color("6f767e"), 0.38)
	var interior := Kit.plastic(Color("2b2f34"), 0.6, 0.2)
	# --- chassis (top shell)
	chassis = Kit.slab(body, Vector3(W, TB - CT, D), 0.011, 0.0024, alu, alu, interior, Vector3(0, y_top - (TB - CT) * 0.5, 0))
	chassis.name = "Chassis"
	shell_meshes.append(chassis)
	# keyboard well + keys
	var well := Kit.slab(body, Vector3(0.276, 0.0004, 0.112), 0.004, 0.0002, Kit.plastic(Color("17191c"), 0.6), null, null, Vector3(0, y_top + 0.0001, -0.045))
	well.name = "KeyboardWell"
	_build_keyboard()
	# trackpad
	var pad_mat := Kit.aluminium(Color("9aa1a9"), 0.22)
	pad_mat.anisotropy = 0.0
	var pad := Kit.slab(body, Vector3(0.124, 0.0005, 0.078), 0.006, 0.0002, pad_mat, null, null, Vector3(0, y_top + 0.00015, 0.062))
	shell_meshes.append(pad)
	# speaker grilles either side of the keyboard
	var hole := Kit.mat(Color("101113"), 0.7)
	for sx in [-1.0, 1.0]:
		for r in range(18):
			for c in range(2):
				Kit.cyl(body, 0.00045, 0.0003, hole, Vector3(sx * (0.143 + c * 0.0022), y_top + 0.00005, -0.095 + r * 0.0058), Vector3.ZERO, -1.0, 6)
	# ports (left side): 2x USB-C + audio; (right side): USB-A + card slot
	var port_mat := Kit.mat(Color("0c0d0f"), 0.5)
	var port_ring := Kit.mat(Color("3a3e44"), 0.3, 0.7)
	var p1 := Kit.slab(body, Vector3(0.0088, 0.0001, 0.0032), 0.0015, 0.00004, port_mat, null, null, Vector3(-W * 0.5 - 0.00002, y_top - 0.004, -0.050), Vector3(0, 0, 90))
	p1.rotation_degrees = Vector3(90, 90, 0)
	var p2 := Kit.slab(body, Vector3(0.0088, 0.0001, 0.0032), 0.0015, 0.00004, port_mat, null, null, Vector3(-W * 0.5 - 0.00002, y_top - 0.004, -0.032))
	p2.rotation_degrees = Vector3(90, 90, 0)
	Kit.cyl(body, 0.0018, 0.0002, port_mat, Vector3(-W * 0.5 - 0.00002, y_top - 0.004, 0.040), Vector3(0, 0, 90))
	Kit.cyl(body, 0.0024, 0.0001, port_ring, Vector3(-W * 0.5 - 0.00001, y_top - 0.004, 0.040), Vector3(0, 0, 90))
	var usba := Kit.slab(body, Vector3(0.0125, 0.0001, 0.0045), 0.0005, 0.00004, port_mat, null, null, Vector3(W * 0.5 + 0.00002, y_top - 0.0042, -0.040))
	usba.rotation_degrees = Vector3(90, 90, 0)
	Kit.box(body, Vector3(0.0002, 0.0012, 0.009), Kit.mat(Color("2196f3"), 0.4), Vector3(W * 0.5 + 0.00003, y_top - 0.0046, -0.040))
	# status LED on the front lip
	var led := Kit.emissive(Color("ffffff"), 0.0)
	Kit.box(body, Vector3(0.002, 0.0006, 0.0002), led, Vector3(0.07, y_top - 0.004, D * 0.5 + 0.00005)).name = "ChargeLED"
	var port_target := add_target("port", body, Kit.box_shape(Vector3(0.006, 0.008, 0.016)), Vector3(-W * 0.5 - 0.001, y_top - 0.004, -0.041), [p1, p2], 0.0)
	port_target.name = "PortTarget"

	# --- hinge + lid
	var hinge_mat := Kit.mat(Color("2a2d31"), 0.35, 0.6)
	Kit.cyl(body, 0.0032, 0.25, hinge_mat, Vector3(0, y_top + 0.0005, -D * 0.5 + 0.004), Vector3(0, 0, 90))
	lid_pivot = Node3D.new()
	lid_pivot.name = "LidPivot"
	lid_pivot.position = Vector3(0, y_top, -D * 0.5 + 0.0035)
	body.add_child(lid_pivot)
	var bezel := Kit.black_glass()
	lid_mesh = Kit.slab(lid_pivot, Vector3(W, TL, D - 0.002), 0.011, 0.0022, alu, alu, bezel, Vector3(0, TL * 0.5, (D - 0.002) * 0.5 - 0.0025))
	lid_mesh.name = "Lid"
	shell_meshes.append(lid_mesh)
	# logo on the lid
	var logo_mat := Kit.chrome(Color("c7ccd2"))
	Kit.cyl(lid_pivot, 0.010, 0.0002, logo_mat, Vector3(0, TL + 0.00005, D * 0.5 - 0.004))
	# screen (inner face of the lid = -Y in lid space)
	screen_vp = _build_screen_viewport()
	screen_mat = _screen_material()
	var screen := PlaneMesh.new()
	screen.size = Vector2(0.288, 0.180)
	Kit.mi(lid_pivot, screen, screen_mat, Vector3(0, -0.00006, D * 0.5 + 0.004), Vector3(180, 0, 0)).name = "Screen"
	Kit.cyl(lid_pivot, 0.0011, 0.0002, Kit.mat(Color("1b2733"), 0.1, 0.3), Vector3(0, -0.00008, D - 0.012), Vector3(180, 0, 0)).name = "Webcam"
	label3d(lid_pivot, "FIXBOOK", 32, 0.00012, Color("8b9096"), Vector3(0, -0.00008, 0.0055), Vector3(90, 180, 0))
	var lid_t := add_target("lid", lid_pivot, Kit.box_shape(Vector3(W, 0.008, D)), Vector3(0, TL * 0.5, D * 0.5 - 0.002), [lid_mesh], 0.0)
	lid_t.name = "LidTarget"

	# --- bottom cover + feet + vents + screws
	cover = Node3D.new()
	cover.name = "Cover"
	body.add_child(cover)
	cover_mesh = Kit.slab(cover, Vector3(W - 0.0006, CT, D - 0.0006), 0.0108, 0.0013, interior, alu, alu_dark, Vector3(0, y_bot + CT * 0.5, 0))
	cover_mesh.name = "CoverPlate"
	shell_meshes.append(cover_mesh)
	var rubber := Kit.rubber()
	for z in [-0.088, 0.088]:
		var foot := Kit.slab(cover, Vector3(0.21, FEET + 0.0002, 0.0075), 0.0035, 0.0007, rubber, null, null, Vector3(0, y_bot - FEET * 0.5 + 0.0001, z))
		foot.name = "Foot"
	var slot := Kit.mat(Color("0d0e10"), 0.8)
	for i in range(34):
		Kit.slab(cover, Vector3(0.0022, 0.0003, 0.030), 0.0009, 0.0001, slot, null, null, Vector3(-0.07 + i * 0.0042, y_bot - 0.00002, -0.060))
	label3d(cover, "FIXBOOK 14  •  Modelo FX-1402  •  20V DC 3.25A  •  Made for Fix & Flip Tech", 26, 0.0001, Color("4c5258"), Vector3(0, y_bot - 0.00003, 0.050), Vector3(90, 180, 0))
	var cover_t := add_target("cover", cover, Kit.box_shape(Vector3(W * 0.9, CT + 0.001, D * 0.9)), Vector3(0, y_bot + CT * 0.5, 0), [cover_mesh], 0.0)
	cover_t.name = "CoverTarget"
	var spots := [Vector3(-0.140, 0, -0.094), Vector3(0.140, 0, -0.094), Vector3(-0.140, 0, 0.094), Vector3(0.140, 0, 0.094)]
	for i in range(spots.size()):
		var p: Vector3 = spots[i]
		p.y = y_bot - 0.00002
		var s := screw_head(cover, 0.0021, p, Vector3(180, 0, 0))
		s.name = "Screw%d" % i
		screws.append(s)
		screw_local.append(p)
		add_target("screw%d" % i, cover, Kit.sphere_shape(0.006), p, [s.get_meta("head_mesh")], 0.0075, Vector3(180, 0, 0))

	_build_interior()
	make_surface(Vector3(W, H, D), Vector3(0, 0, 0))
	_set_screen("off")


func _ready() -> void:
	screen_mat.albedo_texture = screen_vp.get_texture()


func _build_keyboard() -> void:
	var key_mat := Kit.plastic(Color("141619"), 0.78, 0.12)
	key_mat.metallic_specular = 0.25
	var u := 0.0188
	var gap := 0.0026
	var rows := [
		[0.5, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.5]],
		[1.0, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.5]],
		[1.0, [1.5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.0]],
		[1.0, [1.8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.7]],
		[1.0, [2.3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2.2]],
		[1.0, [1, 1, 1, 1.25, 5.0, 1.25, 1, 1, 1, 1]],
	]
	var z := -0.0975
	var mesh_cache := {}
	for ri in range(rows.size()):
		var row: Array = rows[ri]
		var h: float = row[0]
		var widths: Array = row[1]
		var key_d := h * u - gap
		var x := -0.1363
		for wi in range(widths.size()):
			var wu: float = widths[wi]
			var key_w := wu * u - gap
			var key_key := "%0.4f_%0.4f" % [key_w, key_d]
			if not mesh_cache.has(key_key):
				mesh_cache[key_key] = Kit.slab_mesh(Vector3(key_w, 0.0011, key_d), 0.0016, 0.0005, 3, 2)
			var k := Kit.mi(body, mesh_cache[key_key], key_mat, Vector3(x + wu * u * 0.5, y_top + 0.00075, z + h * u * 0.5))
			if ri == 0 and wi == widths.size() - 1:
				k.name = "PowerKey"
				var ring := Kit.mat(Color("2c3036"), 0.25, 0.5)
				k.material_override = ring
				add_target("power", body, Kit.box_shape(Vector3(key_w + 0.004, 0.006, key_d + 0.004)), k.position, [k], 0.0)
			x += wu * u
		z += h * u
	# a few legends make the keyboard read instantly
	var legend_color := Color("c9cdd2")
	var letters := "QWERTYUIOP"
	for i in range(letters.length()):
		label3d(body, letters[i], 40, 0.00009, legend_color, Vector3(-0.1363 + 1.5 * u + i * u + u * 0.5, y_top + 0.00135, -0.0975 + 0.5 * u + u + u * 0.5))
	var letters2 := "ASDFGHJKL"
	for i in range(letters2.length()):
		label3d(body, letters2[i], 40, 0.00009, legend_color, Vector3(-0.1363 + 1.8 * u + i * u + u * 0.5, y_top + 0.00135, -0.0975 + 0.5 * u + 2 * u + u * 0.5))
	var letters3 := "ZXCVBNM"
	for i in range(letters3.length()):
		label3d(body, letters3[i], 40, 0.00009, legend_color, Vector3(-0.1363 + 2.3 * u + i * u + u * 0.5, y_top + 0.00135, -0.0975 + 0.5 * u + 3 * u + u * 0.5))
	var digits := "1234567890"
	for i in range(digits.length()):
		label3d(body, digits[i], 34, 0.00009, legend_color, Vector3(-0.1363 + u + i * u + u * 0.5, y_top + 0.00135, -0.0975 + 0.5 * u + u * 0.5))
	var pw := Vector3(-0.1363 + 13 * u + 0.75 * u, y_top + 0.0014, -0.0975 + 0.25 * u)
	var icon_mat := Kit.emissive(Color("dfe6ec"), 0.3)
	Kit.torus(body, 0.0016, 0.0021, icon_mat, pw)
	Kit.box(body, Vector3(0.0005, 0.0002, 0.0022), icon_mat, pw + Vector3(0, 0.0001, -0.0012))


func _build_interior() -> void:
	# everything is attached to the chassis floor and faces -Y (visible when flipped + cover off)
	var yi := y_inner
	var pcb := Kit.plastic(Color("142a1d"), 0.45, 0.2)
	var chip := Kit.plastic(Color("101214"), 0.35, 0.1)
	var copper := Kit.mat(Color("c47a3a"), 0.28, 1.0)
	# rim walls (the chassis tray)
	var rim := Kit.aluminium(Color("7d848c"), 0.4)
	Kit.box(body, Vector3(W - 0.012, 0.0016, 0.002), rim, Vector3(0, yi - 0.0008, -D * 0.5 + 0.006))
	Kit.box(body, Vector3(W - 0.012, 0.0016, 0.002), rim, Vector3(0, yi - 0.0008, D * 0.5 - 0.006))
	# motherboard
	Kit.slab(body, Vector3(0.205, 0.0012, 0.088), 0.004, 0.0003, pcb, null, pcb, Vector3(0.03, yi - 0.0006, -0.052))
	for c in [[Vector3(0.055, 0, -0.06), Vector3(0.028, 0.0014, 0.028)], [Vector3(0.0, 0, -0.04), Vector3(0.014, 0.001, 0.014)], [Vector3(0.1, 0, -0.03), Vector3(0.02, 0.0012, 0.012)], [Vector3(0.115, 0, -0.075), Vector3(0.012, 0.001, 0.02)]]:
		var cp: Vector3 = c[0]
		var cs: Vector3 = c[1]
		Kit.slab(body, cs, 0.0008, 0.0002, chip, null, chip, Vector3(cp.x, yi - 0.0012 - cs.y * 0.5, cp.z))
	# RAM + SSD
	var ram := Kit.slab(body, Vector3(0.067, 0.001, 0.030), 0.001, 0.0002, Kit.plastic(Color("1c4b2f"), 0.45), null, Kit.plastic(Color("1c4b2f"), 0.45), Vector3(0.10, yi - 0.0018, -0.068))
	ram.name = "RAM"
	for i in range(4):
		Kit.box(body, Vector3(0.010, 0.0005, 0.008), chip, Vector3(0.078 + i * 0.015, yi - 0.0024, -0.068))
	var ssd := Kit.slab(body, Vector3(0.080, 0.0012, 0.022), 0.001, 0.0002, Kit.plastic(Color("0f1012"), 0.4), null, Kit.plastic(Color("0f1012"), 0.4), Vector3(-0.01, yi - 0.0018, -0.085))
	ssd.name = "SSD"
	label3d(body, "NVMe 512GB", 28, 0.00011, Color("d8dde2"), Vector3(-0.01, yi - 0.0025, -0.085), Vector3(90, 180, 0))
	# fan + heatpipe
	var fan_c := Vector3(-0.098, yi, -0.058)
	Kit.cyl(body, 0.034, 0.0016, Kit.plastic(Color("1a1c1f"), 0.5), fan_c + Vector3(0, -0.0008, 0))
	fan_blades = Node3D.new()
	fan_blades.position = fan_c + Vector3(0, -0.0018, 0)
	body.add_child(fan_blades)
	var blade_mat := Kit.plastic(Color("2a2d31"), 0.45)
	Kit.cyl(fan_blades, 0.011, 0.0012, Kit.plastic(Color("202226"), 0.4), Vector3.ZERO)
	for i in range(11):
		Kit.box(fan_blades, Vector3(0.019, 0.0006, 0.004), blade_mat, Vector3(cos(TAU * i / 11.0) * 0.02, 0, sin(TAU * i / 11.0) * 0.02), Vector3(18, -rad_to_deg(TAU * i / 11.0), 0))
	var fan_ring := Kit.torus(body, 0.031, 0.035, Kit.plastic(Color("17181b"), 0.5), fan_c + Vector3(0, -0.0012, 0))
	fan_ring.scale = Vector3(1, 0.4, 1)
	var dust_mat := Kit.fabric(Color("8f877a"), 1.0, 1.0, 90.0)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.albedo_color = Color(0.56, 0.53, 0.48, 0.92)
	fan_dust = Kit.cyl(body, 0.033, 0.0006, dust_mat, fan_c + Vector3(0, -0.0027, 0))
	fan_dust.name = "Dust"
	for i in range(14):
		var a := randf() * TAU
		var r := randf_range(0.01, 0.034)
		var fluff := Kit.sphere(fan_dust, 0.0026, dust_mat, Vector3(cos(a) * r, -0.0004, sin(a) * r), Vector3(1.6, 0.35, 1.0))
		fluff.rotation.y = randf() * TAU
	Kit.mi(body, Kit.tube_mesh(Kit.bezier(fan_c + Vector3(0.02, -0.0018, -0.025), fan_c + Vector3(0.07, -0.0018, -0.03), Vector3(0.03, yi - 0.0018, -0.07), Vector3(0.055, yi - 0.0018, -0.06), 14), 0.0013, 10), copper)
	add_target("fan", body, Kit.box_shape(Vector3(0.075, 0.008, 0.075)), fan_c + Vector3(0, -0.002, 0), [fan_dust], 0.036)
	# battery (old one, swollen-looking label)
	battery = _battery_model(true)
	battery.position = Vector3(0, yi, 0.050)
	body.add_child(battery)
	add_target("battery", battery, Kit.box_shape(Vector3(0.24, 0.008, 0.08)), Vector3(0, -0.002, 0), battery.get_meta("meshes"), 0.0)
	# speakers
	for sx in [-0.135, 0.135]:
		Kit.slab(body, Vector3(0.022, 0.0016, 0.05), 0.003, 0.0004, chip, null, chip, Vector3(sx, yi - 0.0008, 0.06))


## Battery pack, built facing -Y (label side down) so it reads correctly when flipped.
func _battery_model(old: bool) -> Node3D:
	var n := Node3D.new()
	n.name = "Battery" if old else "NewBattery"
	var wrap := Kit.plastic(Color("17181a") if old else Color("1d2025"), 0.55, 0.15)
	var cells: Array = []
	for i in range(3):
		var c := Kit.slab(n, Vector3(0.074, 0.0034, 0.070), 0.006, 0.0014, wrap, wrap, wrap, Vector3(-0.08 + i * 0.08, -0.0017, 0))
		if old:
			c.scale = Vector3(1, 1.04 + 0.05 * float(i == 1), 1)
		cells.append(c)
	var label_mat := Kit.plastic(Color("e9ecef") if not old else Color("cfd3d6"), 0.5)
	var label := Kit.slab(n, Vector3(0.12, 0.0002, 0.042), 0.002, 0.0001, label_mat, null, label_mat, Vector3(0, -0.0036 if not old else -0.0038, 0))
	cells.append(label)
	label3d(n, "Li-ion 11.55V  52.6Wh", 30, 0.00013, Color("1d2227"), Vector3(0, label.position.y - 0.00015, -0.008), Vector3(90, 180, 0))
	label3d(n, "SUBSTITUIR" if old else "NOVA  •  4500 mAh", 28, 0.00012, Color("c0392b") if old else Color("1f8a4c"), Vector3(0, label.position.y - 0.00015, 0.009), Vector3(90, 180, 0))
	# connector + cable
	Kit.box(n, Vector3(0.016, 0.0018, 0.008), Kit.plastic(Color("efefef"), 0.5), Vector3(0.02, -0.0012, -0.040))
	n.set_meta("meshes", cells)
	return n


func _build_screen_viewport() -> SubViewport:
	var vp := Kit.text_viewport(self, Vector2i(640, 400), func(root: Control) -> void:
		var bg := ColorRect.new()
		bg.color = Color.BLACK
		bg.size = Vector2(640, 400)
		root.add_child(bg)
		_dead_screen = Control.new()
		_dead_screen.size = Vector2(640, 400)
		root.add_child(_dead_screen)
		var bat := Label.new()
		bat.text = "BATERIA 0%  -  Ligue o carregador"
		bat.position = Vector2(120, 180)
		bat.add_theme_font_size_override("font_size", 28)
		bat.add_theme_color_override("font_color", Color("e74c3c"))
		_dead_screen.add_child(bat)
		_boot_screen = Control.new()
		_boot_screen.size = Vector2(640, 400)
		root.add_child(_boot_screen)
		var logo := Label.new()
		logo.text = "FIX & FLIP"
		logo.position = Vector2(205, 150)
		logo.add_theme_font_size_override("font_size", 48)
		logo.add_theme_color_override("font_color", Color("5ec8ff"))
		_boot_screen.add_child(logo)
		var dots := Label.new()
		dots.text = "• • •"
		dots.position = Vector2(290, 230)
		dots.add_theme_font_size_override("font_size", 28)
		dots.add_theme_color_override("font_color", Color("cfe9ff"))
		_boot_screen.add_child(dots)
		_desk_screen = Control.new()
		_desk_screen.size = Vector2(640, 400)
		root.add_child(_desk_screen)
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color("0b2a6f"), Color("1673d6"), Color("4fc3f7")])
		grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.75, 0.9)
		gt.fill_to = Vector2(-0.2, -0.3)
		gt.width = 320
		gt.height = 200
		var wall := TextureRect.new()
		wall.texture = gt
		wall.size = Vector2(640, 400)
		wall.stretch_mode = TextureRect.STRETCH_SCALE
		wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_desk_screen.add_child(wall)
		var badge := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.16)
		sb.set_corner_radius_all(48)
		sb.border_color = Color(1, 1, 1, 0.7)
		sb.set_border_width_all(4)
		badge.add_theme_stylebox_override("panel", sb)
		badge.position = Vector2(272, 112)
		badge.size = Vector2(96, 96)
		_desk_screen.add_child(badge)
		var ff := Label.new()
		ff.text = "F&F"
		ff.position = Vector2(286, 138)
		ff.add_theme_font_size_override("font_size", 34)
		ff.add_theme_color_override("font_color", Color.WHITE)
		_desk_screen.add_child(ff)
		var title := Label.new()
		title.text = "Fix & Flip OS"
		title.position = Vector2(225, 230)
		title.add_theme_font_size_override("font_size", 34)
		title.add_theme_color_override("font_color", Color.WHITE)
		_desk_screen.add_child(title)
		var bar := ColorRect.new()
		bar.color = Color(0.03, 0.06, 0.12, 0.75)
		bar.position = Vector2(0, 372)
		bar.size = Vector2(640, 28)
		_desk_screen.add_child(bar)
		var clock := Label.new()
		clock.text = "08:00    100%"
		clock.position = Vector2(500, 374)
		clock.add_theme_font_size_override("font_size", 16)
		clock.add_theme_color_override("font_color", Color.WHITE)
		_desk_screen.add_child(clock)
	, false)
	return vp


func _set_screen(state: String) -> void:
	screen_state = state
	if _boot_screen == null:
		return
	_dead_screen.visible = state == "dead"
	_boot_screen.visible = state == "boot"
	_desk_screen.visible = state == "on"
	var scr := lid_pivot.get_node_or_null("Screen") as Node3D
	if scr:
		scr.visible = state != "off"
	var led: MeshInstance3D = body.get_node_or_null("ChargeLED")
	if led:
		var m := led.material_override as StandardMaterial3D
		m.emission_energy_multiplier = 2.5 if state == "on" else 0.0


# --- actions -----------------------------------------------------------------
func set_lid(angle_deg: float, duration := 0.8) -> Tween:
	lid_angle = angle_deg
	var t := tw()
	t.tween_property(lid_pivot, "rotation:x", -deg_to_rad(angle_deg), duration)
	return t


func flip(to_bottom: bool, duration := 1.1) -> Tween:
	flipped = to_bottom
	var t := tw()
	var base_y := H * 0.5 + (0.0 if to_bottom else FEET)
	t.tween_property(body, "position:y", 0.09, duration * 0.45)
	t.parallel().tween_property(body, "rotation:z", PI if to_bottom else 0.0, duration)
	t.tween_property(body, "position:y", base_y, duration * 0.4)
	return t


func press_power(works: bool) -> void:
	var key: Node3D = body.get_node("PowerKey")
	var t := tw()
	t.tween_property(key, "position:y", key.position.y - 0.0006, 0.08)
	t.tween_property(key, "position:y", key.position.y, 0.12)
	if works:
		_set_screen("boot")
		get_tree().create_timer(1.4).timeout.connect(func() -> void: _set_screen("on"))
	else:
		_set_screen("off")


func show_dead_battery() -> void:
	_set_screen("dead")
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		if screen_state == "dead":
			_set_screen("off"))


func unscrew(index: int, tray_global: Vector3) -> Tween:
	return anim_unscrew(screws[index], tray_global, Vector3.DOWN)


func screw_in(index: int) -> Tween:
	return anim_screw_in(screws[index], cover, screw_local[index], Vector3(180, 0, 0), Vector3.DOWN)


## Lift the cover and put it on the mat beside the laptop (aside_global).
func remove_cover(aside_global: Vector3) -> Tween:
	var t := tw()
	var start_gt := cover.global_transform
	t.tween_property(cover, "position:y", -0.03, 0.45)
	t.tween_callback(func() -> void:
		var gt := cover.global_transform
		body.remove_child(cover)
		add_child(cover)
		cover.global_transform = gt)
	t.tween_property(cover, "global_position", aside_global, 0.7)
	cover.set_meta("home", start_gt)
	return t


func replace_cover() -> Tween:
	var t := tw()
	t.tween_property(cover, "global_position", body.global_transform * Vector3(0, -0.03, 0), 0.6)
	t.tween_callback(func() -> void:
		var gt := cover.global_transform
		remove_child(cover)
		body.add_child(cover)
		cover.global_transform = gt
		cover.rotation = Vector3.ZERO)
	t.tween_property(cover, "position", Vector3.ZERO, 0.4)
	return t


func clean_fan() -> bool:
	dust_level = maxf(0.0, dust_level - 0.34)
	var m := fan_dust.material_override as StandardMaterial3D
	var t := tw()
	t.tween_property(fan_dust, "scale", Vector3.ONE * (0.5 + dust_level * 0.5), 0.25)
	m.albedo_color.a = 0.92 * dust_level
	for c in fan_dust.get_children():
		(c as Node3D).visible = randf() < dust_level
	var spin := tw()
	spin.tween_property(fan_blades, "rotation:y", fan_blades.rotation.y + TAU * 2.0, 0.6)
	if dust_level <= 0.01:
		fan_dust.visible = false
		return true
	return false


func remove_battery(aside_global: Vector3) -> Tween:
	var t := tw()
	t.tween_property(battery, "position:y", battery.position.y - 0.025, 0.45)
	t.tween_callback(func() -> void:
		var gt := battery.global_transform
		body.remove_child(battery)
		add_child(battery)
		battery.global_transform = gt)
	t.tween_property(battery, "global_position", aside_global, 0.6)
	t.tween_property(battery, "scale", Vector3(0.001, 0.001, 0.001), 0.3)
	t.tween_callback(func() -> void: battery.visible = false)
	return t


## Spawn the boxed replacement battery on the mat (returns its target body).
func spawn_new_battery(global_pos: Vector3) -> void:
	new_battery = _battery_model(false)
	add_child(new_battery)
	new_battery.global_position = global_pos + Vector3(0, 0.0045, 0)
	new_battery.rotation_degrees = Vector3(180, 12, 0)
	add_target("new_battery", new_battery, Kit.box_shape(Vector3(0.24, 0.01, 0.08)), Vector3(0, -0.002, 0), new_battery.get_meta("meshes"), 0.0)


func install_new_battery() -> Tween:
	var t := tw()
	var final_local := Vector3(0, y_inner, 0.050)
	t.tween_property(new_battery, "global_position", body.global_transform * (final_local + Vector3(0, -0.03, 0)), 0.6)
	t.parallel().tween_property(new_battery, "global_rotation", body.global_rotation, 0.6)
	t.tween_callback(func() -> void:
		var gt := new_battery.global_transform
		remove_child(new_battery)
		body.add_child(new_battery)
		new_battery.global_transform = gt)
	t.tween_property(new_battery, "position", final_local, 0.45)
	t.parallel().tween_property(new_battery, "rotation", Vector3.ZERO, 0.45)
	return t


# --- camera views -------------------------------------------------------------
func view_transform(view: String) -> Transform3D:
	match view:
		"overview":
			return _view(Vector3(0, 0.03, -0.01), Vector3(0.0, 0.33, 0.36))
		"front_open":
			return _view(Vector3(0, 0.06, -0.04), Vector3(0.0, 0.26, 0.33))
		"left_side":
			return _view(Vector3(-0.150, 0.0, -0.035), Vector3(-0.43, 0.13, 0.07))
		"bottom":
			return _view(Vector3(0.0, 0.0, 0.01), Vector3(0.05, 0.40, 0.28))
		"interior":
			return _view(Vector3(0.0, 0.0, -0.01), Vector3(0.02, 0.40, 0.26))
	return _view(Vector3.ZERO, Vector3(0, 0.3, 0.3))
