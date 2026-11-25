extends "res://scripts/device_base.gd"
## Wireless game controller at real scale (~155 x 60 x 105 mm).
## Body frame: origin = centre of the main shell, +Y = buttons side, +Z = towards the player.

const W := 0.118
const D := 0.068
const TOP := 0.011           # top of the front shell
const BOT := -0.009          # front shell bottom = interior floor
const CT := 0.0042           # back cover thickness

var cover: Node3D
var screws: Array[Node3D] = []
var screw_local: Array[Vector3] = []
var stick_l: Node3D
var home_led: StandardMaterial3D
var buttons_node: Node3D
var flipped := false
var sticky := 1.0
var shell_color := Color("2a2e35")


func _init() -> void:
	super._init()
	device_id = "gamepad"
	display_name = "Comando"
	name = "Gamepad"
	body.position = Vector3(0, 0.0215, 0)
	var palette := [Color("2a2e35"), Color("e9ecef"), Color("1f4fa0"), Color("b3261e")]
	shell_color = palette[randi() % palette.size()]
	_build()


func _build() -> void:
	var shell := Kit.plastic(shell_color, 0.42, 0.18)
	shell.clearcoat_enabled = true
	shell.clearcoat = 0.3
	var shell_dark := Kit.plastic(shell_color.darkened(0.25), 0.55, 0.25)
	var interior := Kit.plastic(Color("23262b"), 0.6, 0.2)
	var rubber := Kit.rubber(Color("16181b"))
	# --- front shell: centre body + two grips
	var main := Kit.slab(body, Vector3(W, TOP - BOT, D), 0.026, 0.008, shell, shell, interior, Vector3(0, (TOP + BOT) * 0.5, 0), Vector3.ZERO, 10, 4)
	main.name = "Shell"
	shell_meshes.append(main)
	for sx in [-1.0, 1.0]:
		var grip := Kit.capsule(body, 0.021, 0.085, shell, Vector3(sx * 0.048, -0.004, 0.034), Vector3(62, 0, sx * -14.0))
		grip.scale = Vector3(1.0, 1.0, 0.82)
		shell_meshes.append(grip)
		var grip_tex := Kit.capsule(body, 0.0205, 0.06, Kit.rubber(shell_color.darkened(0.35)), Vector3(sx * 0.052, -0.009, 0.044), Vector3(62, 0, sx * -14.0))
		grip_tex.scale = Vector3(1.01, 1.0, 0.82)
		# bumpers + triggers on the back edge
		Kit.slab(body, Vector3(0.036, 0.008, 0.012), 0.005, 0.0035, shell_dark, null, null, Vector3(sx * 0.038, TOP - 0.006, -D * 0.5 - 0.002), Vector3(0, sx * -8.0, 0))
		Kit.slab(body, Vector3(0.026, 0.014, 0.016), 0.006, 0.005, shell_dark, null, null, Vector3(sx * 0.04, BOT + 0.004, -D * 0.5 + 0.002), Vector3(-20, sx * -8.0, 0))
	# --- sticks
	stick_l = _stick(Vector3(-0.033, TOP, -0.009))
	stick_l.name = "StickL"
	_stick(Vector3(0.018, TOP, 0.016))
	add_target("stick_l", stick_l, Kit.sphere_shape(0.013), Vector3(0, 0.006, 0), meshes_of(stick_l), 0.0125)
	# --- d-pad
	var dpad := Node3D.new()
	dpad.position = Vector3(-0.018, TOP, 0.016)
	body.add_child(dpad)
	Kit.cyl(dpad, 0.0115, 0.0012, Kit.plastic(shell_color.darkened(0.4), 0.6), Vector3(0, 0.0003, 0))
	var dp_mat := Kit.plastic(Color("2b2e33"), 0.45)
	Kit.slab(dpad, Vector3(0.0065, 0.0028, 0.019), 0.0012, 0.0008, dp_mat, null, null, Vector3(0, 0.0014, 0))
	Kit.slab(dpad, Vector3(0.019, 0.0028, 0.0065), 0.0012, 0.0008, dp_mat, null, null, Vector3(0, 0.0014, 0))
	# --- ABXY
	buttons_node = Node3D.new()
	buttons_node.name = "Buttons"
	buttons_node.position = Vector3(0.033, TOP, -0.009)
	body.add_child(buttons_node)
	var cols := {"A": [Color("3fb950"), Vector3(0, 0, 0.0085)], "B": [Color("e5534b"), Vector3(0.0085, 0, 0)], "X": [Color("388bfd"), Vector3(-0.0085, 0, 0)], "Y": [Color("e3b341"), Vector3(0, 0, -0.0085)]}
	for k in cols.keys():
		var c: Color = cols[k][0]
		var p: Vector3 = cols[k][1]
		var b := Kit.cyl(buttons_node, 0.0042, 0.003, Kit.plastic(Color("1b1d21"), 0.25), p + Vector3(0, 0.0015, 0), Vector3.ZERO, 0.0040, 24)
		b.name = "Btn" + k
		var l := label3d(buttons_node, k, 40, 0.00012, c, p + Vector3(0, 0.00305, 0))
		l.shaded = false
	add_target("buttons", buttons_node, Kit.box_shape(Vector3(0.028, 0.008, 0.028)), Vector3(0, 0.003, 0), meshes_of(buttons_node), 0.0)
	add_target("btn_a", buttons_node, Kit.sphere_shape(0.0055), Vector3(0, 0.003, 0.0085), [buttons_node.get_node("BtnA")], 0.0058)
	# --- home button with LED logo
	home_led = Kit.emissive(Color("9fd8ff"), 0.0)
	var home := Kit.cyl(body, 0.0058, 0.0016, Kit.plastic(Color("17191c"), 0.3), Vector3(0, TOP + 0.0008, -0.022))
	home.name = "Home"
	Kit.torus(body, 0.0034, 0.0042, home_led, Vector3(0, TOP + 0.0017, -0.022))
	add_target("home", body, Kit.sphere_shape(0.008), Vector3(0, TOP + 0.002, -0.022), [home], 0.0068)
	# small view/menu buttons + USB-C on the back edge
	for sx in [-0.011, 0.011]:
		Kit.slab(body, Vector3(0.0048, 0.0012, 0.0034), 0.0015, 0.0005, Kit.plastic(Color("17191c"), 0.35), null, null, Vector3(sx, TOP + 0.0004, -0.005))
	Kit.slab(body, Vector3(0.0088, 0.0002, 0.003), 0.0014, 0.00005, Kit.mat(Color("0b0c0e"), 0.5), null, null, Vector3(0, TOP - 0.009, -D * 0.5 + 0.0003), Vector3(90, 0, 0))

	# --- back cover with 4 screws
	cover = Node3D.new()
	cover.name = "Cover"
	body.add_child(cover)
	var cv := Kit.slab(cover, Vector3(W - 0.006, CT, D - 0.004), 0.023, 0.0016, interior, shell, shell_dark, Vector3(0, BOT - CT * 0.5, 0), Vector3.ZERO, 10, 3)
	cv.name = "CoverPlate"
	shell_meshes.append(cv)
	label3d(cover, "Comando sem fios  •  Modelo FX-C1  •  5V 0.5A", 22, 0.0001, Color("6c727a"), Vector3(0, BOT - CT - 0.00005, 0.018), Vector3(90, 180, 0))
	add_target("cover", cover, Kit.box_shape(Vector3(W * 0.85, CT + 0.002, D * 0.85)), Vector3(0, BOT - CT * 0.5, 0), [cv], 0.0)
	var spots := [Vector3(-0.042, 0, -0.022), Vector3(0.042, 0, -0.022), Vector3(-0.036, 0, 0.022), Vector3(0.036, 0, 0.022)]
	for i in range(spots.size()):
		var p: Vector3 = spots[i]
		p.y = BOT - CT - 0.00002
		var s := screw_head(cover, 0.0016, p, Vector3(180, 0, 0), Color("3a3e44"))
		s.name = "Screw%d" % i
		screws.append(s)
		screw_local.append(p)
		add_target("screw%d" % i, cover, Kit.sphere_shape(0.0055), p, [s.get_meta("head_mesh")], 0.0058, Vector3(180, 0, 0))

	_build_interior()
	make_surface(Vector3(0.16, 0.04, 0.11))


