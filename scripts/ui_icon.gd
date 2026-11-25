extends Control
## Small vector icons drawn with primitives (no image assets needed).

var kind := "play"
var color := Color.WHITE
var accent := Color("f5b82e")


func setup(k: String, c := Color.WHITE, size_px := 22.0, a := Color("f5b82e")) -> Control:
	kind = k
	color = c
	accent = a
	custom_minimum_size = Vector2(size_px, size_px)
	size = Vector2(size_px, size_px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var c := color
	match kind:
		"play":
			draw_colored_polygon(PackedVector2Array([o + Vector2(s * 0.22, s * 0.12), o + Vector2(s * 0.86, s * 0.5), o + Vector2(s * 0.22, s * 0.88)]), c)
		"folder":
			draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.28), Vector2(s * 0.84, s * 0.56)), c)
			draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.18), Vector2(s * 0.36, s * 0.16)), c)
			draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.4), Vector2(s * 0.84, s * 0.44)), c.lightened(0.15))
		"gear":
			var ctr := o + Vector2(s, s) * 0.5
			for i in range(8):
				var a := TAU * i / 8.0
				var d := Vector2(cos(a), sin(a))
				var p := Vector2(-d.y, d.x)
				draw_colored_polygon(PackedVector2Array([ctr + d * s * 0.3 + p * s * 0.09, ctr + d * s * 0.47 + p * s * 0.07, ctr + d * s * 0.47 - p * s * 0.07, ctr + d * s * 0.3 - p * s * 0.09]), c)
			draw_circle(ctr, s * 0.33, c)
			draw_circle(ctr, s * 0.13, Color(0, 0, 0, 0.0) if false else Color("0f1b2b"))
		"info":
			var ctr := o + Vector2(s, s) * 0.5
			draw_arc(ctr, s * 0.42, 0, TAU, 32, c, s * 0.09, true)
			draw_rect(Rect2(ctr + Vector2(-s * 0.05, -s * 0.06), Vector2(s * 0.1, s * 0.3)), c)
			draw_circle(ctr + Vector2(0, -s * 0.2), s * 0.065, c)
		"power":
			var ctr := o + Vector2(s, s) * 0.5
			draw_arc(ctr, s * 0.36, deg_to_rad(-60), deg_to_rad(240), 32, c, s * 0.1, true)
			draw_line(ctr + Vector2(0, -s * 0.46), ctr + Vector2(0, -s * 0.05), c, s * 0.1, true)
		"calendar":
			draw_rect(Rect2(o + Vector2(s * 0.1, s * 0.18), Vector2(s * 0.8, s * 0.72)), Color("f4f6f8"))
			draw_rect(Rect2(o + Vector2(s * 0.1, s * 0.18), Vector2(s * 0.8, s * 0.22)), Color("e74c3c"))
			for i in range(3):
				for j in range(2):
					draw_rect(Rect2(o + Vector2(s * (0.2 + i * 0.22), s * (0.5 + j * 0.18)), Vector2(s * 0.13, s * 0.1)), Color("7f8c8d"))
			draw_rect(Rect2(o + Vector2(s * 0.26, s * 0.08), Vector2(s * 0.08, s * 0.18)), Color("34495e"))
			draw_rect(Rect2(o + Vector2(s * 0.66, s * 0.08), Vector2(s * 0.08, s * 0.18)), Color("34495e"))
		"clock":
			var ctr := o + Vector2(s, s) * 0.5
			draw_circle(ctr, s * 0.44, accent)
			draw_circle(ctr, s * 0.34, Color("1d2a3a"))
			draw_line(ctr, ctr + Vector2(0, -s * 0.24), Color.WHITE, s * 0.08, true)
			draw_line(ctr, ctr + Vector2(s * 0.17, s * 0.06), Color.WHITE, s * 0.08, true)
		"cash":
			draw_rect(Rect2(o + Vector2(s * 0.04, s * 0.24), Vector2(s * 0.92, s * 0.52)), Color("2ecc71"))
			draw_rect(Rect2(o + Vector2(s * 0.1, s * 0.3), Vector2(s * 0.8, s * 0.4)), Color("27ae60"))
			draw_circle(o + Vector2(s * 0.5, s * 0.5), s * 0.13, Color("a9f5c4"))
			draw_rect(Rect2(o + Vector2(s * 0.0, s * 0.16), Vector2(s * 0.92, s * 0.08)), Color("58d68d"))
		"star":
			var ctr := o + Vector2(s, s) * 0.5
			var pts := PackedVector2Array()
			for i in range(10):
				var a := -PI * 0.5 + PI * i / 5.0
				var r := s * (0.48 if i % 2 == 0 else 0.2)
				pts.append(ctr + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, accent)
		"check":
			draw_polyline(PackedVector2Array([o + Vector2(s * 0.15, s * 0.52), o + Vector2(s * 0.4, s * 0.76), o + Vector2(s * 0.86, s * 0.24)]), Color("2ecc71"), s * 0.16, true)
		"box":
			draw_rect(Rect2(o + Vector2(s * 0.12, s * 0.12), Vector2(s * 0.76, s * 0.76)), c, false, s * 0.08)
		"box_active":
			draw_rect(Rect2(o + Vector2(s * 0.12, s * 0.12), Vector2(s * 0.76, s * 0.76)), accent)
			draw_polyline(PackedVector2Array([o + Vector2(s * 0.28, s * 0.5), o + Vector2(s * 0.45, s * 0.66), o + Vector2(s * 0.74, s * 0.34)]), Color("1a1a1a"), s * 0.1, true)
		"chevron":
			draw_polyline(PackedVector2Array([o + Vector2(s * 0.2, s * 0.3), o + Vector2(s * 0.5, s * 0.6), o + Vector2(s * 0.8, s * 0.3)]), accent, s * 0.14, true)
			draw_polyline(PackedVector2Array([o + Vector2(s * 0.2, s * 0.55), o + Vector2(s * 0.5, s * 0.85), o + Vector2(s * 0.8, s * 0.55)]), accent, s * 0.14, true)
		"mouse_l", "mouse_r", "mouse":
			var r := Rect2(o + Vector2(s * 0.22, s * 0.06), Vector2(s * 0.56, s * 0.88))
			_round_rect(r, s * 0.26, c, false, s * 0.08)
			draw_line(o + Vector2(s * 0.5, s * 0.08), o + Vector2(s * 0.5, s * 0.42), c, s * 0.06)
			draw_line(o + Vector2(s * 0.24, s * 0.42), o + Vector2(s * 0.76, s * 0.42), c, s * 0.06)
			if kind == "mouse_l":
				draw_colored_polygon(PackedVector2Array([o + Vector2(s * 0.27, s * 0.38), o + Vector2(s * 0.27, s * 0.24), o + Vector2(s * 0.36, s * 0.12), o + Vector2(s * 0.47, s * 0.1), o + Vector2(s * 0.47, s * 0.38)]), accent)
			elif kind == "mouse_r":
				draw_colored_polygon(PackedVector2Array([o + Vector2(s * 0.73, s * 0.38), o + Vector2(s * 0.73, s * 0.24), o + Vector2(s * 0.64, s * 0.12), o + Vector2(s * 0.53, s * 0.1), o + Vector2(s * 0.53, s * 0.38)]), accent)
		"hand":
			var ctr := o + Vector2(s, s) * 0.5
			draw_circle(ctr + Vector2(0, s * 0.12), s * 0.26, c)
			for i in range(4):
				draw_line(ctr + Vector2(-s * 0.18 + i * s * 0.12, 0), ctr + Vector2(-s * 0.18 + i * s * 0.12, -s * (0.3 + 0.05 * float(i == 1 or i == 2))), c, s * 0.1, true)
			draw_line(ctr + Vector2(-s * 0.2, s * 0.15), ctr + Vector2(-s * 0.4, -s * 0.02), c, s * 0.1, true)


func _round_rect(r: Rect2, radius: float, c: Color, filled: bool, width: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(radius))
	if filled:
		sb.bg_color = c
	else:
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = c
		sb.set_border_width_all(int(maxf(1.0, width)))
	draw_style_box(sb, r)
