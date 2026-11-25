extends Node3D
## Right hand wearing a work glove (knitted back, coated palm, orange cuff).
## Local frame: wrist at origin, fingers point to -Z, back of the hand faces +Y,
## thumb on -X, pinky on +X. Units are metres (real hand size).

const Kit = preload("res://scripts/kit.gd")

const GLOVE := Color("1e2125")
const GLOVE_DARK := Color("101113")
const CUFF := Color("ef7d1a")
const SLEEVE := Color("16202c")

# name: [knuckle x, knuckle z, [phalanx lengths], radius]
const FINGERS := {
	"index": [-0.030, -0.088, [0.044, 0.027, 0.023], 0.0098],
	"middle": [-0.010, -0.093, [0.048, 0.030, 0.024], 0.0100],
	"ring": [0.010, -0.090, [0.045, 0.028, 0.023], 0.0096],
	"pinky": [0.029, -0.080, [0.035, 0.022, 0.020], 0.0086],
}

var joints: Dictionary = {}      # finger -> Array[Node3D] (3 joints)
var thumb_joints: Array[Node3D] = []
var tool_mount: Node3D
var pinch_mount: Node3D
var _pose_target: Dictionary = {}
var _pose_current: Dictionary = {}
var _knit: StandardMaterial3D
var _coat: StandardMaterial3D


func _init() -> void:
	name = "GloveHand"
	_knit = Kit.fabric(GLOVE, 0.95, 0.55, 40.0)
	_coat = Kit.fabric(GLOVE_DARK, 0.62, 0.35, 55.0)
	_coat.clearcoat_enabled = true
	_coat.clearcoat = 0.25
	_coat.clearcoat_roughness = 0.5
	_build()
	set_pose("relaxed", true)


func _build() -> void:
	# --- palm: rounded slabs, tapered towards the wrist
	var palm := Node3D.new()
	palm.name = "Palm"
	add_child(palm)
	Kit.slab(palm, Vector3(0.084, 0.024, 0.060), 0.018, 0.0105, _knit, _knit, _coat, Vector3(0, 0.001, -0.066))
	var heel := Kit.slab(palm, Vector3(0.072, 0.026, 0.060), 0.022, 0.0115, _knit, _knit, _coat, Vector3(0.001, -0.001, -0.026))
	heel.rotation_degrees = Vector3(4, 0, 0)
	# thenar pad (thumb muscle) and knuckle ridge for a believable silhouette
	Kit.sphere(palm, 0.021, _coat, Vector3(-0.024, -0.007, -0.034), Vector3(0.95, 0.6, 1.4))
	Kit.sphere(palm, 0.02, _knit, Vector3(-0.022, 0.002, -0.03), Vector3(1.0, 0.55, 1.5))
	Kit.capsule(palm, 0.012, 0.084, _knit, Vector3(0.0, 0.003, -0.089), Vector3(0, 0, 90))
	# subtle knuckle bumps
	for kx in [-0.030, -0.010, 0.010, 0.029]:
		Kit.sphere(palm, 0.0105, _knit, Vector3(kx, 0.006, -0.090), Vector3(1.0, 0.8, 1.0))

	# --- fingers
	for f in FINGERS.keys():
		var data: Array = FINGERS[f]
		var base := Node3D.new()
		base.name = "%s_0" % f
		base.position = Vector3(data[0], 0.0, data[1])
		add_child(base)
		var list: Array[Node3D] = []
		var parent: Node3D = base
		var lengths: Array = data[2]
		var r: float = data[3]
		for i in range(3):
			var j: Node3D = parent if i == 0 else Node3D.new()
			if i > 0:
				j.name = "%s_%d" % [f, i]
				j.position = Vector3(0, 0, -float(lengths[i - 1]))
				parent.add_child(j)
			var rr: float = r * (1.0 - 0.07 * i)
			var seg_len: float = lengths[i]
			# capsule along -Z
			Kit.capsule(j, rr, seg_len + rr * 1.6, _knit, Vector3(0, 0, -seg_len * 0.5), Vector3(90, 0, 0))
			# coated underside of each phalanx
			var pad := Kit.capsule(j, rr * 0.93, seg_len + rr * 1.2, _coat, Vector3(0, -rr * 0.18, -seg_len * 0.5), Vector3(90, 0, 0))
			pad.scale = Vector3(0.98, 1.0, 0.85)
			if i == 0:
				Kit.sphere(j, rr * 1.05, _knit, Vector3.ZERO)
			list.append(j)
			parent = j
		# finger tip seam
		var tip := Kit.sphere(parent, r * 0.88, _coat, Vector3(0, -0.001, -float(lengths[2]) + 0.001))
		tip.scale = Vector3(1.0, 0.95, 1.1)
		joints[f] = list

	# --- thumb (3 segments starting inside the palm)
	var tb := Node3D.new()
	tb.name = "thumb_0"
	tb.position = Vector3(-0.028, -0.010, -0.026)
	add_child(tb)
	var t_lengths := [0.044, 0.032, 0.027]
	var t_parent: Node3D = tb
	for i in range(3):
		var j: Node3D = t_parent if i == 0 else Node3D.new()
		if i > 0:
			j.name = "thumb_%d" % i
			j.position = Vector3(0, 0, -t_lengths[i - 1])
			t_parent.add_child(j)
		var rr := 0.0125 - 0.0008 * i
		Kit.capsule(j, rr, t_lengths[i] + rr * 1.5, _knit, Vector3(0, 0, -t_lengths[i] * 0.5), Vector3(90, 0, 0))
		var pad := Kit.capsule(j, rr * 0.92, t_lengths[i] + rr * 1.1, _coat, Vector3(0, -rr * 0.2, -t_lengths[i] * 0.5), Vector3(90, 0, 0))
		pad.scale = Vector3(0.98, 1.0, 0.85)
		thumb_joints.append(j)
		t_parent = j

	# --- cuff + sleeve
	var wrist := Kit.cyl(self, 0.033, 0.03, _knit, Vector3(0, -0.001, 0.006), Vector3(90, 0, 0), 0.036)
	wrist.scale = Vector3(1.12, 1.0, 0.70)
	var cuff := Kit.cyl(self, 0.039, 0.045, _knit, Vector3(0, -0.001, 0.040), Vector3(90, 0, 0), 0.034)
	cuff.scale = Vector3(1.12, 1.0, 0.72)
	var band := Kit.cyl(self, 0.0405, 0.014, Kit.fabric(CUFF, 0.8, 0.5, 60.0), Vector3(0, -0.001, 0.066), Vector3(90, 0, 0), 0.0395)
	band.scale = Vector3(1.12, 1.0, 0.74)
	var sleeve := Kit.cyl(self, 0.050, 0.26, Kit.fabric(SLEEVE, 0.95, 0.6, 14.0), Vector3(0, -0.001, 0.20), Vector3(90, 0, 0), 0.043)
	sleeve.scale = Vector3(1.1, 1.0, 0.85)
	var hem := Kit.cyl(self, 0.0455, 0.012, Kit.fabric(Color("17222e"), 0.9, 0.6, 14.0), Vector3(0, -0.001, 0.076), Vector3(90, 0, 0))
	hem.scale = Vector3(1.1, 1.0, 0.85)

	# where tools are held: inside the curled fingers, tool axis = +X (towards pinky)
	tool_mount = Node3D.new()
	tool_mount.name = "ToolMount"
	tool_mount.position = Vector3(0.004, -0.026, -0.100)
	# tool models point their tip to -Y; rotate so -Y maps to +X
	tool_mount.rotation_degrees = Vector3(0, 0, 90)
	add_child(tool_mount)
	# fingertip pinch point (pointing / pressing)
	pinch_mount = Node3D.new()
	pinch_mount.name = "PinchMount"
	add_child(pinch_mount)


