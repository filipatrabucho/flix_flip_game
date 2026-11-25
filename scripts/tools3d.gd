extends RefCounted
## Real-scale tool models. Every builder returns a Node3D whose origin is the
## grip centre and whose working tip points to -Y. meta "tip" = tip position.

const Kit = preload("res://scripts/kit.gd")

const IDS := ["screwdriver", "brush", "air", "cloth", "multimeter"]
const NAMES := {
	"screwdriver": "Chave de Fendas",
	"brush": "Pincel",
	"air": "Ar Comprimido",
	"cloth": "Pano de Microfibra",
	"multimeter": "Multímetro",
	"none": "Mão",
}
const DESCRIPTIONS := {
	"screwdriver": "Remove e aperta parafusos.",
	"brush": "Limpa pó de ventoinhas e placas.",
	"air": "Sopra pó de grelhas e portas.",
	"cloth": "Limpa ecrãs e superfícies.",
	"multimeter": "Mede tensão e diagnostica avarias.",
	"none": "Pega, abre e liga equipamentos.",
}


static func build(id: String) -> Node3D:
	match id:
		"screwdriver":
			return screwdriver()
		"brush":
			return brush()
		"air":
			return air_can()
		"cloth":
			return cloth()
		"multimeter":
			return multimeter()
	return Node3D.new()


static func screwdriver() -> Node3D:
	var n := Node3D.new()
	n.name = "Screwdriver"
	var yellow := Kit.plastic(Color("f2b316"), 0.32, 0.1)
	yellow.clearcoat_enabled = true
	yellow.clearcoat = 0.6
	var black := Kit.rubber(Color("15171a"))
	# handle: yellow core with black rubber grip zones
	Kit.cyl(n, 0.0125, 0.026, yellow, Vector3(0, 0.040, 0), Vector3.ZERO, 0.0105)
	Kit.sphere(n, 0.0106, yellow, Vector3(0, 0.053, 0), Vector3(1, 0.5, 1))
	Kit.cyl(n, 0.0132, 0.050, black, Vector3(0, 0.002, 0))
	for i in range(6):
		var a := TAU * i / 6.0
		Kit.box(n, Vector3(0.004, 0.046, 0.003), black, Vector3(cos(a) * 0.0132, 0.002, sin(a) * 0.0132), Vector3(0, -rad_to_deg(a), 0))
	Kit.cyl(n, 0.0128, 0.012, yellow, Vector3(0, -0.029, 0), Vector3.ZERO, 0.0128)
	Kit.cyl(n, 0.0128, 0.018, yellow, Vector3(0, -0.044, 0), Vector3.ZERO, 0.0062)
	# chrome ferrule + shaft + tip
	var steel := Kit.chrome()
	Kit.cyl(n, 0.0040, 0.008, steel, Vector3(0, -0.055, 0))
	Kit.cyl(n, 0.0024, 0.074, steel, Vector3(0, -0.095, 0), Vector3.ZERO, -1.0, 16)
	Kit.cyl(n, 0.0008, 0.008, Kit.mat(Color("1e1f22"), 0.3, 0.9), Vector3(0, -0.136, 0), Vector3.ZERO, 0.0024, 12)
	n.set_meta("tip", Vector3(0, -0.140, 0))
	return n


static func brush() -> Node3D:
	var n := Node3D.new()
	n.name = "Brush"
	var wood := Kit.pbr("walnut_pbr", 0.45, 0.0, Color("f0b070"), Vector3(4, 4, 4), true, 0.3)
	var handle := Kit.cyl(n, 0.0075, 0.12, Kit.plastic(Color("e58a1f"), 0.35), Vector3(0, 0.035, 0), Vector3.ZERO, 0.0095)
	handle.scale = Vector3(1.0, 1.0, 0.55)
	Kit.sphere(n, 0.0076, Kit.plastic(Color("e58a1f"), 0.35), Vector3(0, 0.095, 0), Vector3(1, 0.6, 0.55))
	Kit.cyl(n, 0.002, 0.004, Kit.mat(Color("111111")), Vector3(0, 0.088, 0), Vector3(90, 0, 0))
	var ferrule := Kit.slab(n, Vector3(0.026, 0.011, 0.024), 0.004, 0.0015, Kit.chrome(Color("c9ccd0")), null, null, Vector3(0, -0.036, 0), Vector3(90, 0, 0))
	ferrule.name = "Ferrule"
	var bristle_mat := Kit.fabric(Color("e8d2a6"), 0.95, 0.9, 120.0)
	var bristles := Kit.slab(n, Vector3(0.025, 0.0095, 0.034), 0.003, 0.002, bristle_mat, null, null, Vector3(0, -0.063, 0), Vector3(90, 0, 0))
	bristles.scale = Vector3(1.04, 1.0, 1.0)
	var tips := Kit.slab(n, Vector3(0.024, 0.0085, 0.012), 0.002, 0.003, Kit.fabric(Color("cdb98e"), 0.95, 0.9, 120.0), null, null, Vector3(0, -0.081, 0), Vector3(90, 0, 0))
	tips.scale = Vector3(1.0, 1.0, 0.9)
	wood = wood
	n.set_meta("tip", Vector3(0, -0.088, 0))
	return n


