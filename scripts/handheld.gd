extends "res://scripts/generic_device.gd"
## Handheld game console (~170 x 23 x 74 mm), generic design with a wide screen.

const W := 0.17
const H := 0.022
const D := 0.074
const CT := 0.004


func _init() -> void:
	super._init()
	device_id = "handheld"
	display_name = "Consola portátil"
	name = "Handheld"
	rest_y = H * 0.5 + 0.001
	rest_y_flipped = H * 0.5 + 0.001
	body.position = Vector3(0, rest_y, 0)
	_build()


func _build() -> void:
	var shell := Kit.plastic(Color("1c1e22"), 0.22, 0.08)
	shell.clearcoat_enabled = true
	shell.clearcoat = 0.9
	var interior := Kit.plastic(Color("2a2d31"), 0.6, 0.2)
	var front := Kit.slab(body, Vector3(W, H - CT, D), 0.03, 0.007, shell, shell, interior, Vector3(0, CT * 0.5, 0), Vector3.ZERO, 10, 3)
	front.name = "Front"
	shell_meshes.append(front)
	# screen + bezel
	var top := H * 0.5
	Kit.slab(body, Vector3(0.1, 0.0006, 0.058), 0.003, 0.0002, Kit.black_glass(), null, null, Vector3(0, top + 0.0002, -0.002))
	screen_label = label3d(body, "", 34, 0.00016, Color.WHITE, Vector3(0, top + 0.0006, -0.002))
	screen_label.shaded = false
	screen_label.visible = false
	# d-pad (left) + face buttons (right) + analog nub + start/select
	var dp := Kit.plastic(Color("2b2e33"), 0.4)
	Kit.slab(body, Vector3(0.0055, 0.002, 0.017), 0.001, 0.0006, dp, null, null, Vector3(-0.066, top + 0.0008, -0.01))
	Kit.slab(body, Vector3(0.017, 0.002, 0.0055), 0.001, 0.0006, dp, null, null, Vector3(-0.066, top + 0.0008, -0.01))
	Kit.cyl(body, 0.0055, 0.002, Kit.rubber(Color("3a3d42")), Vector3(-0.066, top + 0.0008, 0.018))
	var buttons := Node3D.new()
	buttons.name = "Buttons"
	buttons.position = Vector3(0.066, top, -0.008)
	body.add_child(buttons)
	var cols := [Color("3fb950"), Color("e5534b"), Color("388bfd"), Color("e3b341")]
	var offs := [Vector3(0, 0, 0.008), Vector3(0.008, 0, 0), Vector3(-0.008, 0, 0), Vector3(0, 0, -0.008)]
	for i in range(4):
		Kit.cyl(buttons, 0.0034, 0.002, Kit.plastic(Color("26282c"), 0.3), offs[i] + Vector3(0, 0.0008, 0))
		Kit.cyl(buttons, 0.0018, 0.0003, Kit.emissive(cols[i], 0.4), offs[i] + Vector3(0, 0.0019, 0))
	add_target("buttons", buttons, Kit.box_shape(Vector3(0.026, 0.008, 0.026)), Vector3(0, 0.002, 0), meshes_of(buttons), 0.0)
	for sx in [0.054, 0.064]:
		Kit.slab(body, Vector3(0.006, 0.001, 0.0028), 0.0013, 0.0003, Kit.plastic(Color("3a3d42"), 0.4), null, null, Vector3(sx, top + 0.0003, 0.025))
	# power slider on the right side + LED
	var sw := Kit.slab(body, Vector3(0.002, 0.004, 0.01), 0.0008, 0.0006, Kit.plastic(Color("3a3d42"), 0.4), null, null, Vector3(W * 0.5 - 0.004, 0.0, 0.008))
	sw.name = "PowerSwitch"
	add_target("power", body, Kit.box_shape(Vector3(0.012, 0.012, 0.02)), Vector3(W * 0.5 - 0.003, 0.0, 0.008), [sw], 0.0)
	led_mat = Kit.emissive(Color("6ec6ff"), 0.0)
	Kit.cyl(body, 0.0012, 0.0004, led_mat, Vector3(0.062, top + 0.0002, 0.03))
	# shoulder buttons + charge port
	for sx in [-1.0, 1.0]:
		Kit.slab(body, Vector3(0.03, 0.006, 0.006), 0.003, 0.002, Kit.plastic(Color("26282c"), 0.35), null, null, Vector3(sx * 0.06, 0.004, -D * 0.5 - 0.0015))
	var port := Kit.slab(body, Vector3(0.008, 0.0002, 0.0028), 0.0013, 0.00005, Kit.mat(Color("070708"), 0.5), null, null, Vector3(0, 0.0, D * 0.5 + 0.00002), Vector3(90, 0, 0))
	add_target("port", body, Kit.box_shape(Vector3(0.014, 0.008, 0.008)), Vector3(0, 0.0, D * 0.5 + 0.002), [port], 0.0036, Vector3(90, 0, 0))
	# back cover + screws
	cover = Node3D.new()
	cover.name = "Cover"
	body.add_child(cover)
	var cv := Kit.slab(cover, Vector3(W - 0.004, CT, D - 0.004), 0.028, 0.0015, interior, shell, shell, Vector3(0, -H * 0.5 + CT * 0.5, 0), Vector3.ZERO, 10, 3)
	cv.name = "CoverPlate"
	shell_meshes.append(cv)
	label3d(cover, "FX POCKET  •  Modelo FXP-3  •  5V 1.5A", 22, 0.0001, Color("6c727a"), Vector3(0, -H * 0.5 - 0.0001, 0.012), Vector3(90, 180, 0))
	add_target("cover", cover, Kit.box_shape(Vector3(W * 0.8, CT + 0.003, D * 0.8)), Vector3(0, -H * 0.5 + CT * 0.5, 0), [cv], 0.0)
	var yb := -H * 0.5 - 0.00002
	build_screws(cover, [Vector3(-0.06, yb, -0.022), Vector3(0.06, yb, -0.022), Vector3(-0.06, yb, 0.022), Vector3(0.06, yb, 0.022)], 0.0015, Vector3(180, 0, 0), Color("3a3e44"), 0.0055)
	# interior
	var yi := -H * 0.5 + CT
	var pcb := Kit.plastic(Color("173b2a"), 0.4, 0.2)
	Kit.slab(body, Vector3(0.14, 0.0012, 0.058), 0.01, 0.0003, pcb, null, pcb, Vector3(0, yi - 0.0006, 0))
	var bat := Node3D.new()
	bat.name = "HandheldBattery"
	bat.position = Vector3(0.0, yi, 0.004)
	body.add_child(bat)
	Kit.slab(bat, Vector3(0.05, 0.0034, 0.04), 0.003, 0.001, Kit.plastic(Color("2b56a8"), 0.4), null, Kit.plastic(Color("2b56a8"), 0.4), Vector3(0, -0.0017, 0))
	label3d(bat, "Li-ion 3.7V 2200mAh", 22, 0.00008, Color("e8eef6"), Vector3(0, -0.0036, 0), Vector3(90, 180, 0))
	register_part("handheld_battery", bat, Vector3(0.054, 0.008, 0.044), Vector3(0, -0.002, 0))
	make_surface(Vector3(W, H, D))


func view_transform(view: String) -> Transform3D:
	match view:
		"front":
			return _view(Vector3(0, 0.0, 0.004), Vector3(0.0, 0.27, 0.17))
		"port":
			return _view(Vector3(0, 0.0, D * 0.5), Vector3(0.02, 0.1, D * 0.5 + 0.2))
		"bottom", "interior":
			return _view(Vector3(0, 0.0, 0.0), Vector3(0.0, 0.27, 0.17))
	return _view(Vector3.ZERO, Vector3(0, 0.27, 0.2))
