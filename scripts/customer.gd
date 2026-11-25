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
	var skin := Kit.mat(skin_c, 0.6)
	var shirt := Kit.fabric(shirt_c, 0.9, 0.35, 10.0)
	var pants := Kit.fabric(pants_c, 0.9, 0.4, 10.0)
	var shoe := Kit.mat(Color("1d1f22"), 0.5)
	var hair := Kit.fabric(hair_c, 0.8, 0.25, 30.0)
	hips = Node3D.new()
	hips.position = Vector3(0, 0.88, 0)
	add_child(hips)
	# legs (pivot at the hip)
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.09, 0, 0)
		hips.add_child(leg)
		Kit.capsule(leg, 0.068, 0.5, pants, Vector3(0, -0.24, 0))
		Kit.capsule(leg, 0.058, 0.46, pants, Vector3(0, -0.62, 0))
		var foot := Kit.slab(leg, Vector3(0.1, 0.07, 0.24), 0.04, 0.03, shoe, shoe, shoe, Vector3(0, -0.85, 0.04))
		foot.name = "Shoe"
		if side < 0:
			leg_l = leg
		else:
			leg_r = leg
	# torso
	torso = Node3D.new()
	torso.position = Vector3(0, 0.05, 0)
	hips.add_child(torso)
	Kit.capsule(torso, 0.17, 0.38, pants, Vector3(0, 0.02, 0)).scale = Vector3(1.05, 1, 0.75)
	var chest := Kit.capsule(torso, 0.19, 0.62, shirt, Vector3(0, 0.3, 0))
	chest.scale = Vector3(1.0, 1.0, 0.68)
	Kit.cyl(torso, 0.17, 0.05, shirt, Vector3(0, 0.08, 0)).scale = Vector3(1.05, 1, 0.75)
	Kit.cyl(torso, 0.055, 0.09, skin, Vector3(0, 0.63, 0))
	# arms
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.235, 0.52, 0)
		torso.add_child(arm)
		Kit.sphere(arm, 0.07, shirt, Vector3.ZERO)
		Kit.capsule(arm, 0.058, 0.36, shirt, Vector3(0, -0.17, 0))
		Kit.capsule(arm, 0.048, 0.32, skin, Vector3(0, -0.46, 0))
		Kit.sphere(arm, 0.052, skin, Vector3(0, -0.64, 0.005), Vector3(0.9, 1.1, 0.7))
		arm.rotation.z = side * 0.08
		if side < 0:
			arm_l = arm
		else:
			arm_r = arm
	# head
	head = Node3D.new()
	head.position = Vector3(0, 0.69, 0)
	torso.add_child(head)
	Kit.sphere(head, 0.125, skin, Vector3(0, 0.1, 0), Vector3(0.95, 1.08, 1.0))
	Kit.sphere(head, 0.03, skin, Vector3(-0.122, 0.09, 0), Vector3(0.5, 1, 0.8))
	Kit.sphere(head, 0.03, skin, Vector3(0.122, 0.09, 0), Vector3(0.5, 1, 0.8))
	var white := Kit.mat(Color("fbfbfb"), 0.3)
	var dark := Kit.mat(Color("1a1410"), 0.2)
	for side in [-1.0, 1.0]:
		Kit.sphere(head, 0.022, white, Vector3(side * 0.045, 0.12, 0.105), Vector3(1.0, 1.1, 0.5))
		Kit.sphere(head, 0.012, dark, Vector3(side * 0.045, 0.118, 0.115), Vector3(1, 1, 0.5))
		var brow := Node3D.new()
		brow.position = Vector3(side * 0.047, 0.158, 0.11)
		head.add_child(brow)
		Kit.box(brow, Vector3(0.04, 0.009, 0.008), hair, Vector3.ZERO)
		if side < 0:
			brow_l = brow
		else:
			brow_r = brow
		Kit.sphere(head, 0.02, Kit.mat(skin_c.lerp(Color("ff8a8a"), 0.35), 0.7), Vector3(side * 0.07, 0.075, 0.095), Vector3(1, 0.6, 0.4))
	Kit.sphere(head, 0.018, Kit.mat(skin_c.darkened(0.06), 0.6), Vector3(0, 0.09, 0.122), Vector3(0.8, 1.0, 0.9))
	mouth = Kit.box(head, Vector3(0.05, 0.01, 0.01), Kit.mat(Color("7a3b35"), 0.5), Vector3(0, 0.045, 0.115))
	# hair styles
	match hair_style:
		0:   # short
			Kit.sphere(head, 0.132, hair, Vector3(0, 0.15, -0.012), Vector3(1.0, 0.75, 1.02))
		1:   # long
			Kit.sphere(head, 0.135, hair, Vector3(0, 0.15, -0.015), Vector3(1.02, 0.8, 1.04))
			Kit.capsule(head, 0.11, 0.34, hair, Vector3(0, -0.02, -0.06)).scale = Vector3(1.15, 1, 0.55)
		2:   # bun
			Kit.sphere(head, 0.132, hair, Vector3(0, 0.15, -0.012), Vector3(1.0, 0.75, 1.02))
			Kit.sphere(head, 0.06, hair, Vector3(0, 0.26, -0.07))
		_:   # cap
			Kit.sphere(head, 0.132, hair, Vector3(0, 0.14, -0.02), Vector3(1.0, 0.65, 1.0))
			var cap := Kit.mat(Color.from_hsv(randf(), 0.6, 0.7), 0.6)
			Kit.sphere(head, 0.135, cap, Vector3(0, 0.18, 0), Vector3(1.0, 0.6, 1.0))
			Kit.cyl(head, 0.09, 0.012, cap, Vector3(0, 0.2, 0.11), Vector3(-12, 0, 0)).scale = Vector3(1, 1, 0.9)
	if "glasses" in extras:
		var frame := Kit.mat(Color("1b1b1b"), 0.3, 0.3)
		for side in [-1.0, 1.0]:
			Kit.torus(head, 0.022, 0.028, frame, Vector3(side * 0.045, 0.12, 0.122), Vector3(90, 0, 0))
		Kit.box(head, Vector3(0.03, 0.005, 0.005), frame, Vector3(0, 0.122, 0.124))
	if "beard" in extras:
		Kit.sphere(head, 0.1, hair, Vector3(0, 0.03, 0.04), Vector3(1.05, 0.65, 0.9))
		mouth.position.z = 0.135
	if "apron" in extras:
		Kit.box(torso, Vector3(0.3, 0.55, 0.02), Kit.fabric(Color("5b8a3c"), 0.9), Vector3(0, 0.22, 0.13))
	# carried item holder (in front of the belly)
	carry = Node3D.new()
	carry.position = Vector3(0, 0.12, 0.22)
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
			mouth.scale = Vector3(1.2, 1.8, 1)
			brow_l.rotation.z = 0.15
			brow_r.rotation.z = -0.15
		"sad":
			mouth.scale = Vector3(0.8, 1.0, 1)
			brow_l.rotation.z = -0.3
			brow_r.rotation.z = 0.3
		"worried":
			mouth.scale = Vector3(0.6, 1.4, 1)
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
	var holding := item != null
	arm_l.rotation.x = -0.9 if holding else 0.0
	arm_r.rotation.x = -0.9 if holding else 0.0


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
	# limb animation
	var holding := carry.get_child_count() > 0
	if walking:
		var s := sin(t * 7.5)
		leg_l.rotation.x = s * 0.5
		leg_r.rotation.x = -s * 0.5
		if not holding:
			arm_l.rotation.x = -s * 0.4
			arm_r.rotation.x = s * 0.4
		hips.position.y = 0.88 + absf(cos(t * 7.5)) * 0.025
	else:
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.0, minf(1.0, delta * 8.0))
		leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.0, minf(1.0, delta * 8.0))
		if not holding:
			arm_l.rotation.x = lerpf(arm_l.rotation.x, 0.0, minf(1.0, delta * 6.0))
			arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, minf(1.0, delta * 6.0))
		hips.position.y = 0.88 + sin(t * 1.8) * 0.006
		torso.rotation.x = sin(t * 1.8) * 0.01
	# head looks at the player while waiting
	if look_enabled and not walking:
		var local := to_local(look_target)
		var yaw_h := clampf(atan2(local.x, local.z), -0.8, 0.8)
		head.rotation.y = lerp_angle(head.rotation.y, yaw_h, minf(1.0, delta * 5.0))
	else:
		head.rotation.y = lerp_angle(head.rotation.y, 0.0, minf(1.0, delta * 5.0))
	if bubble.visible:
		bubble.position.y = 2.02 + sin(t * 3.0) * 0.03