static func air_can() -> Node3D:
	var n := Node3D.new()
	n.name = "AirCan"
	var label := Kit.plastic(Color("1e6fd9"), 0.35, 0.05)
	var vp_tex := _can_label_texture(n)
	if vp_tex:
		label = Kit.mat(Color.WHITE, 0.35)
		label.albedo_texture = vp_tex
	Kit.cyl(n, 0.026, 0.13, label, Vector3(0, 0.03, 0), Vector3.ZERO, -1.0, 40)
	Kit.cyl(n, 0.026, 0.012, Kit.chrome(Color("c8ced6")), Vector3(0, 0.101, 0), Vector3.ZERO, 0.021)
	Kit.cyl(n, 0.026, 0.006, Kit.chrome(Color("c8ced6")), Vector3(0, -0.038, 0), Vector3.ZERO, 0.024)
	# actuator + nozzle + red straw (points to -Y after tilting)
	Kit.cyl(n, 0.011, 0.016, Kit.plastic(Color("eef0f2"), 0.4), Vector3(0, 0.114, 0))
	Kit.box(n, Vector3(0.010, 0.008, 0.020), Kit.plastic(Color("eef0f2"), 0.4), Vector3(0, 0.124, -0.010))
	var straw := Kit.tube_mesh(Kit.bezier(Vector3(0, 0.124, -0.02), Vector3(0, 0.124, -0.06), Vector3(0, 0.10, -0.075), Vector3(0, 0.07, -0.08), 12), 0.0018, 8)
	Kit.mi(n, straw, Kit.plastic(Color("d6222a"), 0.4))
	# held upside-down-ish: rotate so the straw end becomes the tip
	var holder := Node3D.new()
	holder.name = "AirCanHolder"
	for c in n.get_children():
		n.remove_child(c)
		holder.add_child(c)
	holder.rotation_degrees = Vector3(-120, 0, 0)
	n.add_child(holder)
	var tip_local := holder.transform * Vector3(0, 0.07, -0.08)
	n.set_meta("tip", tip_local)
	return n


static func _can_label_texture(owner: Node3D) -> Texture2D:
	var vp := Kit.text_viewport(owner, Vector2i(512, 256), func(root: Control) -> void:
		var bg := ColorRect.new()
		bg.color = Color("1667cf")
		bg.size = Vector2(512, 256)
		root.add_child(bg)
		var stripe := ColorRect.new()
		stripe.color = Color("f2f4f7")
		stripe.position = Vector2(0, 150)
		stripe.size = Vector2(512, 46)
		root.add_child(stripe)
		var l := Label.new()
		l.text = "AIR DUSTER"
		l.position = Vector2(40, 52)
		l.add_theme_font_size_override("font_size", 64)
		l.add_theme_color_override("font_color", Color.WHITE)
		root.add_child(l)
		var l2 := Label.new()
		l2.text = "AR COMPRIMIDO  400 ml"
		l2.position = Vector2(40, 156)
		l2.add_theme_font_size_override("font_size", 28)
		l2.add_theme_color_override("font_color", Color("1a2a40"))
		root.add_child(l2)
	, false)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	return vp.get_texture()


static func cloth() -> Node3D:
	var n := Node3D.new()
	n.name = "Cloth"
	var blue := Kit.fabric(Color("5aa9e6"), 0.98, 0.7, 70.0)
	var blue2 := Kit.fabric(Color("4f9bd8"), 0.98, 0.7, 70.0)
	# folded square: three soft layers, slightly offset
	var a := Kit.slab(n, Vector3(0.09, 0.008, 0.075), 0.012, 0.0038, blue, null, null, Vector3(0, -0.010, 0))
	a.rotation_degrees = Vector3(2, 4, -3)
	var b := Kit.slab(n, Vector3(0.086, 0.007, 0.072), 0.014, 0.0034, blue2, null, null, Vector3(0.003, -0.003, 0.002))
	b.rotation_degrees = Vector3(-3, -6, 2)
	var c := Kit.slab(n, Vector3(0.08, 0.006, 0.064), 0.016, 0.003, blue, null, null, Vector3(-0.002, 0.003, -0.003))
	c.rotation_degrees = Vector3(4, 9, 1)
	var hem := Kit.slab(n, Vector3(0.09, 0.0025, 0.006), 0.002, 0.001, Kit.fabric(Color("3d86c4"), 0.98, 0.7, 70.0), null, null, Vector3(0, -0.0058, 0.035))
	hem.rotation_degrees = Vector3(2, 4, -3)
	n.set_meta("tip", Vector3(0, -0.015, 0))
	return n


