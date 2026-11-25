extends "res://scripts/device_base.gd"
## Modern smartphone at real scale (71.6 x 7.8 x 147.6 mm), lying screen up.
## Body frame: origin = centre, +Z = bottom edge (USB-C), +Y = screen side.

const W := 0.0716
const L := 0.1476
const T := 0.0078
const ST := 0.0017             # screen assembly thickness

var frame_mesh: MeshInstance3D
var screen_pivot: Node3D
var screen_node: Node3D
var screen_glass: MeshInstance3D
var screen_mat: StandardMaterial3D
var crack_mesh: MeshInstance3D
var screen_vp: SubViewport
var screws: Array[Node3D] = []
var screw_local: Array[Vector3] = []
var new_screen: Node3D
var cleaned := 0.0
var screen_state := "off"
var _lock: Control
var _glitch: Control
var _msg_screen: Control
var _msg_label: Label
var _crack_mat: StandardMaterial3D
var y_top := T * 0.5
var y_frame_top := T * 0.5 - ST


func _init() -> void:
	super._init()
	device_id = "phone"
	display_name = "Telemóvel"
	name = "Phone"
	body.position = Vector3(0, T * 0.5 + 0.0002, 0)
	_build()


func _ready() -> void:
	screen_mat.albedo_texture = screen_vp.get_texture()


func _build() -> void:
	var frame := Kit.aluminium(Color("4a5a6e"), 0.22)
	frame.anisotropy = 0.0
	var back := Kit.mat(Color("27384d"), 0.42, 0.0)
	back.clearcoat_enabled = true
	back.clearcoat = 0.8
	back.clearcoat_roughness = 0.35
	var interior := Kit.plastic(Color("2f3338"), 0.5, 0.2)
	var frame_h := T - ST
	frame_mesh = Kit.slab(body, Vector3(W, frame_h, L), 0.0105, 0.0022, interior, frame, back, Vector3(0, -T * 0.5 + frame_h * 0.5, 0), Vector3.ZERO, 10, 3)
	frame_mesh.name = "Frame"
	shell_meshes.append(frame_mesh)
	# antenna lines on the frame
	var band := Kit.plastic(Color("2b3440"), 0.4)
	for z in [-L * 0.5 + 0.012, L * 0.5 - 0.012]:
		Kit.box(body, Vector3(W + 0.0002, 0.0024, 0.0009), band, Vector3(0, -0.0005, z))
	# side buttons
	var btn := Kit.aluminium(Color("56677c"), 0.25)
	var pbtn := Kit.slab(body, Vector3(0.0012, 0.0024, 0.017), 0.0005, 0.0004, btn, null, null, Vector3(W * 0.5 + 0.0003, -0.0005, -0.022))
	pbtn.name = "PowerButton"
	add_target("power", body, Kit.box_shape(Vector3(0.008, 0.008, 0.022)), Vector3(W * 0.5 + 0.002, 0.0, -0.022), [pbtn], 0.0)
	Kit.slab(body, Vector3(0.0012, 0.0024, 0.0085), 0.0005, 0.0004, btn, null, null, Vector3(-W * 0.5 - 0.0003, -0.0005, -0.042))
	Kit.slab(body, Vector3(0.0012, 0.0024, 0.0110), 0.0005, 0.0004, btn, null, null, Vector3(-W * 0.5 - 0.0003, -0.0005, -0.026))
	Kit.slab(body, Vector3(0.0012, 0.0024, 0.0110), 0.0005, 0.0004, btn, null, null, Vector3(-W * 0.5 - 0.0003, -0.0005, -0.012))
	# bottom edge: USB-C, speaker + mic holes, pentalobe screws
	var dark := Kit.mat(Color("0b0c0e"), 0.5)
	var usb := Kit.slab(body, Vector3(0.0088, 0.0002, 0.0030), 0.0014, 0.00005, dark, null, null, Vector3(0, -0.0006, L * 0.5 + 0.00002))
	usb.rotation_degrees = Vector3(90, 0, 0)
	for i in range(6):
		Kit.cyl(body, 0.00055, 0.0003, dark, Vector3(0.0105 + i * 0.0021, -0.0006, L * 0.5 + 0.00001), Vector3(90, 0, 0), -1.0, 8)
		Kit.cyl(body, 0.00055, 0.0003, dark, Vector3(-0.0105 - i * 0.0021, -0.0006, L * 0.5 + 0.00001), Vector3(90, 0, 0), -1.0, 8)
	for i in range(2):
		var p := Vector3(-0.0068 + i * 0.0136, -0.0006, L * 0.5 + 0.00003)
		var s := screw_head(body, 0.00075, p, Vector3(90, 0, 0), Color("aeb5bd"))
		s.name = "Pentalobe%d" % i
		screws.append(s)
		screw_local.append(p)
		add_target("pscrew%d" % i, body, Kit.sphere_shape(0.0032), p, [s.get_meta("head_mesh")], 0.0032, Vector3(90, 0, 0))
	add_target("port", body, Kit.box_shape(Vector3(0.014, 0.006, 0.006)), Vector3(0, -0.0006, L * 0.5 + 0.002), [usb], 0.0035, Vector3(90, 0, 0))
	# rear camera bump (underneath)
	var bump_mat := Kit.mat(Color("2a3a50"), 0.3, 0.0)
	Kit.slab(body, Vector3(0.032, 0.0014, 0.033), 0.008, 0.0006, bump_mat, bump_mat, bump_mat, Vector3(-W * 0.5 + 0.021, -T * 0.5 - 0.0006, -L * 0.5 + 0.022))
	# interior (under the screen)
	_build_interior()
	# --- screen assembly hinged on the right edge (opens like a book)
	screen_pivot = Node3D.new()
	screen_pivot.name = "ScreenPivot"
	screen_pivot.position = Vector3(W * 0.5 - 0.0004, y_frame_top, 0)
	body.add_child(screen_pivot)
	screen_node = _build_screen_assembly(true)
	screen_pivot.add_child(screen_node)
	screen_node.position = Vector3(-W * 0.5 + 0.0004, 0, 0)
	make_surface(Vector3(W, T, L))
	add_target("screen", screen_node, Kit.box_shape(Vector3(W * 0.9, 0.004, L * 0.9)), Vector3(0, ST, 0), [screen_glass], 0.0)
	_set_screen("off")


