extends RefCounted
## Procedural mesh + material helpers used by the whole game.
## Everything is built at real-world scale (1 unit = 1 metre).

const TEX := "res://assets/%s.png"

static var _mat_cache: Dictionary = {}
static var _noise_cache: Dictionary = {}


# -----------------------------------------------------------------------------
# Materials
# -----------------------------------------------------------------------------
static func mat(color: Color, roughness := 0.6, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


static func emissive(color: Color, energy := 2.0, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func glass(tint: Color, roughness := 0.05, alpha := 0.25) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = roughness
	m.metallic = 0.2
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m


## PBR material using the project textures (albedo + normal + roughness).
static func pbr(name: String, roughness := 0.7, metallic := 0.0, tint := Color.WHITE, uv_scale := Vector3.ONE, triplanar := false, normal_strength := 0.6) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s|%s|%s" % [name, roughness, metallic, tint.to_html(), uv_scale, triplanar]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = load(TEX % name)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 1.0
	m.metallic = metallic
	var rough_tex: Texture2D = load(TEX % (name + "_rough"))
	if rough_tex:
		m.roughness_texture = rough_tex
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.roughness = roughness * 1.4
	else:
		m.roughness = roughness
	var normal_tex: Texture2D = load(TEX % (name + "_normal"))
	if normal_tex:
		m.normal_enabled = true
		m.normal_texture = normal_tex
		m.normal_scale = normal_strength
	m.uv1_scale = uv_scale
	m.uv1_triplanar = triplanar
	_mat_cache[key] = m
	return m


## Seamless procedural noise texture (used for fabric, brushed metal, plastic grain...).
static func noise_tex(freq := 0.08, as_normal := false, bump := 4.0, size := 256, kind := FastNoiseLite.TYPE_SIMPLEX_SMOOTH, stretch := Vector2.ONE) -> NoiseTexture2D:
	var key := "%s|%s|%s|%s|%s|%s" % [freq, as_normal, bump, size, kind, stretch]
	if _noise_cache.has(key):
		return _noise_cache[key]
	var n := FastNoiseLite.new()
	n.noise_type = kind
	n.frequency = freq
	n.fractal_octaves = 3
	var t := NoiseTexture2D.new()
	t.width = int(size * stretch.x)
	t.height = int(size * stretch.y)
	t.seamless = true
	t.noise = n
	t.as_normal_map = as_normal
	t.bump_strength = bump
	t.generate_mipmaps = true
	_noise_cache[key] = t
	return t


## Knitted / woven fabric (gloves, cloth, sleeves).
static func fabric(color: Color, roughness := 0.92, weave := 0.35, uv := 18.0) -> StandardMaterial3D:
	var m := mat(color, roughness, 0.0)
	m.normal_enabled = true
	m.normal_texture = noise_tex(0.35, true, 6.0, 256, FastNoiseLite.TYPE_CELLULAR)
	m.normal_scale = weave
	m.uv1_scale = Vector3(uv, uv, uv)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = false
	m.rim_enabled = true
	m.rim = 0.12
	m.rim_tint = 0.8
	return m


## Brushed / anodised aluminium.
static func aluminium(color := Color("9aa3ad"), roughness := 0.34) -> StandardMaterial3D:
	var m := mat(color, roughness, 0.9)
	m.normal_enabled = true
	m.normal_texture = noise_tex(0.9, true, 1.2, 256, FastNoiseLite.TYPE_VALUE, Vector2(4.0, 0.25))
	m.normal_scale = 0.18
	m.uv1_scale = Vector3(14, 14, 14)
	m.uv1_triplanar = true
	m.anisotropy_enabled = true
	m.anisotropy = 0.35
	return m


## Slightly textured plastic.
static func plastic(color: Color, roughness := 0.45, grain := 0.15) -> StandardMaterial3D:
	var m := mat(color, roughness, 0.0)
	m.normal_enabled = true
	m.normal_texture = noise_tex(0.6, true, 2.0)
	m.normal_scale = grain
	m.uv1_scale = Vector3(30, 30, 30)
	m.uv1_triplanar = true
	return m


static func rubber(color := Color("1c1f23")) -> StandardMaterial3D:
	return plastic(color, 0.85, 0.25)


static func chrome(color := Color("d9dde2")) -> StandardMaterial3D:
	return mat(color, 0.12, 1.0)


## Glossy black glass (phone/laptop screens when off).
static func black_glass() -> StandardMaterial3D:
	var m := mat(Color("050607"), 0.04, 0.0)
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.02
	return m


## Constant-pixel-width outline (inverted hull) used as material_overlay.
static func outline_material(color := Color(1.0, 0.78, 0.15), width_px := 3.0) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, shadows_disabled;
uniform vec4 outline_color : source_color = vec4(1.0, 0.78, 0.15, 1.0);
uniform float width_px = 3.0;
uniform float pulse = 1.0;
void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n_view = normalize(mat3(MODELVIEW_MATRIX) * NORMAL);
	vec2 off = (PROJECTION_MATRIX * vec4(n_view, 0.0)).xy;
	if (length(off) > 0.0001) { off = normalize(off); }
	clip.xy += off * width_px * pulse * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
}
void fragment() {
	ALBEDO = outline_color.rgb * 1.6;
	ALPHA = outline_color.a;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("outline_color", color)
	m.set_shader_parameter("width_px", width_px)
	return m


# -----------------------------------------------------------------------------
# Mesh instances
# -----------------------------------------------------------------------------
static func mi(parent: Node, mesh: Mesh, material: Material = null, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, name := "") -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	if material:
		n.material_override = material
	n.position = pos
	n.rotation_degrees = rot_deg
	if name != "":
		n.name = name
	parent.add_child(n)
	return n


static func box(parent: Node, size: Vector3, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return mi(parent, m, material, pos, rot_deg)


static func cyl(parent: Node, radius: float, height: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, top_radius := -1.0, sides := 32) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = radius if top_radius < 0.0 else top_radius
	m.height = height
	m.radial_segments = sides
	m.rings = 1
	return mi(parent, m, material, pos, rot_deg)


static func sphere(parent: Node, radius: float, material: Material, pos := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 24
	m.rings = 12
	var n := mi(parent, m, material, pos)
	n.scale = scale
	return n


static func capsule(parent: Node, radius: float, height: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(height, radius * 2.0 + 0.0001)
	m.radial_segments = 20
	m.rings = 6
	return mi(parent, m, material, pos, rot_deg)


static func torus(parent: Node, inner: float, outer: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 40
	m.ring_segments = 12
	return mi(parent, m, material, pos, rot_deg)


## Rounded slab: rounded-rectangle footprint (corner_r) with rounded top/bottom
## edges (edge_r). Surfaces: 0 = top, 1 = sides, 2 = bottom.
static func slab_mesh(size: Vector3, corner_r: float, edge_r: float, corner_seg := 6, edge_seg := 3) -> ArrayMesh:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	corner_r = clampf(corner_r, 0.0, minf(hx, hz) - 0.00001)
	edge_r = clampf(edge_r, 0.0, minf(hy - 0.00001, corner_r))
	# outline (XZ) with outward normals, clockwise when seen from +Y
	var pts: Array[Vector2] = []
	var nrm: Array[Vector2] = []
	var centers := [Vector2(hx - corner_r, hz - corner_r), Vector2(-hx + corner_r, hz - corner_r), Vector2(-hx + corner_r, -hz + corner_r), Vector2(hx - corner_r, -hz + corner_r)]
	var start_angles := [0.0, PI * 0.5, PI, PI * 1.5]
	for c in range(4):
		for k in range(corner_seg + 1):
			var a: float = start_angles[c] + (PI * 0.5) * float(k) / float(corner_seg)
			var d := Vector2(cos(a), sin(a))
			pts.append(centers[c] + d * corner_r)
			nrm.append(d)
	var n_out := pts.size()
	# rings along the edge profile: bottom arc then top arc
	var ring_inset: Array[float] = []
	var ring_y: Array[float] = []
	var ring_ny: Array[float] = []
	var ring_nh: Array[float] = []
	for j in range(edge_seg + 1):
		var phi := -PI * 0.5 + (PI * 0.5) * float(j) / float(edge_seg)
		ring_inset.append(edge_r * (1.0 - cos(phi)))
		ring_y.append(-hy + edge_r + edge_r * sin(phi))
		ring_ny.append(sin(phi))
		ring_nh.append(cos(phi))
	for j in range(edge_seg + 1):
		var phi := (PI * 0.5) * float(j) / float(edge_seg)
		ring_inset.append(edge_r * (1.0 - cos(phi)))
		ring_y.append(hy - edge_r + edge_r * sin(phi))
		ring_ny.append(sin(phi))
		ring_nh.append(cos(phi))
	var rings := ring_y.size()

	var am := ArrayMesh.new()
	# --- top & bottom caps
	for cap_i in [1, -1]:
		var cap: float = float(cap_i)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var y: float = hy * cap
		var inset := edge_r
		var n := Vector3(0, cap, 0)
		var center := Vector3(0, y, 0)
		var ring_pts: Array[Vector3] = []
		for i in range(n_out):
			var p := pts[i] - nrm[i] * inset
			ring_pts.append(Vector3(p.x, y, p.y))
		for i in range(n_out):
			var a := ring_pts[i]
			var b := ring_pts[(i + 1) % n_out]
			_tri(st, center, a, b, n, n, n, size, true)
		st.generate_tangents()
		st.commit(am)
		if cap > 0.0:
			# side surface right after top so that order is top, side, bottom
			_slab_sides(am, pts, nrm, ring_inset, ring_y, ring_ny, ring_nh, size)
	return am


static func _slab_sides(am: ArrayMesh, pts: Array[Vector2], nrm: Array[Vector2], ring_inset: Array[float], ring_y: Array[float], ring_ny: Array[float], ring_nh: Array[float], size: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_out := pts.size()
	var rings := ring_y.size()
	var perim := 0.0
	var acc: Array[float] = [0.0]
	for i in range(n_out):
		perim += pts[i].distance_to(pts[(i + 1) % n_out])
		acc.append(perim)
	for i in range(n_out):
		var i2 := (i + 1) % n_out
		for j in range(rings - 1):
			var verts: Array[Vector3] = []
			var norms: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for pair in [[i, j], [i2, j], [i2, j + 1], [i, j + 1]]:
				var ii: int = pair[0]
				var jj: int = pair[1]
				var p := pts[ii] - nrm[ii] * ring_inset[jj]
				verts.append(Vector3(p.x, ring_y[jj], p.y))
				norms.append(Vector3(nrm[ii].x * ring_nh[jj], ring_ny[jj], nrm[ii].y * ring_nh[jj]).normalized())
				var u := acc[i] if ii == i else acc[i + 1]
				uvs.append(Vector2(u / maxf(perim, 0.0001) * 8.0, ring_y[jj] / maxf(size.y, 0.0001)))
			_quad(st, verts, norms, uvs)
	st.generate_tangents()
	st.commit(am)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, size: Vector3, planar_uv: bool) -> void:
	var face := (b - a).cross(c - a)
	var avg := na + nb + nc
	# Godot: clockwise winding = front face, i.e. face normal opposite of outward normal
	if face.dot(avg) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	for v in [[a, na], [b, nb], [c, nc]]:
		var p: Vector3 = v[0]
		st.set_normal(v[1])
		if planar_uv:
			st.set_uv(Vector2(p.x / size.x + 0.5, p.z / size.z + 0.5))
		st.add_vertex(p)


static func _quad(st: SurfaceTool, v: Array[Vector3], n: Array[Vector3], uv: Array[Vector2]) -> void:
	for idx in [[0, 1, 2], [0, 2, 3]]:
		var a: int = idx[0]
		var b: int = idx[1]
		var c: int = idx[2]
		var face := (v[b] - v[a]).cross(v[c] - v[a])
		if face.dot(n[a] + n[b] + n[c]) > 0.0:
			var t := b
			b = c
			c = t
		for k in [a, b, c]:
			st.set_normal(n[k])
			st.set_uv(uv[k])
			st.add_vertex(v[k])


## Rounded slab instance with per-surface materials (top, sides, bottom).
static func slab(parent: Node, size: Vector3, corner_r: float, edge_r: float, top: Material, side: Material = null, bottom: Material = null, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, corner_seg := 6, edge_seg := 3) -> MeshInstance3D:
	var mesh := slab_mesh(size, corner_r, edge_r, corner_seg, edge_seg)
	var n := mi(parent, mesh, null, pos, rot_deg)
	n.set_surface_override_material(0, top)
	n.set_surface_override_material(1, side if side else top)
	n.set_surface_override_material(2, bottom if bottom else (side if side else top))
	return n


## Tube along a polyline (cables, wires, pipes).
static func tube_mesh(points: PackedVector3Array, radius: float, sides := 8) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := points.size()
	var prev_up := Vector3.UP
	var ring_list: Array = []
	for i in range(count):
		var t: Vector3
		if i == 0:
			t = (points[1] - points[0]).normalized()
		elif i == count - 1:
			t = (points[i] - points[i - 1]).normalized()
		else:
			t = (points[i + 1] - points[i - 1]).normalized()
		var side := t.cross(prev_up)
		if side.length() < 0.001:
			side = t.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(t).normalized()
		prev_up = up
		var ring: Array = []
		for s in range(sides + 1):
			var a := TAU * float(s) / float(sides)
			var nn := (side * cos(a) + up * sin(a)).normalized()
			ring.append([points[i] + nn * radius, nn, Vector2(float(s) / sides, float(i) / count)])
		ring_list.append(ring)
	for i in range(count - 1):
		for s in range(sides):
			var q := [ring_list[i][s], ring_list[i][s + 1], ring_list[i + 1][s + 1], ring_list[i + 1][s]]
			var v: Array[Vector3] = []
			var n: Array[Vector3] = []
			var uv: Array[Vector2] = []
			for e in q:
				v.append(e[0])
				n.append(e[1])
				uv.append(e[2])
			_quad(st, v, n, uv)
	st.generate_tangents()
	return st.commit()


static func bezier(a: Vector3, b: Vector3, c: Vector3, d: Vector3, steps := 16) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(steps + 1):
		var t := float(i) / steps
		var u := 1.0 - t
		out.append(a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t)
	return out


## Lens shaped leaf, double sided, slightly folded along the midrib.
static func leaf_mesh(length := 0.08, width := 0.045, fold := 0.25) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 8
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	var mid: Array[Vector3] = []
	for i in range(seg + 1):
		var t := float(i) / seg
		var w := sin(t * PI) * width * 0.5 * (1.0 - 0.35 * t)
		var bend := -t * t * length * 0.25
		mid.append(Vector3(0, bend, -t * length))
		left.append(Vector3(-w, bend - w * fold, -t * length))
		right.append(Vector3(w, bend - w * fold, -t * length))
	for i in range(seg):
		for side in [left, right]:
			var v: Array[Vector3] = [mid[i], side[i], side[i + 1], mid[i + 1]]
			var n0 := (v[1] - v[0]).cross(v[3] - v[0]).normalized()
			if n0.y < 0.0:
				n0 = -n0
			var n: Array[Vector3] = [n0, n0, n0, n0]
			var uv: Array[Vector2] = [Vector2(0.5, float(i) / seg), Vector2(0, float(i) / seg), Vector2(0, float(i + 1) / seg), Vector2(0.5, float(i + 1) / seg)]
			_quad(st, v, n, uv)
	return st.commit()


## Text rendered into a texture through a SubViewport (labels, screens, stickers).
static func text_viewport(owner: Node, size: Vector2i, build: Callable, transparent := true) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = transparent
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	owner.add_child(vp)
	var root := Control.new()
	root.size = Vector2(size)
	vp.add_child(root)
	build.call(root)
	return vp


static func static_body(parent: Node3D, shape: Shape3D, pos := Vector3.ZERO, meta := "") -> StaticBody3D:
	var b := StaticBody3D.new()
	b.position = pos
	if meta != "":
		b.set_meta("target", meta)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	b.add_child(cs)
	parent.add_child(b)
	return b


static func box_shape(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s


static func sphere_shape(r: float) -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = r
	return s


## Lathe-like organic mesh: profile = [Vector3(y, radius_x, radius_z), ...] from bottom to top.
## Elliptical rings give smooth bodies, limbs and heads. Caps close both ends.
static func lathe_mesh(profile: Array, segs := 24, z_offset: Array = [], caps := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	var n := profile.size()
	for i in range(n):
		var pr: Vector3 = profile[i]
		var zo: float = z_offset[i] if i < z_offset.size() else 0.0
		var ring: Array = []
		for s in range(segs + 1):
			var a := TAU * float(s) / segs
			ring.append(Vector3(cos(a) * pr.y, pr.x, sin(a) * pr.z + zo))
		rings.append(ring)
	# normals from neighbouring points
	var normals: Array = []
	for i in range(n):
		var row: Array = []
		for s in range(segs + 1):
			var p_prev: Vector3 = rings[maxi(i - 1, 0)][s]
			var p_next: Vector3 = rings[mini(i + 1, n - 1)][s]
			var p_l: Vector3 = rings[i][(s - 1 + segs) % segs]
			var p_r: Vector3 = rings[i][(s + 1) % segs]
			var nrm := (p_r - p_l).cross(p_next - p_prev).normalized()
			if nrm.length() < 0.5:
				nrm = Vector3.UP if i == n - 1 else Vector3.DOWN
			# make sure it points outwards
			var center := Vector3(0, (profile[i] as Vector3).x, 0)
			if nrm.dot(rings[i][s] - center) < 0.0:
				nrm = -nrm
			row.append(nrm)
		normals.append(row)
	for i in range(n - 1):
		for s in range(segs):
			var v: Array[Vector3] = [rings[i][s], rings[i][s + 1], rings[i + 1][s + 1], rings[i + 1][s]]
			var nn: Array[Vector3] = [normals[i][s], normals[i][s + 1], normals[i + 1][s + 1], normals[i + 1][s]]
			var uv: Array[Vector2] = [Vector2(float(s) / segs, float(i) / n), Vector2(float(s + 1) / segs, float(i) / n), Vector2(float(s + 1) / segs, float(i + 1) / n), Vector2(float(s) / segs, float(i + 1) / n)]
			_quad(st, v, nn, uv)
	# caps
	for cap in ([0, n - 1] if caps else []):
		var pr: Vector3 = profile[cap]
		if pr.y < 0.0005 and pr.z < 0.0005:
			continue
		var c := Vector3(0, pr.x, (z_offset[cap] if cap < z_offset.size() else 0.0))
		var nrm := Vector3.DOWN if cap == 0 else Vector3.UP
		for s in range(segs):
			_tri(st, c, rings[cap][s], rings[cap][s + 1], nrm, nrm, nrm, Vector3.ONE, false)

	return st.commit()


static func lathe(parent: Node, profile: Array, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, segs := 24, z_offset: Array = []) -> MeshInstance3D:
	return mi(parent, lathe_mesh(profile, segs, z_offset), material, pos, rot_deg)