func _stick(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	body.add_child(n)
	var ring := Kit.mat(Color("101113"), 0.6)
	Kit.cyl(n, 0.0125, 0.0014, ring, Vector3(0, 0.0004, 0))
	Kit.cyl(n, 0.0045, 0.006, Kit.plastic(Color("1b1d20"), 0.45), Vector3(0, 0.003, 0))
	var cap := Kit.cyl(n, 0.0098, 0.0035, Kit.rubber(Color("1d1f23")), Vector3(0, 0.0072, 0), Vector3.ZERO, 0.0092, 32)
	cap.name = "Cap"
	Kit.torus(n, 0.0074, 0.0093, Kit.rubber(Color("131416")), Vector3(0, 0.0089, 0)).scale = Vector3(1, 0.5, 1)
	return n


func _build_interior() -> void:
	var yi := BOT
	var pcb := Kit.plastic(Color("173b2a"), 0.4, 0.2)
	var chip := Kit.plastic(Color("101214"), 0.35, 0.1)
	Kit.slab(body, Vector3(0.1, 0.0012, 0.056), 0.012, 0.0003, pcb, null, pcb, Vector3(0, yi - 0.0006, 0))
	Kit.slab(body, Vector3(0.012, 0.0012, 0.012), 0.001, 0.0003, chip, null, chip, Vector3(0.0, yi - 0.0018, -0.012))
	Kit.slab(body, Vector3(0.008, 0.0010, 0.006), 0.001, 0.0003, chip, null, chip, Vector3(0.012, yi - 0.0017, 0.006))
	# battery pack in the middle
	var bat := Kit.slab(body, Vector3(0.03, 0.0024, 0.022), 0.003, 0.0008, Kit.plastic(Color("2b56a8"), 0.4), null, Kit.plastic(Color("2b56a8"), 0.4), Vector3(0.0, yi - 0.0024, 0.014))
	bat.name = "PadBattery"
	label3d(body, "Li-ion 1200mAh", 22, 0.00008, Color("e8eef6"), Vector3(0.0, yi - 0.00365, 0.014), Vector3(90, 180, 0))
	# right stick module (fixed) and left stick module (replaceable)
	_joystick_module(Vector3(0.018, yi, 0.016), "JoyR")
	var joy := _joystick_module(Vector3(-0.033, yi, -0.009), "JoystickModule")
	register_part("joystick", joy, Vector3(0.022, 0.008, 0.022), Vector3(0, -0.002, 0))
	# rumble motors in the grips
	for sx in [-1.0, 1.0]:
		var m := Kit.cyl(body, 0.0018, 0.012, Kit.chrome(Color("b6bcc3")), Vector3(sx * 0.047, yi - 0.002, 0.02), Vector3(0, 0, 90))
		m.name = "Rumble"


func _joystick_module(pos: Vector3, nm: String) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	n.position = pos
	body.add_child(n)
	var housing := Kit.mat(Color("2c2f34"), 0.5, 0.3)
	var metal := Kit.mat(Color("aeb4bb"), 0.3, 0.9)
	Kit.box(n, Vector3(0.017, 0.0032, 0.017), metal, Vector3(0, -0.0016, 0))
	Kit.box(n, Vector3(0.012, 0.0012, 0.012), housing, Vector3(0, -0.0034, 0))
	Kit.box(n, Vector3(0.004, 0.0016, 0.006), Kit.plastic(Color("2f7a35"), 0.5), Vector3(0.0105, -0.0012, 0))
	Kit.box(n, Vector3(0.006, 0.0016, 0.004), Kit.plastic(Color("2f7a35"), 0.5), Vector3(0, -0.0012, 0.0105))
	return n


# --- actions -----------------------------------------------------------------
func flip(to_bottom: bool, duration := 0.9) -> Tween:
	flipped = to_bottom
	var t := tw()
	t.tween_property(body, "position:y", 0.08, duration * 0.45)
	t.parallel().tween_property(body, "rotation:z", PI if to_bottom else 0.0, duration)
	t.tween_property(body, "position:y", 0.0215 if not to_bottom else 0.0245, duration * 0.4)
	return t


func wiggle_stick(drift: bool) -> void:
	var t := tw()
	t.tween_property(stick_l, "rotation:x", 0.3, 0.15)
	t.tween_property(stick_l, "rotation:x", -0.3, 0.2)
	t.tween_property(stick_l, "rotation:x", 0.12 if drift else 0.0, 0.15)
	if drift:
		t.tween_property(stick_l, "rotation:z", 0.08, 0.2)


func reset_stick() -> void:
	var t := tw()
	t.tween_property(stick_l, "rotation", Vector3.ZERO, 0.2)


func press_a(stuck: bool) -> void:
	var b: Node3D = buttons_node.get_node("BtnA")
	var t := tw()
	t.tween_property(b, "position:y", 0.0002, 0.08)
	if not stuck:
		t.tween_property(b, "position:y", 0.0015, 0.12)
	else:
		t.tween_interval(0.6)
		t.tween_property(b, "position:y", 0.0015, 0.5)


func clean_buttons() -> bool:
	sticky = maxf(0.0, sticky - 0.5)
	return sticky <= 0.01


func set_led(on: bool) -> void:
	home_led.emission_energy_multiplier = 4.0 if on else 0.0


func show_message(_text: String, _color := Color.WHITE, _seconds := 2.0) -> void:
	set_led(true)
	get_tree().create_timer(1.5).timeout.connect(func() -> void: set_led(false))


func unscrew(index: int, tray_global: Vector3) -> Tween:
	return anim_unscrew(screws[index], tray_global, Vector3.DOWN)


func screw_in(index: int) -> Tween:
	return anim_screw_in(screws[index], cover, screw_local[index], Vector3(180, 0, 0), Vector3.DOWN)


func remove_cover(aside_global: Vector3) -> Tween:
	var t := tw()
	t.tween_property(cover, "position:y", -0.025, 0.4)
	t.tween_callback(func() -> void:
		var gt := cover.global_transform
		body.remove_child(cover)
		add_child(cover)
		cover.global_transform = gt)
	t.tween_property(cover, "global_position", aside_global, 0.6)
	return t


func replace_cover() -> Tween:
	var t := tw()
	t.tween_property(cover, "global_position", body.global_transform * Vector3(0, -0.025, 0), 0.5)
	t.tween_callback(func() -> void:
		var gt := cover.global_transform
		remove_child(cover)
		body.add_child(cover)
		cover.global_transform = gt
		cover.rotation = Vector3.ZERO)
	t.tween_property(cover, "position", Vector3.ZERO, 0.35)
	return t


func view_transform(view: String) -> Transform3D:
	match view:
		"overview", "front":
			return _view(Vector3(0, 0.0, 0.01), Vector3(0.0, 0.27, 0.19))
		"bottom", "interior":
			return _view(Vector3(0, 0.0, 0.0), Vector3(0.02, 0.27, 0.18))
	return _view(Vector3.ZERO, Vector3(0, 0.27, 0.2))
