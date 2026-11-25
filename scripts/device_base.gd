extends Node3D
## Shared behaviour for repairable devices: click targets, ring markers,
## hover outlines, camera views and small animation helpers.

const Kit = preload("res://scripts/kit.gd")

const LAYER_TARGET := 1
const LAYER_SURFACE := 2
const RING_COLOR := Color(1.0, 0.76, 0.12)

var device_id := ""
var display_name := ""
var body: Node3D                       # flip pivot that holds the whole device
var targets: Dictionary = {}           # id -> StaticBody3D
var target_meshes: Dictionary = {}     # id -> Array[MeshInstance3D] for outline
var markers: Dictionary = {}           # id -> Node3D ring marker
var shell_meshes: Array[MeshInstance3D] = []
var surface_body: StaticBody3D
var device_pick: StaticBody3D
var active_targets: Array = []
var hovered := ""
var _outline: ShaderMaterial
var _outline_soft: ShaderMaterial
var _t := 0.0
var busy := false
static var anim_speed := 1.0


func _init() -> void:
	_outline = Kit.outline_material(Color(1.0, 0.80, 0.16), 3.0)
	_outline_soft = Kit.outline_material(Color(1.0, 0.80, 0.16, 1.0), 2.0)
	body = Node3D.new()
	body.name = "Body"
	add_child(body)


func _process(delta: float) -> void:
	_t += delta
	var s := 1.0 + sin(_t * 5.0) * 0.08
	for id in markers.keys():
		var m: Node3D = markers[id]
		if m.visible:
			m.scale = Vector3(s, 1.0, s)


# --- targets -----------------------------------------------------------------
func add_target(id: String, parent: Node3D, shape: Shape3D, pos: Vector3, meshes: Array = [], ring_radius := 0.0, ring_rot := Vector3.ZERO) -> StaticBody3D:
	var b := Kit.static_body(parent, shape, pos, id)
	b.set_meta("device", device_id)
	b.collision_layer = 0
	b.collision_mask = 0
	targets[id] = b
	var typed: Array[MeshInstance3D] = []
	for m in meshes:
		typed.append(m)
	target_meshes[id] = typed
	if ring_radius > 0.0:
		var holder := Node3D.new()
		holder.name = "Ring_" + id
		holder.position = pos
		holder.rotation_degrees = ring_rot
		parent.add_child(holder)
		var ring_mat := Kit.emissive(RING_COLOR, 3.0, true)
		ring_mat.no_depth_test = false
		Kit.torus(holder, ring_radius, ring_radius + maxf(0.0008, ring_radius * 0.24), ring_mat, Vector3(0, 0.0004, 0))
		holder.visible = false
		markers[id] = holder
	return b


func set_active_targets(ids: Array) -> void:
	active_targets = ids.duplicate()
	for id in targets.keys():
		var b: StaticBody3D = targets[id]
		var on := ids.has(id) and b.is_visible_in_tree()
		b.collision_layer = LAYER_TARGET if on else 0
		if markers.has(id):
			(markers[id] as Node3D).visible = on
	set_hover("")


func refresh_targets() -> void:
	set_active_targets(active_targets)


func set_hover(id: String) -> void:
	if id == hovered:
		return
	if hovered != "" and target_meshes.has(hovered):
		for m in target_meshes[hovered]:
			if is_instance_valid(m):
				m.material_overlay = null
	hovered = id
	if id != "" and target_meshes.has(id):
		for m in target_meshes[id]:
			if is_instance_valid(m):
				m.material_overlay = _outline


func set_device_highlight(on: bool) -> void:
	for m in shell_meshes:
		if is_instance_valid(m):
			m.material_overlay = _outline if on else null


func set_pickable(on: bool) -> void:
	if device_pick:
		device_pick.collision_layer = LAYER_TARGET if on else 0


