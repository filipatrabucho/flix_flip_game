extends Node3D
## Stylised customer: walks in through the door, waits at the counter with a
## speech bubble, carries their device and leaves. Real human scale (~1.65 m).

const Kit = preload("res://scripts/kit.gd")

signal arrived

const SKIN := [Color("f2d0b5"), Color("e0b08c"), Color("c68863"), Color("8d5a3b"), Color("5c3a24")]
const HAIR := [Color("2b1d14"), Color("5a3a22"), Color("a9702f"), Color("d9b46a"), Color("1a1a1a"), Color("8a8f96"), Color("b5462f")]
const SHIRTS := [Color("3f7fbf"), Color("d9534f"), Color("5cb85c"), Color("f0ad4e"), Color("8e6fc4"), Color("2f3b4c"), Color("e8e3d9"), Color("2a9d8f")]
const PANTS := [Color("2d3a4f"), Color("3b3b3b"), Color("6b5a45"), Color("1f2a44"), Color("4a5b3d")]

var display_name := ""
var order_id := -1
var role := "customer"            # customer | story
var hips: Node3D
var torso: Node3D
var head: Node3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var carry: Node3D
var bubble: Label3D
var name_tag: Label3D
var mouth: MeshInstance3D
var brow_l: Node3D
var brow_r: Node3D
var pick: StaticBody3D
var path: Array = []
var speed := 1.05
var walking := false
var t := 0.0
var look_target := Vector3.ZERO
var look_enabled := false
var mood := "neutral"
var _arrive_cb: Callable
var height := 1.0
var eyelids: Array = []
var blink_t := 2.0


func setup(cust_name: String, seed_value: int, look := {}) -> void:
	display_name = cust_name
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	height = look.get("height", rng.randf_range(0.92, 1.06))
	var skin: Color = look.get("skin", SKIN[rng.randi() % SKIN.size()])
	var hair_c: Color = look.get("hair", HAIR[rng.randi() % HAIR.size()])
	var shirt: Color = look.get("shirt", SHIRTS[rng.randi() % SHIRTS.size()])
	var pants: Color = look.get("pants", PANTS[rng.randi() % PANTS.size()])
	var hair_style: int = look.get("hair_style", rng.randi() % 4)
	var extras: Array = look.get("extras", [])
	if rng.randf() < 0.25 and not look.has("extras"):
		extras.append("glasses")
	_build(skin, hair_c, shirt, pants, hair_style, extras)
	scale = Vector3.ONE * height


