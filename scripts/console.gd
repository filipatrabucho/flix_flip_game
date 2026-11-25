extends "res://scripts/generic_device.gd"
## Home video game console (~300 x 65 x 255 mm), generic design.

const W := 0.30
const H := 0.065
const D := 0.255
const CT := 0.006


func _init() -> void:
	super._init()
	device_id = "console"
	display_name = "Consola"
	name = "Console"
	rest_y = H * 0.5 + 0.004
	rest_y_flipped = H * 0.5 + 0.002
	body.position = Vector3(0, rest_y, 0)
	_build()


func _build() -> void:
	var white := Kit.plastic(Color("e9ebee"), 0.35, 0.1)
	white.clearcoat_enabled = true
	white.clearcoat = 0.5
	var black := Kit.plastic(Color("17191c"), 0.25, 0.1)
	black.clearcoat_enabled = true
	black.clearcoat = 0.8
	var interior := Kit.plastic(Color("2a2d31"), 0.6, 0.2)
	# two-tone shell: glossy black core with white side plates
	var core := Kit.slab(body, Vector3(W - 0.03, H - CT, D - 0.01), 0.012, 0.006, black, black, interior, Vector3(0, CT * 0.5, 0))
	core.name = "Core"
	shell_meshes.append(core)
	for sx in [-1.0, 1.0]:
		var plate := Kit.slab(body, Vector3(0.022, H + 0.008, D + 0.008), 0.01, 0.008, white, white, white, Vector3(sx * (W * 0.5 - 0.008), 0.002, 0))
		shell_meshes.append(plate)
	# front: disc slot, power button with LED strip, USB ports
	var dark := Kit.mat(Color("070708"), 0.5)
	Kit.box(body, Vector3(0.17, 0.003, 0.002), dark, Vector3(-0.02, 0.012, D * 0.5 - 0.004))
	var pbtn := Kit.slab(body, Vector3(0.022, 0.004, 0.006), 0.002, 0.001, Kit.plastic(Color("2a2d31"), 0.3), null, null, Vector3(0.1, 0.0, D * 0.5 - 0.004), Vector3(90, 0, 0))
	pbtn.name = "PowerBtn"
	led_mat = Kit.emissive(Color("6ec6ff"), 0.0)
	Kit.box(body, Vector3(0.24, 0.002, 0.002), led_mat, Vector3(0, H * 0.5 - 0.004, D * 0.5 - 0.004))
	add_target("power", body, Kit.box_shape(Vector3(0.04, 0.02, 0.02)), Vector3(0.1, 0.0, D * 0.5), [pbtn], 0.0)
	for i in range(2):
		Kit.slab(body, Vector3(0.012, 0.0045, 0.002), 0.0005, 0.0002, dark, null, null, Vector3(0.05 + i * 0.018, -0.012, D * 0.5 - 0.004), Vector3(90, 0, 0))
	# back vents
	for i in range(22):
		Kit.box(body, Vector3(0.006, 0.03, 0.002), dark, Vector3(-0.11 + i * 0.01, 0.005, -D * 0.5 + 0.004))
	var logo := label3d(body, "FX STATION", 40, 0.0006, Color("9aa3ad"), Vector3(-0.07, H * 0.5 + 0.0002, 0.05))
	logo.rotation_degrees = Vector3(-90, 0, 0)
	# --- bottom cover + feet + screws
	cover = Node3D.new()
	cover.name = "Cover"
	body.add_child(cover)
	var cv := Kit.slab(cover, Vector3(W - 0.034, CT, D - 0.014), 0.012, 0.002, interior, black, black, Vector3(0, -H * 0.5 + CT * 0.5, 0))
	cv.name = "CoverPlate"
	shell_meshes.append(cv)
	for x in [-0.11, 0.11]:
		for z in [-0.1, 0.1]:
			Kit.cyl(cover, 0.008, 0.003, Kit.rubber(), Vector3(x, -H * 0.5 - 0.0015, z))
	label3d(cover, "FX STATION  •  Modelo FXS-500  •  12V 10A", 24, 0.00012, Color("6c727a"), Vector3(0, -H * 0.5 - 0.0001, 0.03), Vector3(90, 180, 0))
	add_target("cover", cover, Kit.box_shape(Vector3(W * 0.85, CT + 0.004, D * 0.85)), Vector3(0, -H * 0.5 + CT * 0.5, 0), [cv], 0.0)
	var yb := -H * 0.5 - 0.00002
	build_screws(cover, [Vector3(-0.12, yb, -0.105), Vector3(0.12, yb, -0.105), Vector3(-0.12, yb, 0.105), Vector3(0.12, yb, 0.105)], 0.0024, Vector3(180, 0, 0), Color("3a3e44"), 0.0085)
	# --- interior (faces -Y, visible when flipped and opened)
	var yi := -H * 0.5 + CT
	var pcb := Kit.plastic(Color("163522"), 0.4, 0.2)
	Kit.slab(body, Vector3(0.18, 0.0015, 0.16), 0.004, 0.0004, pcb, null, pcb, Vector3(0.04, yi - 0.00075, 0.01))
	Kit.slab(body, Vector3(0.05, 0.004, 0.05), 0.003, 0.001, Kit.mat(Color("8f969e"), 0.3, 0.9), null, Kit.mat(Color("8f969e"), 0.3, 0.9), Vector3(0.06, yi - 0.0035, -0.01))
	# fan (dusty) and PSU
	var fan := Node3D.new()
	fan.name = "ConsoleFan"
	fan.position = Vector3(-0.085, yi, -0.05)
	body.add_child(fan)
	Kit.cyl(fan, 0.045, 0.004, Kit.plastic(Color("1b1d20"), 0.5), Vector3(0, -0.002, 0))
	for i in range(9):
		var a := TAU * i / 9.0
		Kit.box(fan, Vector3(0.028, 0.001, 0.008), Kit.plastic(Color("2a2d31"), 0.45), Vector3(cos(a) * 0.024, -0.0045, sin(a) * 0.024), Vector3(18, -rad_to_deg(a), 0))
	make_dust(fan, Vector3(0, -0.005, 0), 0.043)
	register_part("console_fan", fan, Vector3(0.1, 0.012, 0.1), Vector3(0, -0.003, 0))
	add_target("fan", body, Kit.box_shape(Vector3(0.095, 0.012, 0.095)), Vector3(-0.085, yi - 0.004, -0.05), meshes_of(fan), 0.047)
	Kit.slab(body, Vector3(0.08, 0.0055, 0.09), 0.003, 0.001, Kit.mat(Color("6d737a"), 0.35, 0.85), null, Kit.mat(Color("6d737a"), 0.35, 0.85), Vector3(-0.085, yi - 0.00275, 0.06))
	label3d(body, "PSU 12V", 26, 0.00012, Color("e8eef4"), Vector3(-0.085, yi - 0.0057, 0.06), Vector3(90, 180, 0))
	# disc drive (replaceable)
	var drive := Node3D.new()
	drive.name = "DiscDrive"
	drive.position = Vector3(0.07, yi, 0.07)
	body.add_child(drive)
	Kit.slab(drive, Vector3(0.13, 0.0052, 0.1), 0.004, 0.001, Kit.mat(Color("a7adb4"), 0.3, 0.9), null, Kit.mat(Color("a7adb4"), 0.3, 0.9), Vector3(0, -0.0026, 0))
	Kit.cyl(drive, 0.035, 0.0006, Kit.mat(Color("2b2f36"), 0.4), Vector3(0.0, -0.0055, 0.0))
	label3d(drive, "BD-DRIVE", 26, 0.00012, Color("1d2227"), Vector3(0.035, -0.0056, 0.03), Vector3(90, 180, 0))
	register_part("disc_drive", drive, Vector3(0.135, 0.012, 0.105), Vector3(0, -0.003, 0))
	make_surface(Vector3(W, H, D))


func view_transform(view: String) -> Transform3D:
	match view:
		"front":
			return _view(Vector3(0, 0.02, 0.05), Vector3(0.05, 0.25, 0.42))
		"bottom", "interior":
			return _view(Vector3(0, 0.0, 0.0), Vector3(0.03, 0.42, 0.3))
	return _view(Vector3.ZERO, Vector3(0, 0.35, 0.35))
