extends "res://scripts/generic_device.gd"
## Vintage rotary telephone (~220 x 120 x 220 mm) with bell gongs inside.

const BASE_H := 0.075
const CT := 0.006

var handset: Node3D
var dial: Node3D
var gongs: Array[Node3D] = []


func _init() -> void:
	super._init()
	device_id = "rotary"
	display_name = "Telefone antigo"
	name = "RotaryPhone"
	rest_y = 0.004
	rest_y_flipped = 0.168
	body.position = Vector3(0, rest_y, 0)
	_build()


func _build() -> void:
	var colors := [Color("1b1b1d"), Color("7a1e1e"), Color("2f5d3a"), Color("d8cfc0")]
	var bak := Kit.plastic(colors[randi() % colors.size()], 0.18, 0.05)
	bak.clearcoat_enabled = true
	bak.clearcoat = 1.0
	bak.clearcoat_roughness = 0.1
	var interior := Kit.mat(Color("6b6156"), 0.6, 0.3)
	var chrome := Kit.chrome()
	# body: lathe dome on a slab base (bakelite)
	var shell_mat := bak.duplicate() as StandardMaterial3D
	shell_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var shell := Kit.mi(body, Kit.lathe_mesh([Vector3(CT, 0.11, 0.115), Vector3(0.02, 0.112, 0.118), Vector3(0.05, 0.1, 0.106), Vector3(0.085, 0.075, 0.08), Vector3(0.11, 0.06, 0.062), Vector3(0.12, 0.0, 0.0)], 32, [], false), shell_mat)
	shell.name = "Shell"
	shell_meshes.append(shell)
	# rotary dial on the sloped front
	dial = Node3D.new()
	dial.name = "Dial"
	dial.position = Vector3(0, 0.068, 0.094)
	dial.rotation_degrees = Vector3(58, 0, 0)
	body.add_child(dial)
	Kit.cyl(dial, 0.048, 0.006, chrome, Vector3(0, 0.003, 0))
	Kit.cyl(dial, 0.042, 0.004, Kit.plastic(Color("f2ede2"), 0.4), Vector3(0, 0.006, 0))
	var hole := Kit.mat(Color("0d0d0f"), 0.6)
	for i in range(10):
		var a := deg_to_rad(-50 + i * 28.0)
		Kit.cyl(dial, 0.0062, 0.003, hole, Vector3(cos(a) * 0.032, 0.0075, sin(a) * 0.032))
		var n := label3d(dial, str((i + 1) % 10), 32, 0.00011, Color("1b1b1b"), Vector3(cos(a) * 0.032, 0.0077, sin(a) * 0.032), Vector3(-90, 0, 0))
		n.no_depth_test = false
	Kit.cyl(dial, 0.013, 0.004, Kit.plastic(Color("f2ede2"), 0.4), Vector3(0, 0.008, 0))
	Kit.box(dial, Vector3(0.004, 0.006, 0.016), chrome, Vector3(0.035, 0.008, 0.03), Vector3(0, -30, 0))
	add_target("dial", dial, Kit.sphere_shape(0.05), Vector3(0, 0.006, 0), meshes_of(dial), 0.05)
	# cradle: two forked prongs with hook-switch plungers between them
	var chrome2 := Kit.chrome(Color("c9ced4"))
	for sx in [-1.0, 1.0]:
		Kit.capsule(body, 0.011, 0.045, bak, Vector3(sx * 0.072, 0.118, -0.012))
		for dz in [-0.012, 0.012]:
			Kit.capsule(body, 0.006, 0.022, bak, Vector3(sx * 0.072, 0.142, -0.012 + dz), Vector3(dz * 900.0, 0, 0))
		Kit.cyl(body, 0.006, 0.012, chrome2, Vector3(sx * 0.04, 0.122, -0.012))
	# handset: curved grip with earpiece and mouthpiece cups facing down
	handset = Node3D.new()
	handset.name = "Handset"
	handset.position = Vector3(0, 0.152, -0.012)
	body.add_child(handset)
	var grip_pts := Kit.bezier(Vector3(-0.085, -0.008, 0), Vector3(-0.05, 0.022, 0), Vector3(0.05, 0.022, 0), Vector3(0.085, -0.008, 0), 18)
	var grip := Kit.mi(handset, Kit.tube_mesh(grip_pts, 0.0145, 14), bak)
	grip.scale = Vector3(1, 1, 0.9)
	for sx in [-1.0, 1.0]:
		var cup := Kit.lathe(handset, [Vector3(-0.03, 0.03, 0.03), Vector3(-0.024, 0.033, 0.033), Vector3(-0.01, 0.028, 0.028), Vector3(0.0, 0.016, 0.016)], bak, Vector3(sx * 0.088, -0.006, 0), Vector3.ZERO, 24)
		cup.name = "Cup"
		# grille holes on the underside
		Kit.cyl(handset, 0.024, 0.002, Kit.mat(Color("2a2522"), 0.6), Vector3(sx * 0.088, -0.036, 0))
		for k in range(6):
			var a2 := TAU * k / 6.0
			Kit.cyl(handset, 0.0025, 0.003, Kit.mat(Color("0d0d0d"), 0.6), Vector3(sx * 0.088 + cos(a2) * 0.012, -0.037, sin(a2) * 0.012))
	add_target("hook", handset, Kit.box_shape(Vector3(0.22, 0.06, 0.07)), Vector3.ZERO, meshes_of(handset), 0.0)
	# coiled cord to the side
	var pts := PackedVector3Array()
	for i in range(120):
		var tt := float(i) / 119.0
		var base := Vector3(-0.1 - tt * 0.08, 0.1 - tt * 0.09, -0.02 + tt * 0.06)
		pts.append(base + Vector3(0, cos(tt * 60.0) * 0.006, sin(tt * 60.0) * 0.006))
	Kit.mi(body, Kit.tube_mesh(pts, 0.0018, 6), bak)
	# bottom plate (cover) with screws + felt feet
	cover = Node3D.new()
	cover.name = "Cover"
	body.add_child(cover)
	var plate := Kit.slab(cover, Vector3(0.21, CT, 0.22), 0.04, 0.002, interior, Kit.mat(Color("3a3530"), 0.5, 0.5), Kit.mat(Color("3a3530"), 0.5, 0.5), Vector3(0, CT * 0.5, 0))
	plate.name = "CoverPlate"
	shell_meshes.append(plate)
	for x in [-0.08, 0.08]:
		for z in [-0.08, 0.08]:
			Kit.cyl(cover, 0.01, 0.004, Kit.fabric(Color("3d2f22"), 1.0), Vector3(x, -0.002, z))
	label3d(cover, "TELEFONES DE PORTUGAL  •  1974", 26, 0.00014, Color("c2b8a8"), Vector3(0, -0.0001, 0.02), Vector3(90, 180, 0))
	add_target("cover", cover, Kit.box_shape(Vector3(0.18, CT + 0.004, 0.18)), Vector3(0, CT * 0.5, 0), [plate], 0.0)
	build_screws(cover, [Vector3(-0.06, -0.00002, -0.06), Vector3(0.06, -0.00002, -0.06), Vector3(-0.06, -0.00002, 0.06), Vector3(0.06, -0.00002, 0.06)], 0.003, Vector3(180, 0, 0), Color("8a7d6b"), 0.009)
	cover_lift = Vector3(0, -0.03, 0)
	# interior: bell gongs, ringer coil (replaceable), dusty contacts
	var yi := CT
	for sx in [-1.0, 1.0]:
		var g := Kit.lathe(body, [Vector3(-0.024, 0.0, 0.0), Vector3(-0.02, 0.022, 0.022), Vector3(-0.008, 0.034, 0.034), Vector3(0.0, 0.036, 0.036)], chrome, Vector3(sx * 0.05, yi + 0.024, -0.02), Vector3(180, 0, 0), 28)
		g.name = "Gong"
		gongs.append(g)
	var ringer := Node3D.new()
	ringer.name = "Ringer"
	ringer.position = Vector3(0, yi, 0.035)
	body.add_child(ringer)
	for sx in [-1.0, 1.0]:
		Kit.cyl(ringer, 0.012, 0.035, Kit.mat(Color("b5652e"), 0.35, 0.8), Vector3(sx * 0.016, 0.018, 0), Vector3(0, 0, 0))
	Kit.box(ringer, Vector3(0.05, 0.004, 0.02), Kit.mat(Color("4a4a4a"), 0.4, 0.8), Vector3(0, 0.002, 0))
	Kit.cyl(ringer, 0.003, 0.05, chrome, Vector3(0, 0.03, -0.03), Vector3(90, 0, 0))
	register_part("ringer", ringer, Vector3(0.06, 0.04, 0.04), Vector3(0, 0.018, 0))
	var block := Kit.plastic(Color("2b2622"), 0.5)
	Kit.box(body, Vector3(0.07, 0.012, 0.04), block, Vector3(0.0, yi + 0.006, -0.06))
	for k in range(5):
		var spring := Kit.box(body, Vector3(0.004, 0.0015, 0.05), Kit.mat(Color("c9a640"), 0.25, 0.95), Vector3(-0.024 + k * 0.012, yi + 0.0135, -0.06))
		spring.rotation_degrees.x = 6.0
		Kit.cyl(body, 0.003, 0.004, Kit.chrome(Color("d8c38a")), Vector3(-0.024 + k * 0.012, yi + 0.0145, -0.083))
	make_dust(body, Vector3(0.0, yi + 0.016, -0.06), 0.032, Vector3(180, 0, 0))
	add_target("contacts", body, Kit.box_shape(Vector3(0.08, 0.03, 0.06)), Vector3(0.0, yi + 0.012, -0.06), [], 0.036, Vector3(180, 0, 0))
	make_surface(Vector3(0.22, 0.13, 0.23), Vector3(0, 0.065, 0))
	flip_rot = Vector3(0, 0, PI)