## Pose library: curl angles in degrees per joint.
func _pose_data(pose: String) -> Dictionary:
	match pose:
		"grip":
			return {
				"index": [62, 78, 40], "middle": [70, 82, 42], "ring": [74, 84, 44], "pinky": [78, 84, 44],
				"thumb": [[30, 18, 70], [28, 0, 0], [30, 0, 0]], "spread": [3, 0, -3, -7],
			}
		"point":
			return {
				"index": [6, 6, 4], "middle": [68, 88, 50], "ring": [74, 90, 52], "pinky": [78, 90, 52],
				"thumb": [[26, 22, 62], [30, 0, 0], [26, 0, 0]], "spread": [-2, 0, -2, -6],
			}
		"press":
			return {
				"index": [18, 22, 14], "middle": [62, 84, 48], "ring": [70, 86, 50], "pinky": [74, 88, 50],
				"thumb": [[26, 22, 62], [30, 0, 0], [26, 0, 0]], "spread": [-2, 0, -2, -6],
			}
		"pinch":
			return {
				"index": [38, 42, 18], "middle": [44, 50, 24], "ring": [54, 60, 30], "pinky": [62, 66, 32],
				"thumb": [[22, 26, 58], [22, 0, 0], [24, 0, 0]], "spread": [0, 0, -3, -7],
			}
		_:
			return {
				"index": [14, 16, 8], "middle": [18, 20, 10], "ring": [22, 24, 12], "pinky": [26, 26, 14],
				"thumb": [[14, 30, 40], [12, 0, 0], [14, 0, 0]], "spread": [-4, 0, 3, 8],
			}


func set_pose(pose: String, instant := false) -> void:
	_pose_target = _pose_data(pose)
	if instant or _pose_current.is_empty():
		_pose_current = _pose_target.duplicate(true)
		_apply_pose(_pose_current)


func _process(delta: float) -> void:
	if _pose_target.is_empty():
		return
	var k := minf(1.0, delta * 14.0)
	for key in _pose_target.keys():
		var tgt = _pose_target[key]
		var cur = _pose_current[key]
		if key == "thumb":
			for i in range(3):
				var a: Array = cur[i]
				var b: Array = tgt[i]
				for c in range(3):
					a[c] = lerpf(float(a[c]), float(b[c]), k)
		else:
			for i in range(tgt.size()):
				cur[i] = lerpf(float(cur[i]), float(tgt[i]), k)
	_apply_pose(_pose_current)


func _apply_pose(p: Dictionary) -> void:
	var names := ["index", "middle", "ring", "pinky"]
	var spread: Array = p.get("spread", [0, 0, 0, 0])
	for fi in range(names.size()):
		var f: String = names[fi]
		var list: Array[Node3D] = joints[f]
		var curls: Array = p[f]
		for i in range(3):
			list[i].rotation = Vector3(-deg_to_rad(float(curls[i])), deg_to_rad(float(spread[fi])) if i == 0 else 0.0, 0.0)
	var th: Array = p["thumb"]
	for i in range(3):
		var r: Array = th[i]
		thumb_joints[i].rotation = Vector3(-deg_to_rad(float(r[0])), deg_to_rad(float(r[1])), deg_to_rad(float(r[2])))


## Position of the index fingertip in this node's local space.
func index_tip_local() -> Vector3:
	var list: Array[Node3D] = joints["index"]
	var last := list[2]
	var lengths: Array = FINGERS["index"][2]
	var tip_global := last.global_transform * Vector3(0, -0.004, -float(lengths[2]) - 0.006)
	return global_transform.affine_inverse() * tip_global