func make_surface(size: Vector3, pos := Vector3.ZERO) -> void:
	surface_body = Kit.static_body(body, Kit.box_shape(size), pos)
	surface_body.collision_layer = LAYER_SURFACE
	surface_body.collision_mask = 0
	device_pick = Kit.static_body(self, Kit.box_shape(size * Vector3(1.0, 3.0, 1.0) + Vector3(0.02, 0.02, 0.02)), pos)
	device_pick.set_meta("target", "device")
	device_pick.set_meta("device", device_id)
	device_pick.collision_layer = 0
	device_pick.collision_mask = 0


# --- swappable parts ------------------------------------------------------------
var parts: Dictionary = {}     # key -> {node, parent, xform, size, offset, new}


func meshes_of(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(meshes_of(c))
	return out


## Registers a replaceable part. Its click target is `key`; the spare one is `new_<key>`.
func register_part(key: String, node: Node3D, size: Vector3, offset := Vector3.ZERO) -> void:
	parts[key] = {"node": node, "parent": node.get_parent(), "xform": node.transform, "size": size, "offset": offset, "new": null}
	add_target(key, node, Kit.box_shape(size), offset, meshes_of(node), 0.0)


func has_new_part(key: String) -> bool:
	return parts.has(key) and parts[key]["new"] != null


func remove_part(key: String, aside_global: Vector3) -> Tween:
	var node: Node3D = parts[key]["node"]
	var t := tw()
	t.tween_property(node, "global_position", node.global_position + Vector3.UP * 0.025, 0.4)
	t.tween_callback(func() -> void:
		var gt := node.global_transform
		node.get_parent().remove_child(node)
		add_child(node)
		node.global_transform = gt)
	t.tween_property(node, "global_position", aside_global, 0.6)
	t.tween_property(node, "scale", Vector3(0.001, 0.001, 0.001), 0.3)
	t.tween_callback(func() -> void: node.visible = false)
	return t


## Puts a brand-new copy of the part on the mat (inventory is handled by the game).
func spawn_part(key: String, global_pos: Vector3) -> void:
	var info: Dictionary = parts[key]
	var orig: Node3D = info["node"]
	var copy := orig.duplicate() as Node3D
	for c in copy.get_children():
		if c is StaticBody3D:
			copy.remove_child(c)
			c.free()
	var dust := copy.get_node_or_null("Dust")
	if dust:
		dust.visible = false
	copy.visible = true
	copy.scale = Vector3.ONE
	add_child(copy)
	var home_gt: Transform3D = (info["parent"] as Node3D).global_transform * (info["xform"] as Transform3D)
	copy.global_transform = Transform3D(home_gt.basis, global_pos)
	info["new"] = copy
	add_target("new_" + key, copy, Kit.box_shape(info["size"]), info["offset"], meshes_of(copy), 0.0)


func install_part(key: String) -> Tween:
	var info: Dictionary = parts[key]
	var copy: Node3D = info["new"]
	var parent: Node3D = info["parent"]
	var xf: Transform3D = info["xform"]
	var t := tw()
	var home := parent.global_transform * xf
	t.tween_property(copy, "global_position", home.origin + Vector3.UP * 0.03, 0.55)
	t.tween_property(copy, "global_position", home.origin, 0.35)
	t.tween_callback(func() -> void:
		var gt := copy.global_transform
		remove_child(copy)
		parent.add_child(copy)
		copy.global_transform = gt
		copy.transform = xf
		info["node"] = copy
		info["new"] = null)
	return t


## Optional status message on the device screen (overridden by devices with screens).
func show_message(_text: String, _color := Color.WHITE, _seconds := 2.0) -> void:
	pass


# --- helpers -----------------------------------------------------------------
## Unshaded display surface (texture assigned from a SubViewport in _ready).
func _screen_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 1.0, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


func tw() -> Tween:
	var t := create_tween()
	t.set_speed_scale(anim_speed)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_IN_OUT)
	return t


