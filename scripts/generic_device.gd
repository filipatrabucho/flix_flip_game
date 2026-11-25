extends "res://scripts/device_base.gd"
## Shared helpers for the extra devices (console, handheld, rotary phone, radio):
## removable cover with screws, flip to reach it, power LED / screen messages,
## a dusty spot to clean and swappable parts.

const I18n = preload("res://scripts/i18n.gd")

var cover: Node3D
var screws: Array[Node3D] = []
var screw_local: Array[Vector3] = []
var screw_rot := Vector3(180, 0, 0)
var screw_axis := Vector3.DOWN
var flipped := false
var flip_rot := Vector3(0, 0, PI)       # rotation of `body` when flipped
var rest_y := 0.03
var rest_y_flipped := 0.03
var led_mat: StandardMaterial3D
var dust: Node3D
var dust_level := 1.0
var sticky := 1.0
var screen_label: Label3D
var cover_lift := Vector3(0, -0.025, 0)


func _init() -> void:
	super._init()


func build_screws(parent: Node3D, spots: Array, radius: float, rot := Vector3(180, 0, 0), color := Color("3a3e44"), ring := 0.006) -> void:
	screw_rot = rot
	for i in range(spots.size()):
		var p: Vector3 = spots[i]
		var s := screw_head(parent, radius, p, rot, color)
		s.name = "Screw%d" % i
		screws.append(s)
		screw_local.append(p)
		add_target("screw%d" % i, parent, Kit.sphere_shape(maxf(0.005, radius * 2.8)), p, [s.get_meta("head_mesh")], ring, rot)


func make_dust(parent: Node3D, pos: Vector3, radius: float, rot := Vector3.ZERO) -> void:
	var dust_mat := Kit.fabric(Color("8f877a"), 1.0, 1.0, 90.0)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.albedo_color = Color(0.56, 0.53, 0.48, 0.9)
	dust = Node3D.new()
	dust.name = "Dust"
	dust.position = pos
	dust.rotation_degrees = rot
	parent.add_child(dust)
	Kit.cyl(dust, radius, 0.0006, dust_mat, Vector3.ZERO)
	for i in range(12):
		var a := randf() * TAU
		var r := randf_range(0.2, 1.0) * radius
		Kit.sphere(dust, radius * 0.08, dust_mat, Vector3(cos(a) * r, -0.0004, sin(a) * r), Vector3(1.6, 0.35, 1.0))


# --- actions -----------------------------------------------------------------
func flip(to_bottom: bool, duration := 0.9) -> Tween:
	flipped = to_bottom
	var t := tw()
	t.tween_property(body, "position:y", 0.12, duration * 0.45)
	t.parallel().tween_property(body, "rotation", flip_rot if to_bottom else Vector3.ZERO, duration)
	t.tween_property(body, "position:y", rest_y_flipped if to_bottom else rest_y, duration * 0.4)
	return t


func unscrew(index: int, tray_global: Vector3) -> Tween:
	return anim_unscrew(screws[index], tray_global, screw_axis)


func screw_in(index: int) -> Tween:
	return anim_screw_in(screws[index], cover, screw_local[index], screw_rot, screw_axis)


func remove_cover(aside_global: Vector3) -> Tween:
	var t := tw()
	t.tween_property(cover, "position", cover.position + cover_lift, 0.4)
	t.tween_callback(func() -> void:
		var gt := cover.global_transform
		cover.get_parent().remove_child(cover)
		add_child(cover)
		cover.global_transform = gt)
	t.tween_property(cover, "global_position", aside_global, 0.6)
	cover.set_meta("home_parent", body)
	return t


func replace_cover() -> Tween:
	var t := tw()
	t.tween_property(cover, "global_position", body.global_transform * cover_lift, 0.5)
	t.tween_callback(func() -> void:
		var gt := cover.global_transform
		remove_child(cover)
		body.add_child(cover)
		cover.global_transform = gt
		cover.rotation = Vector3.ZERO)
	t.tween_property(cover, "position", Vector3.ZERO, 0.35)
	return t


func set_led(on: bool, color := Color("6ec6ff")) -> void:
	if led_mat:
		led_mat.emission = color
		led_mat.albedo_color = color
		led_mat.emission_energy_multiplier = 4.0 if on else 0.0


func power(ok: bool, fail_color := Color("ff4d4d")) -> void:
	if ok:
		set_led(true, Color("6ec6ff"))
	else:
		set_led(true, fail_color)
		get_tree().create_timer(1.4).timeout.connect(func() -> void: set_led(false))


func show_message(text: String, color := Color.WHITE, seconds := 2.0) -> void:
	if screen_label:
		screen_label.text = text
		screen_label.modulate = color
		screen_label.visible = true
		if seconds > 0.0:
			get_tree().create_timer(seconds).timeout.connect(func() -> void: screen_label.visible = false)


func clean() -> bool:
	dust_level = maxf(0.0, dust_level - 0.34)
	if dust:
		var tw2 := tw()
		tw2.tween_property(dust, "scale", Vector3.ONE * (0.4 + dust_level * 0.6), 0.25)
		if dust_level <= 0.01:
			tw2.tween_callback(func() -> void: dust.visible = false)
	return dust_level <= 0.01


func clean_buttons() -> bool:
	sticky = maxf(0.0, sticky - 0.5)
	return sticky <= 0.01


func set_dirty(on: bool) -> void:
	dust_level = 1.0 if on else 0.0
	if dust:
		dust.visible = on