func _build_interior() -> void:
	var yi := y_frame_top
	var cell := Kit.plastic(Color("1b1d20"), 0.4, 0.1)
	var board := Kit.plastic(Color("10241a"), 0.4, 0.2)
	var shield := Kit.chrome(Color("b5bcc4"))
	shield.roughness = 0.35
	var pack := Node3D.new()
	pack.name = "BatteryPack"
	pack.position = Vector3(-0.004, yi, 0.018)
	body.add_child(pack)
	var bat := Kit.slab(pack, Vector3(0.050, 0.0011, 0.072), 0.003, 0.0004, cell, cell, cell, Vector3(0, 0.00055, 0))
	bat.name = "PhoneBattery"
	label3d(pack, "Li-ion 3.88V  3349mAh", 24, 0.00007, Color("c8cdd2"), Vector3(0, 0.00115, 0))
	Kit.slab(pack, Vector3(0.008, 0.0006, 0.012), 0.001, 0.0002, Kit.plastic(Color("c27a24"), 0.4), null, null, Vector3(0.024, 0.0003, -0.03))
	register_part("phone_battery", pack, Vector3(0.052, 0.004, 0.074), Vector3(0, 0.0008, 0))
	Kit.slab(body, Vector3(0.060, 0.0012, 0.040), 0.004, 0.0004, board, board, board, Vector3(0, yi + 0.0006, -0.045))
	Kit.slab(body, Vector3(0.036, 0.0013, 0.026), 0.002, 0.0004, shield, shield, shield, Vector3(0.008, yi + 0.0007, -0.046))
	Kit.cyl(body, 0.0055, 0.0012, Kit.mat(Color("0d0f12"), 0.15, 0.2), Vector3(-0.020, yi + 0.0006, -0.058))
	Kit.cyl(body, 0.0045, 0.0012, Kit.mat(Color("0d0f12"), 0.15, 0.2), Vector3(-0.020, yi + 0.0006, -0.045))
	Kit.slab(body, Vector3(0.030, 0.0012, 0.012), 0.002, 0.0004, cell, cell, cell, Vector3(0.0, yi + 0.0006, 0.064))
	# flex cable to the screen (right edge)
	Kit.slab(body, Vector3(0.010, 0.0003, 0.020), 0.001, 0.0001, Kit.plastic(Color("c27a24"), 0.4), null, null, Vector3(0.028, yi + 0.0002, -0.020))