func _build(skin_c: Color, hair_c: Color, shirt_c: Color, pants_c: Color, hair_style: int, extras: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(display_name)
	var skin := Kit.mat(skin_c, 0.55)
	skin.rim_enabled = true
	skin.rim = 0.2
	skin.rim_tint = 0.4
	skin.subsurf_scatter_enabled = true
	skin.subsurf_scatter_strength = 0.25
	skin.normal_enabled = true
	skin.normal_texture = Kit.noise_tex(0.9, true, 1.5, 256)
	skin.normal_scale = 0.12
	skin.uv1_scale = Vector3(6, 6, 6)
	skin.uv1_triplanar = true
	var shirt := Kit.fabric(shirt_c, 0.9, 0.3, 14.0)
	var pants := Kit.fabric(pants_c, 0.92, 0.45, 16.0)
	var shoe := Kit.mat(Color("221d1a") if rng.randf() < 0.6 else Color("e8e8e8"), 0.45)
	var sole := Kit.mat(Color("efefef"), 0.6)
	var hair := Kit.fabric(hair_c, 0.65, 0.35, 60.0)
	hair.anisotropy_enabled = true
	hair.anisotropy = 0.5
	var wide := rng.randf_range(0.92, 1.08)         # shoulder width variation
	var hipw := rng.randf_range(0.94, 1.1)
	var long_sleeves := rng.randf() < 0.5
	var outfit := rng.randi() % 3        # 0 shirt, 1 hoodie, 2 open jacket over t-shirt
	if extras.has("apron") or extras.has("beard"):
		outfit = 0
	var tee_c: Color = [Color("f4f1ea"), Color("2b2f36"), Color("e9c46a"), Color("8ecae6")][rng.randi() % 4]
	var tee := Kit.fabric(tee_c, 0.9, 0.3, 14.0)
	if outfit != 0:
		long_sleeves = true
	hips = Node3D.new()
	hips.position = Vector3(0, 0.92, 0)
	add_child(hips)
	# --- legs: thigh -> knee -> shin -> shoe
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.085 * hipw, -0.02, 0)
		hips.add_child(leg)
		Kit.lathe(leg, [Vector3(-0.45, 0.05, 0.053), Vector3(-0.36, 0.057, 0.06), Vector3(-0.2, 0.068, 0.072), Vector3(-0.06, 0.08, 0.083), Vector3(0.02, 0.078, 0.08)], pants, Vector3.ZERO, Vector3.ZERO, 18)
		var knee := Node3D.new()
		knee.name = "Knee"
		knee.position = Vector3(0, -0.44, 0)
		leg.add_child(knee)
		Kit.sphere(knee, 0.052, pants, Vector3.ZERO)
		Kit.lathe(knee, [Vector3(-0.42, 0.034, 0.036), Vector3(-0.38, 0.037, 0.042), Vector3(-0.28, 0.047, 0.056), Vector3(-0.17, 0.054, 0.062), Vector3(-0.05, 0.05, 0.054), Vector3(0.02, 0.05, 0.052)], pants, Vector3.ZERO, Vector3.ZERO, 18)
		var foot := Node3D.new()
		foot.position = Vector3(0, -0.44, 0)
		knee.add_child(foot)
		Kit.slab(foot, Vector3(0.095, 0.06, 0.25), 0.045, 0.025, shoe, shoe, shoe, Vector3(0, -0.012, 0.045))
		Kit.slab(foot, Vector3(0.1, 0.018, 0.26), 0.047, 0.008, sole, sole, sole, Vector3(0, -0.045, 0.045))
		if side < 0:
			leg_l = leg
		else:
			leg_r = leg
	# --- pelvis + torso (one organic shape), shoulders wider for some people
	torso = Node3D.new()
	torso.position = Vector3(0, 0.0, 0)
	hips.add_child(torso)
	Kit.lathe(torso, [Vector3(-0.1, 0.12 * hipw, 0.085), Vector3(-0.06, 0.16 * hipw, 0.105), Vector3(0.0, 0.168 * hipw, 0.11), Vector3(0.08, 0.158, 0.105)], pants, Vector3.ZERO, Vector3.ZERO, 24)
	Kit.lathe(torso, [Vector3(0.05, 0.16, 0.108), Vector3(0.14, 0.148, 0.102), Vector3(0.24, 0.156, 0.108), Vector3(0.35, 0.176 * wide, 0.118), Vector3(0.45, 0.19 * wide, 0.12), Vector3(0.52, 0.18 * wide, 0.11), Vector3(0.565, 0.13 * wide, 0.085), Vector3(0.59, 0.055, 0.05)], shirt, Vector3.ZERO, Vector3.ZERO, 28)
	Kit.box(torso, Vector3(0.33 * hipw, 0.035, 0.225), Kit.mat(Color("2a211b"), 0.4, 0.2), Vector3(0, 0.065, 0))
	Kit.box(torso, Vector3(0.05, 0.03, 0.01), Kit.chrome(Color("c9b27a")), Vector3(0, 0.065, 0.112))
	match outfit:
		0:
			# collared shirt with buttons and a breast pocket
			Kit.torus(torso, 0.043, 0.06, shirt, Vector3(0, 0.585, 0.0)).scale = Vector3(1.1, 0.6, 1.0)
			for side in [-1.0, 1.0]:
				var col := Kit.box(torso, Vector3(0.06, 0.006, 0.04), shirt, Vector3(side * 0.03, 0.575, 0.06), Vector3(30, side * 25.0, 0))
				col.rotation_degrees.z = side * -20.0
			for i in range(4):
				Kit.cyl(torso, 0.0055, 0.004, Kit.mat(shirt_c.darkened(0.45), 0.4), Vector3(0, 0.5 - i * 0.1, 0.121 - i * 0.002), Vector3(90, 0, 0))
			Kit.box(torso, Vector3(0.002, 0.42, 0.003), Kit.mat(shirt_c.darkened(0.2), 0.8), Vector3(0, 0.33, 0.121))
			Kit.box(torso, Vector3(0.06, 0.07, 0.004), Kit.fabric(shirt_c.darkened(0.08), 0.9), Vector3(-0.07, 0.44, 0.118))
		1:
			# hoodie: hood behind the neck, kangaroo pocket, drawstrings
			Kit.torus(torso, 0.05, 0.075, shirt, Vector3(0, 0.575, -0.02)).scale = Vector3(1.15, 0.9, 1.1)
			Kit.lathe(torso, [Vector3(0.52, 0.09, 0.05), Vector3(0.6, 0.1, 0.06), Vector3(0.68, 0.085, 0.05), Vector3(0.72, 0.0, 0.0)], shirt, Vector3(0, 0, -0.08), Vector3.ZERO, 18)
			Kit.lathe(torso, [Vector3(0.1, 0.11, 0.03), Vector3(0.22, 0.1, 0.03)], Kit.fabric(shirt_c.darkened(0.1), 0.9), Vector3(0, 0, 0.098), Vector3.ZERO, 16)
			for side in [-1.0, 1.0]:
				Kit.cyl(torso, 0.003, 0.14, Kit.mat(Color("f4f6f8"), 0.6), Vector3(side * 0.025, 0.5, 0.118))
				Kit.sphere(torso, 0.006, Kit.mat(Color("d9dde2"), 0.4), Vector3(side * 0.025, 0.43, 0.12))
			Kit.cyl(torso, 0.15, 0.04, Kit.fabric(shirt_c.darkened(0.15), 0.9), Vector3(0, 0.08, 0)).scale = Vector3(1.08, 1, 0.75)
		_:
			# open jacket over a t-shirt: lapels and a zip line
			var panel := Kit.slab(torso, Vector3(0.1, 0.006, 0.42), 0.02, 0.002, tee, tee, tee, Vector3(0, 0.33, 0.118), Vector3(-90, 0, 0))
			panel.rotation_degrees.x = -92.0
			for side in [-1.0, 1.0]:
				var lap := Kit.box(torso, Vector3(0.05, 0.3, 0.012), shirt, Vector3(side * 0.07, 0.4, 0.124), Vector3(0, side * -10.0, side * 8.0))
				lap.name = "Lapel"
				Kit.box(torso, Vector3(0.05, 0.08, 0.012), Kit.fabric(shirt_c.darkened(0.2), 0.9), Vector3(side * 0.085, 0.53, 0.1), Vector3(-20, 0, side * 25.0))
				Kit.box(torso, Vector3(0.002, 0.3, 0.004), Kit.chrome(Color("b8bec5")), Vector3(side * 0.045, 0.35, 0.131))
			Kit.torus(torso, 0.046, 0.058, tee, Vector3(0, 0.58, 0.0)).scale = Vector3(1.1, 0.5, 1.0)
	Kit.lathe(torso, [Vector3(0.55, 0.056, 0.058), Vector3(0.6, 0.052, 0.054), Vector3(0.66, 0.05, 0.052)], skin, Vector3.ZERO, Vector3.ZERO, 16)
	# --- arms: shoulder -> elbow -> forearm -> hand
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.172 * wide, 0.5, 0)
		torso.add_child(arm)
		Kit.sphere(arm, 0.054, shirt, Vector3(0, -0.005, 0), Vector3(1.0, 0.95, 1.0))
		Kit.lathe(arm, [Vector3(-0.3, 0.036, 0.039), Vector3(-0.2, 0.042, 0.046), Vector3(-0.08, 0.05, 0.052), Vector3(0.0, 0.053, 0.053), Vector3(0.035, 0.04, 0.04), Vector3(0.055, 0.0, 0.0)], shirt, Vector3.ZERO, Vector3.ZERO, 16)
		var elbow := Node3D.new()
		elbow.name = "Elbow"
		elbow.position = Vector3(0, -0.29, 0)
		arm.add_child(elbow)
		Kit.sphere(elbow, 0.037, shirt if long_sleeves else skin, Vector3.ZERO)
		Kit.lathe(elbow, [Vector3(-0.26, 0.025, 0.03), Vector3(-0.18, 0.031, 0.036), Vector3(-0.08, 0.037, 0.042), Vector3(0.0, 0.036, 0.04)], shirt if long_sleeves else skin, Vector3.ZERO, Vector3.ZERO, 16)
		if long_sleeves:
			Kit.cyl(elbow, 0.031, 0.02, shirt, Vector3(0, -0.25, 0))
		_hand(elbow, Vector3(0, -0.27, 0), skin, side)
		arm.rotation.z = side * 0.06
		if side < 0:
			arm_l = arm
		else:
			arm_r = arm
	# --- head
	head = Node3D.new()
	head.position = Vector3(0, 0.615, 0.008)
	torso.add_child(head)
	var skull := Kit.lathe(head, [Vector3(0.0, 0.035, 0.03), Vector3(0.012, 0.055, 0.058), Vector3(0.04, 0.072, 0.08), Vector3(0.085, 0.083, 0.092), Vector3(0.14, 0.088, 0.098), Vector3(0.19, 0.086, 0.096), Vector3(0.225, 0.072, 0.083), Vector3(0.25, 0.048, 0.058), Vector3(0.262, 0.018, 0.022), Vector3(0.265, 0.0, 0.0)], skin, Vector3.ZERO, Vector3.ZERO, 28, [0.012, 0.012, 0.01, 0.006, 0.0, -0.004, -0.006, -0.008, -0.008, -0.008])
	skull.name = "Skull"
	# ears
	for side in [-1.0, 1.0]:
		var ear := Kit.sphere(head, 0.024, skin, Vector3(side * 0.088, 0.135, -0.005), Vector3(0.35, 1.0, 0.7))
		ear.rotation.y = side * 0.3
	# eyes with iris, pupil and eyelids (blink)
	var iris_c: Color = [Color("4b3621"), Color("2e6f9e"), Color("4f7942"), Color("6b4f2a"), Color("1e1e1e")][rng.randi() % 5]
	var white := Kit.mat(Color("f7f4ef"), 0.25)
	white.clearcoat_enabled = true
	white.clearcoat = 0.8
	var iris := Kit.mat(iris_c, 0.2)
	var pupil := Kit.mat(Color("070707"), 0.1)
	eyelids.clear()
	for side in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.position = Vector3(side * 0.034, 0.145, 0.08)
		head.add_child(eye)
		Kit.sphere(head, 0.02, Kit.mat(skin_c.darkened(0.12), 0.6), Vector3(side * 0.034, 0.145, 0.074), Vector3(1.15, 0.85, 0.6))
		Kit.sphere(eye, 0.0145, white, Vector3.ZERO)
		Kit.cyl(eye, 0.0075, 0.002, iris, Vector3(0, 0, 0.0132), Vector3(90, 0, 0), -1.0, 20)
		Kit.cyl(eye, 0.0036, 0.0022, pupil, Vector3(0, 0, 0.0138), Vector3(90, 0, 0), -1.0, 16)
		var lid := Node3D.new()
		lid.position = Vector3(0, 0.0, 0.0)
		eye.add_child(lid)
		var lid_mesh := Kit.sphere(lid, 0.0158, skin, Vector3(0, 0.0, 0.0), Vector3(1.0, 1.0, 1.0))
		lid_mesh.position = Vector3(0, 0.0105, 0.002)
		lid_mesh.scale = Vector3(1.05, 0.55, 1.0)
		var lash := Kit.capsule(lid, 0.0012, 0.026, Kit.mat(Color("15100c"), 0.5), Vector3(0, 0.0095, 0.0135), Vector3(0, 0, 90))
		lash.rotation_degrees.x = -25.0
		eyelids.append(lid)
		var brow := Node3D.new()
		brow.position = Vector3(side * 0.036, 0.168, 0.091)
		head.add_child(brow)
		var bm := Kit.capsule(brow, 0.0042, 0.034, hair, Vector3.ZERO, Vector3(0, 0, 90))
		bm.rotation_degrees.z = 90 + side * 6.0
		if side < 0:
			brow_l = brow
		else:
			brow_r = brow
	# nose
	Kit.lathe(head, [Vector3(0.105, 0.016, 0.012), Vector3(0.12, 0.012, 0.012), Vector3(0.15, 0.008, 0.008), Vector3(0.155, 0.0, 0.0)], skin, Vector3.ZERO, Vector3.ZERO, 12, [0.104, 0.106, 0.1, 0.098])
	Kit.sphere(head, 0.013, skin, Vector3(0, 0.112, 0.104), Vector3(1.2, 0.85, 0.9))
	# lips
	var lip := Kit.mat(skin_c.lerp(Color("b5524a"), 0.45), 0.4)
	mouth = Kit.capsule(head, 0.0045, 0.034, lip, Vector3(0, 0.083, 0.094), Vector3(0, 0, 90))
	Kit.capsule(head, 0.0042, 0.03, lip, Vector3(0, 0.077, 0.091), Vector3(0, 0, 90))
	# hair
	match hair_style:
		0:   # short
			Kit.lathe(head, [Vector3(0.13, 0.091, 0.097), Vector3(0.18, 0.094, 0.104), Vector3(0.225, 0.08, 0.091), Vector3(0.255, 0.054, 0.064), Vector3(0.275, 0.0, 0.0)], hair, Vector3.ZERO, Vector3.ZERO, 26, [-0.018, -0.012, -0.01, -0.012, -0.012])
		1:   # long
			Kit.lathe(head, [Vector3(0.12, 0.093, 0.099), Vector3(0.18, 0.096, 0.106), Vector3(0.225, 0.082, 0.093), Vector3(0.255, 0.056, 0.066), Vector3(0.278, 0.0, 0.0)], hair, Vector3.ZERO, Vector3.ZERO, 26, [-0.012, -0.008, -0.008, -0.01, -0.01])
			Kit.lathe(head, [Vector3(-0.12, 0.09, 0.03), Vector3(-0.02, 0.1, 0.045), Vector3(0.1, 0.098, 0.06), Vector3(0.17, 0.094, 0.06)], hair, Vector3(0, 0, -0.045), Vector3.ZERO, 20)
		2:   # bun
			Kit.lathe(head, [Vector3(0.13, 0.091, 0.097), Vector3(0.18, 0.094, 0.103), Vector3(0.225, 0.08, 0.09), Vector3(0.255, 0.053, 0.062), Vector3(0.272, 0.0, 0.0)], hair, Vector3.ZERO, Vector3.ZERO, 26, [-0.02, -0.014, -0.012, -0.012, -0.012])
			Kit.sphere(head, 0.045, hair, Vector3(0, 0.25, -0.07), Vector3(1, 0.9, 1))
		_:   # cap
			Kit.lathe(head, [Vector3(0.13, 0.091, 0.097), Vector3(0.17, 0.093, 0.1)], hair, Vector3.ZERO, Vector3.ZERO, 26, [-0.02, -0.02])
			var cap := Kit.fabric(Color.from_hsv(rng.randf(), 0.6, 0.7), 0.8, 0.3, 30.0)
			Kit.lathe(head, [Vector3(0.17, 0.095, 0.103), Vector3(0.22, 0.088, 0.096), Vector3(0.255, 0.06, 0.068), Vector3(0.275, 0.0, 0.0)], cap, Vector3.ZERO, Vector3.ZERO, 26, [-0.006, -0.006, -0.008, -0.008])
			Kit.slab(head, Vector3(0.15, 0.008, 0.08), 0.035, 0.003, cap, cap, cap, Vector3(0, 0.178, 0.115), Vector3(-10, 0, 0))
	if hair_style in [1, 2] and rng.randf() < 0.6:
		# fringe / bangs
		Kit.lathe(head, [Vector3(0.17, 0.088, 0.03), Vector3(0.215, 0.08, 0.03), Vector3(0.24, 0.06, 0.02)], hair, Vector3(0, 0, 0.068), Vector3.ZERO, 18)
	if hair_style == 0 and rng.randf() < 0.35:
		# curly volume
		for i in range(26):
			var a := rng.randf() * TAU
			var y := rng.randf_range(0.17, 0.27)
			var r := sqrt(maxf(0.0, 1.0 - pow((y - 0.15) / 0.13, 2))) * 0.1
			Kit.sphere(head, 0.028, hair, Vector3(cos(a) * r, y, sin(a) * r * 1.05 - 0.01))
	for side in [-1.0, 1.0]:
		Kit.box(head, Vector3(0.008, 0.035, 0.014), hair, Vector3(side * 0.087, 0.15, 0.02))
	if "glasses" in extras:
		var frame := Kit.mat(Color("1b1b1b"), 0.3, 0.3)
		for side in [-1.0, 1.0]:
			Kit.torus(head, 0.017, 0.0205, frame, Vector3(side * 0.034, 0.145, 0.1), Vector3(90, 0, 0))
			Kit.box(head, Vector3(0.003, 0.003, 0.09), frame, Vector3(side * 0.085, 0.15, 0.055))
		Kit.box(head, Vector3(0.022, 0.003, 0.003), frame, Vector3(0, 0.148, 0.103))
	if "beard" in extras:
		Kit.lathe(head, [Vector3(0.0, 0.04, 0.04), Vector3(0.03, 0.07, 0.075), Vector3(0.075, 0.085, 0.09), Vector3(0.1, 0.087, 0.088)], hair, Vector3.ZERO, Vector3.ZERO, 22, [0.022, 0.02, 0.014, 0.008])
		mouth.position.z = 0.1
	if "apron" in extras:
		Kit.lathe(torso, [Vector3(-0.15, 0.17, 0.125), Vector3(0.1, 0.165, 0.118), Vector3(0.3, 0.17, 0.125)], Kit.fabric(Color("5b8a3c"), 0.9), Vector3(0, 0, 0.004), Vector3.ZERO, 24)
	# carried item holder (in front of the belly)
	carry = Node3D.new()
	carry.position = Vector3(0, 0.22, 0.24)
	torso.add_child(carry)
	# floating name + speech bubble
	name_tag = Label3D.new()
	name_tag.text = display_name
	name_tag.font_size = 48
	name_tag.pixel_size = 0.0013
	name_tag.outline_size = 10
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.no_depth_test = true
	name_tag.position = Vector3(0, 1.88, 0)
	name_tag.modulate = Color("eef3f8")
	add_child(name_tag)
	bubble = Label3D.new()
	bubble.font_size = 96
	bubble.pixel_size = 0.0017
	bubble.outline_size = 18
	bubble.outline_modulate = Color(0, 0, 0, 0.8)
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.position = Vector3(0, 2.02, 0)
	add_child(bubble)
	set_bubble("")
	# pick shape
	pick = Kit.static_body(self, _capsule_shape(), Vector3(0, 0.9, 0), "customer")
	pick.collision_layer = 1
	pick.set_meta("customer", self)