func view_transform(_view: String) -> Transform3D:
	return global_transform


## Camera looking at a local point of this device from a local offset.
func _view(local_target: Vector3, local_eye: Vector3) -> Transform3D:
	var target := global_transform * local_target
	var eye := global_transform * local_eye
	return Transform3D(Basis.looking_at(target - eye, Vector3.UP), eye)


func label3d(parent: Node3D, text: String, size_px: int, pixel: float, color: Color, pos: Vector3, rot := Vector3(-90, 0, 0)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size_px
	l.pixel_size = pixel
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	l.rotation_degrees = rot
	l.shaded = true
	l.double_sided = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	parent.add_child(l)
	return l


## Screw head: countersunk chrome/black head with a Phillips/Torx recess.
func screw_head(parent: Node3D, radius: float, pos: Vector3, rot := Vector3.ZERO, color := Color("2a2d31")) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees = rot
	parent.add_child(n)
	var sp := Node3D.new()
	sp.name = "Spin"
	n.add_child(sp)
	var head_mat := Kit.mat(color, 0.32, 0.85)
	var head := Kit.cyl(sp, radius, radius * 0.45, head_mat, Vector3(0, radius * 0.2, 0), Vector3.ZERO, radius * 0.86, 24)
	var recess := Kit.mat(Color("0b0c0d"), 0.6, 0.5)
	Kit.box(sp, Vector3(radius * 1.15, radius * 0.2, radius * 0.28), recess, Vector3(0, radius * 0.42, 0))
	Kit.box(sp, Vector3(radius * 0.28, radius * 0.2, radius * 1.15), recess, Vector3(0, radius * 0.42, 0))
	# hidden thread, revealed while the screw rises
	var thread := Kit.cyl(sp, radius * 0.5, radius * 3.2, Kit.mat(Color("8d9298"), 0.35, 0.9), Vector3(0, -radius * 1.5, 0), Vector3.ZERO, -1.0, 12)
	thread.name = "Thread"
	n.set_meta("head_mesh", head)
	return n


## Unscrew animation: spin + rise, then fly to a tray position (global).
func anim_unscrew(screw: Node3D, tray_global: Vector3, axis_local := Vector3.UP) -> Tween:
	var t := tw()
	var start := screw.position
	var lift := axis_local.normalized() * 0.006
	t.tween_property(screw, "position", start + lift, 0.55).set_trans(Tween.TRANS_LINEAR)
	var spinner: Node3D = screw.get_node("Spin")
	var spin := tw()
	spin.tween_property(spinner, "rotation:y", spinner.rotation.y - TAU * 3.0, 0.55)
	t.tween_callback(func() -> void:
		var gt := screw.global_transform
		var holder := get_parent()
		screw.get_parent().remove_child(screw)
		holder.add_child(screw)
		screw.global_transform = gt)
	t.tween_property(screw, "global_position", tray_global + Vector3(randf_range(-0.006, 0.006), 0.004, randf_range(-0.006, 0.006)), 0.35)
	return t


## Screw back in: fly from the tray to its hole, spin down.
func anim_screw_in(screw: Node3D, parent: Node3D, local_pos: Vector3, local_rot: Vector3, axis_local := Vector3.UP) -> Tween:
	var t := tw()
	var target_global := parent.global_transform * (local_pos + axis_local.normalized() * 0.006)
	t.tween_property(screw, "global_position", target_global, 0.3)
	t.tween_callback(func() -> void:
		var gt := screw.global_transform
		screw.get_parent().remove_child(screw)
		parent.add_child(screw)
		screw.global_transform = gt
		screw.rotation_degrees = local_rot)
	t.tween_property(screw, "position", local_pos, 0.5).set_trans(Tween.TRANS_LINEAR)
	var spinner: Node3D = screw.get_node("Spin")
	t.parallel().tween_property(spinner, "rotation:y", spinner.rotation.y + TAU * 3.0, 0.5)
	return t