func _build_screen_assembly(broken: bool) -> Node3D:
	var n := Node3D.new()
	n.name = "ScreenAssembly" if broken else "NewScreen"
	var glass := Kit.black_glass()
	var under := Kit.plastic(Color("202327"), 0.5)
	var g := Kit.slab(n, Vector3(W - 0.0008, ST, L - 0.0008), 0.0101, 0.0011, glass, glass, under, Vector3(0, ST * 0.5, 0), Vector3.ZERO, 10, 3)
	g.name = "Glass"
	if broken:
		screen_glass = g
		shell_meshes.append(g)
		# display content (lock screen) just above the glass top
		screen_vp = _build_screen_viewport()
		screen_mat = _screen_material()
		var disp := PlaneMesh.new()
		disp.size = Vector2(W - 0.0042, L - 0.0042)
		Kit.mi(n, disp, screen_mat, Vector3(0, ST + 0.00003, 0)).name = "Display"
		_crack_mat = _crack_material()
		var crack_plane := PlaneMesh.new()
		crack_plane.size = Vector2(W - 0.002, L - 0.002)
		crack_mesh = Kit.mi(n, crack_plane, _crack_mat, Vector3(0, ST + 0.00006, 0))
		crack_mesh.name = "Cracks"
	else:
		label3d(n, "PROTEÇÃO", 26, 0.00008, Color(0.7, 0.85, 1.0, 0.8), Vector3(0, ST + 0.00012, 0.05)).name = "FilmLabel"
		var film := Kit.glass(Color(0.75, 0.88, 1.0), 0.2, 0.18)
		Kit.slab(n, Vector3(W - 0.0006, 0.0001, L - 0.0006), 0.0101, 0.00005, film, null, null, Vector3(0, ST + 0.00008, 0)).name = "Film"
		var tab := Kit.slab(n, Vector3(0.012, 0.0001, 0.010), 0.002, 0.00005, Kit.plastic(Color("2f80ed"), 0.5), null, null, Vector3(0, ST + 0.0001, L * 0.5 + 0.004))
		tab.name = "Tab"
	# dynamic island
	var island := Kit.slab(n, Vector3(0.020, 0.00008, 0.0058), 0.0029, 0.00003, Kit.mat(Color("010101"), 0.2), null, null, Vector3(0, ST + 0.00009, -L * 0.5 + 0.0105))
	island.name = "Island"
	# flex connector under the screen
	Kit.slab(n, Vector3(0.010, 0.0003, 0.020), 0.001, 0.0001, Kit.plastic(Color("c27a24"), 0.4), null, null, Vector3(0.028, -0.00015, -0.020))
	return n


func _crack_material() -> StandardMaterial3D:
	var img := Image.create(256, 512, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var origin := Vector2(170, 150)
	for i in range(16):
		var p := origin
		var a := rng.randf() * TAU
		for s in range(rng.randi_range(8, 20)):
			a += rng.randf_range(-0.5, 0.5)
			var q := p + Vector2(cos(a), sin(a)) * rng.randf_range(10, 26)
			_line(img, p, q, Color(0.9, 0.95, 1.0, rng.randf_range(0.45, 0.9)))
			if rng.randf() < 0.25:
				var b := a + rng.randf_range(-1.2, 1.2)
				_line(img, q, q + Vector2(cos(b), sin(b)) * rng.randf_range(8, 30), Color(0.9, 0.95, 1.0, 0.5))
			p = q
	for r in [10.0, 20.0, 34.0]:
		var steps := 36
		for k in range(steps):
			if rng.randf() < 0.55:
				var a0 := TAU * k / steps
				var a1 := TAU * (k + 1) / steps
				_line(img, origin + Vector2(cos(a0), sin(a0)) * r, origin + Vector2(cos(a1), sin(a1)) * r, Color(0.9, 0.95, 1.0, 0.6))
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1, 0.55)
	return m


func _line(img: Image, a: Vector2, b: Vector2, c: Color) -> void:
	var n := int(a.distance_to(b)) + 1
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / n)
		var x := int(p.x)
		var y := int(p.y)
		if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
			img.set_pixel(x, y, c)


