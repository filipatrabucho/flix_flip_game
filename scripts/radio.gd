extends "res://scripts/generic_device.gd"
## 1950s style tube radio in a wooden cabinet (~300 x 190 x 140 mm).
## The back panel is the cover; flipping lays the radio on its face.

const W := 0.30
const H := 0.19
const D := 0.14
const BT := 0.006

var tubes: Array[MeshInstance3D] = []
var tube_glow: Array[StandardMaterial3D] = []
var needle: Node3D


func _init() -> void:
	super._init()
	device_id = "radio"
	display_name = "Rádio antigo"
	name = "Radio"
	rest_y = H * 0.5 + 0.004
	rest_y_flipped = D * 0.5 + 0.018
	body.position = Vector3(0, rest_y, 0)
	flip_rot = Vector3(PI * 0.5, 0, 0)   # back faces up
	screw_axis = Vector3.BACK * -1.0
	_build()


func _build() -> void:
	var wood := Kit.pbr("walnut_pbr", 0.4, 0.0, Color("c88f5c"), Vector3(3, 3, 3), true, 0.5)
	wood.clearcoat_enabled = true
	wood.clearcoat = 0.9
	wood.clearcoat_roughness = 0.15
	var interior := Kit.mat(Color("5a4634"), 0.8)
	# open-backed cabinet: the back face is invisible, the inside is lined in dark wood
	var hidden := StandardMaterial3D.new()
	hidden.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hidden.albedo_color = Color(0, 0, 0, 0)
	var wood2 := wood.duplicate() as StandardMaterial3D
	wood2.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cab := Kit.slab(body, Vector3(W, D - BT, H), 0.02, 0.012, hidden, wood2, wood2, Vector3(0, 0, BT * 0.5), Vector3(-90, 0, 0))
	Kit.box(body, Vector3(W - 0.02, H - 0.02, 0.004), interior, Vector3(0, 0, D * 0.5 - 0.008))
	Kit.box(body, Vector3(0.004, H - 0.02, D - 0.02), interior, Vector3(-W * 0.5 + 0.007, 0, 0.0))
	Kit.box(body, Vector3(0.004, H - 0.02, D - 0.02), interior, Vector3(W * 0.5 - 0.007, 0, 0.0))
	Kit.box(body, Vector3(W - 0.02, 0.004, D - 0.02), interior, Vector3(0, H * 0.5 - 0.007, 0.0))
	Kit.box(body, Vector3(W - 0.02, 0.004, D - 0.02), interior, Vector3(0, -H * 0.5 + 0.007, 0.0))
	cab.name = "Cabinet"
	shell_meshes.append(cab)
	# speaker cloth (left) + dial window (right) + knobs
	var cloth := Kit.fabric(Color("cdbb94"), 0.95, 0.9, 120.0)
	Kit.slab(body, Vector3(0.15, 0.004, 0.13), 0.02, 0.002, cloth, null, null, Vector3(-0.06, 0.01, D * 0.5 + 0.0005), Vector3(90, 0, 0))
	for i in range(5):
		Kit.box(body, Vector3(0.15, 0.004, 0.004), wood, Vector3(-0.06, -0.04 + i * 0.024, D * 0.5 + 0.003))
	var glass := Kit.slab(body, Vector3(0.1, 0.003, 0.05), 0.008, 0.001, Kit.mat(Color("f1e3b6"), 0.3), null, null, Vector3(0.085, 0.045, D * 0.5 + 0.0005), Vector3(90, 0, 0))
	glass.name = "DialGlass"
	for i in range(6):
		label3d(body, str(55 + i * 25), 24, 0.00012, Color("3b2a1c"), Vector3(0.045 + i * 0.016, 0.055, D * 0.5 + 0.0025), Vector3(0, 0, 0))
	needle = Node3D.new()
	needle.position = Vector3(0.06, 0.045, D * 0.5 + 0.0028)
	body.add_child(needle)
	Kit.box(needle, Vector3(0.0012, 0.04, 0.0006), Kit.mat(Color("c0392b"), 0.4), Vector3.ZERO)
	led_mat = Kit.emissive(Color("ffb347"), 0.0)
	Kit.box(body, Vector3(0.095, 0.045, 0.001), led_mat, Vector3(0.085, 0.045, D * 0.5 + 0.0002))
	for kx in [0.06, 0.11]:
		var k := Kit.cyl(body, 0.013, 0.016, Kit.plastic(Color("2b1d14"), 0.3), Vector3(kx, -0.03, D * 0.5 + 0.008), Vector3(90, 0, 0), 0.011)
		k.name = "Knob"
	add_target("power", body, Kit.sphere_shape(0.016), Vector3(0.06, -0.03, D * 0.5 + 0.01), [], 0.017, Vector3(90, 0, 0))
	add_target("tuning", body, Kit.box_shape(Vector3(0.11, 0.06, 0.02)), Vector3(0.085, 0.045, D * 0.5 + 0.005), [glass], 0.0)
	label3d(body, "TELEFUNKO", 36, 0.0005, Color("e8d6a8"), Vector3(-0.06, 0.082, D * 0.5 + 0.003), Vector3.ZERO)
	for sx in [-1.0, 1.0]:
		Kit.cyl(body, 0.008, 0.006, Kit.mat(Color("2b1d14"), 0.5), Vector3(sx * 0.12, -H * 0.5 - 0.003, 0.04))
		Kit.cyl(body, 0.008, 0.006, Kit.mat(Color("2b1d14"), 0.5), Vector3(sx * 0.12, -H * 0.5 - 0.003, -0.04))
	# back panel (hardboard) with 4 screws, facing -Z
	cover = Node3D.new()
	cover.name = "Cover"
	body.add_child(cover)
	var board := Kit.mat(Color("6b5136"), 0.85)
	var bp := Kit.slab(cover, Vector3(W - 0.02, BT, H - 0.02), 0.012, 0.0015, board, board, board, Vector3(0, 0, -D * 0.5 + BT * 0.5), Vector3(-90, 0, 0))
	bp.name = "BackPanel"
	shell_meshes.append(bp)
	for i in range(12):
		Kit.cyl(cover, 0.004, 0.002, Kit.mat(Color("1a120c"), 0.9), Vector3(-0.1 + i * 0.018, 0.06, -D * 0.5 - 0.0005), Vector3(90, 0, 0))
	add_target("cover", cover, Kit.box_shape(Vector3(W * 0.85, H * 0.8, BT + 0.004)), Vector3(0, 0, -D * 0.5 + BT * 0.5), [bp], 0.0)
	var zb := -D * 0.5 - 0.00002
	build_screws(cover, [Vector3(-0.13, 0.08, zb), Vector3(0.13, 0.08, zb), Vector3(-0.13, -0.08, zb), Vector3(0.13, -0.08, zb)], 0.0028, Vector3(-90, 0, 0), Color("8a7d6b"), 0.009)
	cover_lift = Vector3(0, 0, -0.03)
	# chassis inside: tubes (one replaceable), capacitors, transformer, speaker magnet
	var zi := -D * 0.5 + BT
	var chassis := Kit.mat(Color("8d9298"), 0.35, 0.85)
	Kit.box(body, Vector3(0.24, 0.004, 0.08), chassis, Vector3(0.0, -0.06, zi + 0.04))
	for i in range(4):
		var holder := Node3D.new()
		holder.position = Vector3(-0.07 + i * 0.045, -0.058, zi + 0.04)
		body.add_child(holder)
		var glow := Kit.emissive(Color("ff8a3c"), 0.0)
		var g := Kit.glass(Color(0.85, 0.85, 0.9), 0.05, 0.35)
		var tube := Kit.lathe(holder, [Vector3(0.0, 0.011, 0.011), Vector3(0.04, 0.011, 0.011), Vector3(0.05, 0.008, 0.008), Vector3(0.055, 0.0, 0.0)], g, Vector3.ZERO, Vector3.ZERO, 20)
		Kit.cyl(holder, 0.006, 0.03, glow, Vector3(0, 0.022, 0))
		Kit.cyl(holder, 0.012, 0.006, Kit.plastic(Color("1b1b1b"), 0.5), Vector3(0, 0.003, 0))
		tubes.append(tube)
		tube_glow.append(glow)
		if i == 2:
			holder.name = "RadioTube"
			register_part("radio_tube", holder, Vector3(0.03, 0.06, 0.03), Vector3(0, 0.03, 0))
	for i in range(3):
		Kit.cyl(body, 0.009, 0.03, Kit.plastic([Color("2f6fd6"), Color("c0392b"), Color("e1b12c")][i], 0.4), Vector3(0.1, -0.05 + i * 0.022, zi + 0.02), Vector3(0, 0, 90))
	Kit.box(body, Vector3(0.045, 0.04, 0.035), Kit.mat(Color("3a3f45"), 0.4, 0.7), Vector3(-0.11, -0.04, zi + 0.025))
	Kit.cyl(body, 0.035, 0.02, Kit.mat(Color("2c2c2c"), 0.5, 0.6), Vector3(-0.06, 0.01, zi + 0.04), Vector3(90, 0, 0))
	make_dust(body, Vector3(0.085, 0.045, zi + 0.004), 0.035, Vector3(-90, 0, 0))
	add_target("chassis", body, Kit.box_shape(Vector3(0.12, 0.08, 0.02)), Vector3(0.085, 0.045, zi + 0.01), [], 0.036, Vector3(-90, 0, 0))
	make_surface(Vector3(W, H, D))


func set_tubes(on: bool, broken_index := -1) -> void:
	for i in range(tube_glow.size()):
		tube_glow[i].emission_energy_multiplier = 3.0 if on and i != broken_index else 0.0
	set_led(on, Color("ffb347"))


func tune() -> void:
	var t := tw()
	t.tween_property(needle, "position:x", 0.11, 0.6)
	t.tween_property(needle, "position:x", 0.075, 0.5)


func view_transform(view: String) -> Transform3D:
	match view:
		"front":
			return _view(Vector3(0, 0.0, 0.05), Vector3(0.03, 0.12, 0.48))
		"bottom", "interior":
			return _view(Vector3(0, 0.0, -0.0), Vector3(0.03, 0.45, 0.25)) if flipped else _view(Vector3(0, 0, 0), Vector3(0.0, 0.2, -0.45))
	return _view(Vector3.ZERO, Vector3(0, 0.3, 0.45))