static func multimeter() -> Node3D:
	var n := Node3D.new()
	n.name = "Multimeter"
	var body := Node3D.new()
	body.name = "Body"
	n.add_child(body)
	var holster := Kit.plastic(Color("f2c218"), 0.6, 0.35)
	var face := Kit.plastic(Color("26292e"), 0.45, 0.2)
	# lying in the XZ plane (screen faces +Y); rotated below so it is held upright
	Kit.slab(body, Vector3(0.078, 0.034, 0.152), 0.016, 0.008, holster)
	Kit.slab(body, Vector3(0.064, 0.004, 0.136), 0.010, 0.0015, face, null, null, Vector3(0, 0.0165, 0.0))
	var lcd := Kit.slab(body, Vector3(0.050, 0.002, 0.034), 0.003, 0.0008, Kit.mat(Color("9fb39a"), 0.25), null, null, Vector3(0, 0.0188, -0.042))
	lcd.name = "LCD"
	var digits := Label3D.new()
	digits.name = "Digits"
	digits.text = "0.00"
	digits.font_size = 64
	digits.pixel_size = 0.00028
	digits.modulate = Color("1b231b")
	digits.outline_size = 0
	digits.rotation_degrees = Vector3(-90, 0, 0)
	digits.position = Vector3(0.002, 0.0202, -0.042)
	digits.shaded = true
	body.add_child(digits)
	var unit := Label3D.new()
	unit.text = "V DC"
	unit.font_size = 24
	unit.pixel_size = 0.0002
	unit.modulate = Color("1b231b")
	unit.outline_size = 0
	unit.rotation_degrees = Vector3(-90, 0, 0)
	unit.position = Vector3(0.017, 0.0202, -0.031)
	body.add_child(unit)
	# dial
	Kit.cyl(body, 0.019, 0.006, Kit.plastic(Color("1a1c1f"), 0.5), Vector3(0, 0.0205, 0.012))
	Kit.box(body, Vector3(0.004, 0.003, 0.016), Kit.plastic(Color("e9edf0"), 0.4), Vector3(0, 0.0245, 0.006), Vector3(0, 35, 0))
	for i in range(8):
		var a := -PI * 0.75 + i * (PI * 1.5 / 7.0)
		Kit.box(body, Vector3(0.001, 0.0006, 0.004), Kit.emissive(Color("e8edf2"), 0.2), Vector3(sin(a) * 0.026, 0.019, 0.012 - cos(a) * 0.026), Vector3(0, -rad_to_deg(a), 0))
	# buttons + jacks
	for i in range(4):
		Kit.slab(body, Vector3(0.011, 0.003, 0.006), 0.002, 0.001, Kit.plastic(Color("3d434b"), 0.5), null, null, Vector3(-0.0195 + i * 0.013, 0.0195, -0.016))
	var jack_red := Kit.plastic(Color("c81e1e"), 0.4)
	var jack_blk := Kit.plastic(Color("0d0d0d"), 0.4)
	Kit.cyl(body, 0.0042, 0.004, jack_blk, Vector3(-0.018, 0.0195, 0.052))
	Kit.cyl(body, 0.0042, 0.004, jack_red, Vector3(0.0, 0.0195, 0.052))
	Kit.cyl(body, 0.0042, 0.004, jack_red, Vector3(0.018, 0.0195, 0.052))
	# probe (red) held next to the body: the tip is the probe point
	var probe := Node3D.new()
	probe.name = "Probe"
	n.add_child(probe)
	Kit.cyl(probe, 0.0045, 0.075, Kit.plastic(Color("c81e1e"), 0.35), Vector3(0, 0.0, 0))
	Kit.cyl(probe, 0.0062, 0.006, Kit.plastic(Color("c81e1e"), 0.35), Vector3(0, -0.030, 0))
	Kit.cyl(probe, 0.0012, 0.022, Kit.chrome(), Vector3(0, -0.045, 0), Vector3.ZERO, -1.0, 12)
	var cable := Kit.tube_mesh(Kit.bezier(Vector3(0, 0.037, 0), Vector3(0, 0.08, 0), Vector3(0.05, 0.09, 0.03), Vector3(0.07, 0.05, 0.06), 14), 0.0018, 8)
	Kit.mi(probe, cable, Kit.plastic(Color("b51a1a"), 0.5))
	body.position = Vector3(0.075, 0.03, 0.02)
	body.rotation_degrees = Vector3(70, 0, -10)
	n.set_meta("tip", Vector3(0, -0.056, 0))
	return n


## Pose used when the item rests on the workbench (relative to bench top).
static func rest_transform(id: String) -> Transform3D:
	match id:
		"screwdriver":
			return Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(-25), deg_to_rad(90))), Vector3(0, 0.0135, 0))
		"brush":
			return Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(20), deg_to_rad(90))), Vector3(0, 0.008, 0))
		"air":
			return Transform3D(Basis.from_euler(Vector3(deg_to_rad(120), 0, 0)), Vector3(0, 0.045, 0))
		"cloth":
			return Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(15), 0)), Vector3(0, 0.0145, 0))
		"multimeter":
			return Transform3D(Basis.IDENTITY, Vector3(0, 0.0, 0))
	return Transform3D.IDENTITY