func _build_screen_viewport() -> SubViewport:
	var vp := Kit.text_viewport(self, Vector2i(360, 740), func(root: Control) -> void:
		var bg := ColorRect.new()
		bg.color = Color.BLACK
		bg.size = Vector2(360, 740)
		root.add_child(bg)
		_lock = Control.new()
		_lock.size = Vector2(360, 740)
		root.add_child(_lock)
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color("ff7e5f"), Color("7b4397"), Color("1d2b64")])
		grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill_from = Vector2(0.5, 0.0)
		gt.fill_to = Vector2(0.5, 1.0)
		gt.width = 64
		gt.height = 128
		var wall := TextureRect.new()
		wall.texture = gt
		wall.size = Vector2(360, 740)
		wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wall.stretch_mode = TextureRect.STRETCH_SCALE
		_lock.add_child(wall)
		var t := Label.new()
		t.text = "08:00"
		t.size = Vector2(360, 120)
		t.position = Vector2(0, 120)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.add_theme_font_size_override("font_size", 96)
		t.add_theme_color_override("font_color", Color.WHITE)
		_lock.add_child(t)
		var d := Label.new()
		d.text = "segunda-feira, 1 de março"
		d.size = Vector2(360, 40)
		d.position = Vector2(0, 84)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.add_theme_font_size_override("font_size", 22)
		d.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		_lock.add_child(d)
		var bar := ColorRect.new()
		bar.color = Color(1, 1, 1, 0.8)
		bar.size = Vector2(120, 6)
		bar.position = Vector2(120, 712)
		_lock.add_child(bar)
		_msg_screen = Control.new()
		_msg_screen.size = Vector2(360, 740)
		root.add_child(_msg_screen)
		_msg_label = Label.new()
		_msg_label.size = Vector2(320, 740)
		_msg_label.position = Vector2(20, 0)
		_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_msg_label.add_theme_font_size_override("font_size", 34)
		_msg_screen.add_child(_msg_label)
		_glitch = Control.new()
		_glitch.size = Vector2(360, 740)
		root.add_child(_glitch)
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for i in range(26):
			var r := ColorRect.new()
			r.color = [Color("ff00aa"), Color("00ff88"), Color("ffffff"), Color("3355ff")][i % 4]
			r.position = Vector2(0, rng.randi_range(0, 740))
			r.size = Vector2(360, rng.randi_range(2, 14))
			_glitch.add_child(r)
	, false)
	return vp


func _set_screen(state: String) -> void:
	screen_state = state
	if _lock == null:
		return
	_lock.visible = state == "on"
	_glitch.visible = state == "glitch"
	_msg_screen.visible = state == "msg"
	for n in [screen_node, new_screen]:
		if n != null and is_instance_valid(n):
			var d := n.get_node_or_null("Display") as Node3D
			if d:
				d.visible = state != "off"


# --- actions -----------------------------------------------------------------
func press_power(mode: String) -> void:
	var b: Node3D = body.get_node("PowerButton")
	var t := tw()
	t.tween_property(b, "position:x", b.position.x - 0.0005, 0.08)
	t.tween_property(b, "position:x", b.position.x, 0.12)
	_set_screen(mode)
	if mode == "glitch":
		get_tree().create_timer(1.8).timeout.connect(func() -> void: _set_screen("off"))


func show_message(text: String, color := Color.WHITE, seconds := 2.0) -> void:
	_msg_label.text = text
	_msg_label.add_theme_color_override("font_color", color)
	_set_screen("msg")
	if seconds > 0.0:
		get_tree().create_timer(seconds).timeout.connect(func() -> void:
			if screen_state == "msg":
				_set_screen("off"))


## For faults other than the cracked screen: hide the cracks, keep the glass clean.
func set_screen_ok() -> void:
	crack_mesh.visible = false
	cleaned = 1.0


func press_button_only() -> void:
	var b: Node3D = body.get_node("PowerButton")
	var t := tw()
	t.tween_property(b, "position:x", b.position.x - 0.0005, 0.08)
	t.tween_property(b, "position:x", b.position.x, 0.12)


## Wipe the screen; returns true when it is fully clean and the cracks are obvious.
func wipe() -> bool:
	cleaned = minf(1.0, cleaned + 0.34)
	_crack_mat.albedo_color.a = 0.55 + 0.45 * cleaned
	return cleaned >= 0.99


func unscrew(index: int, tray_global: Vector3) -> Tween:
	return anim_unscrew(screws[index], tray_global, Vector3.BACK)


func screw_in(index: int) -> Tween:
	return anim_screw_in(screws[index], body, screw_local[index], Vector3(90, 0, 0), Vector3.BACK)


func open_screen(angle := 100.0) -> Tween:
	var t := tw()
	t.tween_property(screen_pivot, "position:y", y_frame_top + 0.0015, 0.25)
	t.tween_property(screen_pivot, "rotation:z", -deg_to_rad(angle), 0.8)
	return t