func _hand(parent: Node3D, pos: Vector3, skin: Material, side: float) -> void:
	var h := Node3D.new()
	h.position = pos
	parent.add_child(h)
	Kit.slab(h, Vector3(0.07, 0.024, 0.08), 0.02, 0.01, skin, skin, skin, Vector3(0, -0.035, 0), Vector3(90, 0, 0))
	for i in range(4):
		var x := -0.024 + i * 0.016
		var l := 0.05 - absf(i - 1.5) * 0.007
		var f := Kit.capsule(h, 0.0075, l, skin, Vector3(x, -0.075 - l * 0.35, 0.004), Vector3(8, 0, 0))
		f.rotation_degrees.x = 12.0
	Kit.capsule(h, 0.009, 0.045, skin, Vector3(side * -0.036, -0.04, 0.012), Vector3(20, 0, side * -35.0))


func _capsule_shape() -> CapsuleShape3D:
	var c := CapsuleShape3D.new()
	c.radius = 0.28
	c.height = 1.8
	return c


func set_bubble(kind: String) -> void:
	match kind:
		"!":
			bubble.text = "!"
			bubble.modulate = Color("f5b82e")
		"ok":
			bubble.text = "✓"
			bubble.modulate = Color("2ecc71")
		"talk":
			bubble.text = "…"
			bubble.modulate = Color("eef3f8")
		_:
			bubble.text = ""
	bubble.visible = bubble.text != ""


