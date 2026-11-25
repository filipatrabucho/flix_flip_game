extends Control
## Tool wheel: five sectors around a centre hub. Mouse direction highlights,
## click / E confirms. Emits `chosen(tool_id)` ("none" = free hand).

signal chosen(id: String)

const Tools = preload("res://scripts/tools3d.gd")
const I18n = preload("res://scripts/i18n.gd")
const ORDER := ["screwdriver", "air", "multimeter", "cloth", "brush"]
const R_OUT := 230.0
const R_IN := 92.0
const GAP := 0.035

var icons: Dictionary = {}          # id -> Texture2D
var current := "screwdriver"
var equipped := "none"
var _title: Label
var _desc: Label
var _icon_nodes: Dictionary = {}
var _font: Font


func setup(icon_textures: Dictionary, font: Font) -> void:
	icons = icon_textures
	_font = font
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in range(ORDER.size()):
		var id: String = ORDER[i]
		var tr := TextureRect.new()
		tr.texture = icons.get(id)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = Vector2(108, 108)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		_icon_nodes[id] = tr
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_constant_override("line_spacing", -6)
	_title.add_theme_color_override("font_color", Color.WHITE)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_desc = Label.new()
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_theme_font_size_override("font_size", 14)
	_desc.add_theme_constant_override("line_spacing", -4)
	_desc.add_theme_color_override("font_color", Color("c9d6e2"))
	_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_desc)
	resized.connect(_layout)
	_layout()


func open(equipped_id: String) -> void:
	equipped = equipped_id
	current = equipped_id if equipped_id in ORDER else "none"
	show()
	_refresh()


func _layout() -> void:
	var c := size * 0.5
	for i in range(ORDER.size()):
		var a := _sector_angle(i)
		var r := (R_OUT + R_IN) * 0.5 + 6.0
		var tr: TextureRect = _icon_nodes[ORDER[i]]
		tr.position = c + Vector2(cos(a), sin(a)) * r - tr.size * 0.5
	_title.size = Vector2(160, 60)
	_title.position = c + Vector2(-80, -58)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_desc.size = Vector2(150, 50)
	_desc.position = c + Vector2(-75, 6)
	queue_redraw()


func _sector_angle(i: int) -> float:
	return -PI * 0.5 + TAU * i / ORDER.size()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var v: Vector2 = event.position - size * 0.5
		var prev := current
		if v.length() < R_IN * 0.9:
			current = "none"
		else:
			var a := fposmod(v.angle() + PI * 0.5 + PI / ORDER.size(), TAU)
			current = ORDER[int(a / (TAU / ORDER.size())) % ORDER.size()]
		if prev != current:
			_refresh()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(current)
		accept_event()


func confirm() -> void:
	chosen.emit(current)


func _refresh() -> void:
	_title.text = I18n.t(Tools.NAMES.get(current, ""))
	_desc.text = I18n.t(Tools.DESCRIPTIONS.get(current, ""))
	for id in _icon_nodes.keys():
		var tr: TextureRect = _icon_nodes[id]
		tr.modulate = Color(1, 1, 1, 1) if id == current else Color(0.82, 0.86, 0.92, 0.9)
		tr.scale = Vector2.ONE
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	# soft shadow + outer ring
	draw_circle(c + Vector2(0, 8), R_OUT + 14, Color(0, 0, 0, 0.35))
	draw_circle(c, R_OUT + 8, Color("0f1724").lerp(Color.BLACK, 0.2))
	var seg := TAU / ORDER.size()
	for i in range(ORDER.size()):
		var id: String = ORDER[i]
		var mid := _sector_angle(i)
		var a0 := mid - seg * 0.5 + GAP
		var a1 := mid + seg * 0.5 - GAP
		var col := Color("1b2738")
		if id == current:
			col = Color("f5b82e")
		elif id == equipped:
			col = Color("2a3e57")
		var pts := PackedVector2Array()
		var steps := 24
		for k in range(steps + 1):
			var a := lerpf(a0, a1, float(k) / steps)
			pts.append(c + Vector2(cos(a), sin(a)) * (R_OUT + (6.0 if id == current else 0.0)))
		for k in range(steps, -1, -1):
			var a := lerpf(a0 + 0.02, a1 - 0.02, float(k) / steps)
			pts.append(c + Vector2(cos(a), sin(a)) * (R_IN + 10))
		draw_colored_polygon(pts, col)
		if id == equipped and id != current:
			draw_arc(c, R_OUT - 6, a0 + 0.02, a1 - 0.02, 24, Color("f5b82e"), 3.0, true)
		# hotkey number
		var hk := str(i + 1) if false else ""
		hk = hk
	# hub
	draw_circle(c, R_IN, Color("141e2c"))
	draw_arc(c, R_IN, 0, TAU, 64, Color("f5b82e") if current == "none" else Color("2c3d55"), 3.0, true)