func close_screen() -> Tween:
	var t := tw()
	t.tween_property(screen_pivot, "rotation:z", 0.0, 0.7)
	t.tween_property(screen_pivot, "position:y", y_frame_top, 0.2)
	return t


func remove_old_screen(aside_global: Vector3) -> Tween:
	var t := tw()
	t.tween_callback(func() -> void:
		var gt := screen_node.global_transform
		screen_pivot.remove_child(screen_node)
		add_child(screen_node)
		screen_node.global_transform = gt)
	t.tween_property(screen_node, "global_position", aside_global + Vector3(0, 0.03, 0), 0.5)
	t.tween_property(screen_node, "global_rotation", Vector3(0, 0.3, 0), 0.4)
	t.tween_property(screen_node, "global_position", aside_global, 0.3)
	return t


func spawn_new_screen(global_pos: Vector3) -> void:
	new_screen = _build_screen_assembly(false)
	add_child(new_screen)
	new_screen.global_position = global_pos
	new_screen.rotation_degrees = Vector3(0, -8, 0)
	var meshes: Array = []
	for c in new_screen.get_children():
		if c is MeshInstance3D and c.name == "Glass":
			meshes.append(c)
	add_target("new_screen", new_screen, Kit.box_shape(Vector3(W, 0.006, L)), Vector3(0, ST, 0), meshes, 0.0)


func install_new_screen() -> Tween:
	var t := tw()
	# goes into the open hinge: match the pivot's current orientation
	var pivot_gt := screen_pivot.global_transform
	var final_gt := pivot_gt * Transform3D(Basis.IDENTITY, Vector3(-W * 0.5 + 0.0004, 0, 0))
	t.tween_property(new_screen, "global_position", final_gt.origin + Vector3(0, 0.04, 0), 0.5)
	t.parallel().tween_property(new_screen, "global_rotation", final_gt.basis.get_euler(), 0.5)
	t.tween_property(new_screen, "global_position", final_gt.origin, 0.35)
	t.tween_callback(func() -> void:
		for nm in ["Tab", "Film", "FilmLabel"]:
			var node := new_screen.get_node_or_null(nm)
			if node:
				node.queue_free()
		var gt := new_screen.global_transform
		remove_child(new_screen)
		screen_pivot.add_child(new_screen)
		new_screen.global_transform = gt
		new_screen.position = Vector3(-W * 0.5 + 0.0004, 0, 0)
		new_screen.rotation = Vector3.ZERO
		var disp := PlaneMesh.new()
		disp.size = Vector2(W - 0.0042, L - 0.0042)
		Kit.mi(new_screen, disp, screen_mat, Vector3(0, ST + 0.00003, 0)).name = "Display"
		var glass_mesh := new_screen.get_node("Glass") as MeshInstance3D
		screen_glass = glass_mesh
		shell_meshes.append(glass_mesh)
		var tm: Array[MeshInstance3D] = [glass_mesh]
		target_meshes["screen"] = tm
		var old_target: StaticBody3D = targets["screen"]
		old_target.get_parent().remove_child(old_target)
		new_screen.add_child(old_target)
		old_target.position = Vector3(0, ST, 0)
		screen_node = new_screen)
	return t


func view_transform(view: String) -> Transform3D:
	match view:
		"overview":
			return _view(Vector3(0, 0.0, 0.0), Vector3(0.0, 0.32, 0.22))
		"front":
			return _view(Vector3(-0.012, 0.0, -0.005), Vector3(-0.02, 0.30, 0.17))
		"bottom_edge":
			return _view(Vector3(-0.006, 0.0, L * 0.5 - 0.01), Vector3(0.0, 0.11, L * 0.5 + 0.17))
		"open":
			return _view(Vector3(0.025, 0.02, 0.0), Vector3(0.0, 0.33, 0.19))
		"side":
			return _view(Vector3(W * 0.5, 0.0, -0.02), Vector3(0.15, 0.08, 0.04))
	return _view(Vector3.ZERO, Vector3(0, 0.2, 0.2))


func spawn_part(key: String, global_pos: Vector3) -> void:
	if key == "phone_screen":
		spawn_new_screen(global_pos)
	else:
		super.spawn_part(key, global_pos)


func has_new_part(key: String) -> bool:
	if key == "phone_screen":
		return new_screen != null and is_instance_valid(new_screen) and new_screen.get_parent() == self
	return super.has_new_part(key)