func ring(ok: bool) -> void:
	var t := tw()
	t.tween_property(handset, "position", Vector3(0.0, 0.22, 0.04), 0.3)
	t.parallel().tween_property(handset, "rotation", Vector3(0.5, 0.0, 0.25), 0.3)
	t.tween_interval(0.5)
	t.tween_property(handset, "position", Vector3(0, 0.152, -0.012), 0.3)
	t.parallel().tween_property(handset, "rotation", Vector3.ZERO, 0.3)
	if ok:
		var s := tw()
		for i in range(8):
			s.tween_property(body, "rotation:z", 0.015 * (1 if i % 2 == 0 else -1), 0.05)
		s.tween_property(body, "rotation:z", 0.0, 0.05)


func spin_dial() -> void:
	var t := tw()
	t.tween_property(dial, "rotation:y", deg_to_rad(-200), 0.5)
	t.tween_property(dial, "rotation:y", 0.0, 0.8)


func view_transform(view: String) -> Transform3D:
	match view:
		"front":
			return _view(Vector3(0, 0.08, 0.03), Vector3(0.0, 0.28, 0.27))
		"bottom", "interior":
			return _view(Vector3(0, 0.12, 0.0), Vector3(0.02, 0.5, 0.26))
	return _view(Vector3(0, 0.06, 0), Vector3(0, 0.35, 0.35))