func set_mood(m: String) -> void:
	mood = m
	match m:
		"happy":
			mouth.scale = Vector3(1.0, 1.25, 1)
			brow_l.rotation.z = 0.15
			brow_r.rotation.z = -0.15
		"sad":
			mouth.scale = Vector3(1.0, 0.85, 1)
			brow_l.rotation.z = -0.3
			brow_r.rotation.z = 0.3
		"worried":
			mouth.scale = Vector3(1.0, 0.75, 1)
			brow_l.rotation.z = -0.2
			brow_r.rotation.z = 0.2
		_:
			mouth.scale = Vector3.ONE
			brow_l.rotation.z = 0.0
			brow_r.rotation.z = 0.0


## Holds a small stand-in of the device in front of the body.
func hold(item: Node3D) -> void:
	for c in carry.get_children():
		c.queue_free()
	if item:
		carry.add_child(item)



func walk_path(points: Array, cb := Callable()) -> void:
	path = points.duplicate()
	walking = not path.is_empty()
	_arrive_cb = cb


func _process(delta: float) -> void:
	t += delta
	if walking and not path.is_empty():
		var target: Vector3 = path[0]
		var to := target - global_position
		to.y = 0
		var dist := to.length()
		if dist < 0.04:
			path.pop_front()
			if path.is_empty():
				walking = false
				arrived.emit()
				if _arrive_cb.is_valid():
					_arrive_cb.call()
		else:
			var dir := to / dist
			global_position += dir * minf(dist, speed * delta)
			var yaw := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, delta * 8.0))
	# limb animation (thigh swing + knee bend, arm swing + elbow bend)
	var holding := carry.get_child_count() > 0
	var kl: Node3D = leg_l.get_node("Knee")
	var kr: Node3D = leg_r.get_node("Knee")
	var el: Node3D = arm_l.get_node("Elbow")
	var er: Node3D = arm_r.get_node("Elbow")
	if walking:
		var s := sin(t * 7.0)
		leg_l.rotation.x = s * 0.45
		leg_r.rotation.x = -s * 0.45
		kl.rotation.x = maxf(0.0, -cos(t * 7.0 + 0.6)) * 0.8
		kr.rotation.x = maxf(0.0, cos(t * 7.0 + 0.6)) * 0.8
		if not holding:
			arm_l.rotation.x = -s * 0.35
			arm_r.rotation.x = s * 0.35
			el.rotation.x = -0.25 - maxf(0.0, s) * 0.2
			er.rotation.x = -0.25 - maxf(0.0, -s) * 0.2
		hips.position.y = 0.92 + absf(cos(t * 7.0)) * 0.02
	else:
		var k := minf(1.0, delta * 8.0)
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.0, k)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.0, k)
		kl.rotation.x = lerpf(kl.rotation.x, 0.0, k)
		kr.rotation.x = lerpf(kr.rotation.x, 0.0, k)
		if not holding:
			arm_l.rotation.x = lerpf(arm_l.rotation.x, 0.0, k)
			arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, k)
			el.rotation.x = lerpf(el.rotation.x, -0.12, k)
			er.rotation.x = lerpf(er.rotation.x, -0.12, k)
		hips.position.y = 0.92 + sin(t * 1.8) * 0.005
		hips.rotation.z = sin(t * 0.35) * 0.025
		torso.rotation.z = -sin(t * 0.35) * 0.02
		torso.rotation.x = sin(t * 1.8) * 0.008
		head.rotation.z = sin(t * 0.5 + 1.0) * 0.04
	if holding:
		arm_l.rotation.x = -0.35
		arm_r.rotation.x = -0.35
		el.rotation.x = -1.15
		er.rotation.x = -1.15
	# blinking
	blink_t -= delta
	var lid_s := 0.0
	if blink_t < 0.12:
		lid_s = 1.0
	if blink_t < 0.0:
		blink_t = randf_range(2.0, 5.0)
	for lid in eyelids:
		(lid as Node3D).rotation.x = lerpf(0.0, 1.2, lid_s)
	# head looks at the player while waiting
	if look_enabled and not walking:
		var local := to_local(look_target)
		var yaw_h := clampf(atan2(local.x, local.z), -0.8, 0.8)
		head.rotation.y = lerp_angle(head.rotation.y, yaw_h, minf(1.0, delta * 5.0))
	else:
		head.rotation.y = lerp_angle(head.rotation.y, 0.0, minf(1.0, delta * 5.0))
	if bubble.visible:
		bubble.position.y = 2.02 + sin(t * 3.0) * 0.03
