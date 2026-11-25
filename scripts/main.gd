extends Node3D
## Fix & Flip Tech — game controller: menu, workshop walk mode, repair
## (inspect) mode with a gloved hand, tool wheel, HUD and progression.

const Kit = preload("res://scripts/kit.gd")
const Room = preload("res://scripts/room.gd")
const Laptop = preload("res://scripts/laptop.gd")
const Phone = preload("res://scripts/phone.gd")
const Gamepad = preload("res://scripts/gamepad.gd")
const Data = preload("res://scripts/jobs_data.gd")
const Hand = preload("res://scripts/glove_hand.gd")
const Tools = preload("res://scripts/tools3d.gd")
const UIcon = preload("res://scripts/ui_icon.gd")
const Radial = preload("res://scripts/radial_menu.gd")

const SAVE_PATH := "user://fix_flip_save.json"
const SETTINGS_PATH := "user://fix_flip_settings.cfg"
const VERSION := "v0.9"

const YELLOW := Color("f5b82e")
const PANEL_BG := Color(0.035, 0.06, 0.1, 0.84)
const PANEL_BORDER := Color(1, 1, 1, 0.07)
const TEXT := Color("eef3f8")
const MUTED := Color("9fb0c2")
const GREEN := Color("2ecc71")

const MAT_Y := 0.923
const EYE_H := 1.62
const LAPTOP_POS := Vector3(-0.13, MAT_Y, -1.22)
const PHONE_POS := Vector3(0.29, MAT_Y, -1.17)
const TRAY_POS := Vector3(0.24, MAT_Y, -1.47)
const COVER_ASIDE := Vector3(-0.15, MAT_Y - 0.0046, -1.565)
const OLD_PART_BIN := Vector3(-1.7, 0.45, -0.3)
const NEW_BATTERY_POS := Vector3(0.115, MAT_Y + 0.0002, -1.24)
const NEW_SCREEN_POS := Vector3(0.475, MAT_Y + 0.0002, -1.2)
const OLD_SCREEN_ASIDE := Vector3(0.47, MAT_Y + 0.0003, -1.42)

const TOOL_SPOTS := {
	"screwdriver": [Vector3(0.66, 0.92, -1.04), -32.0],
	"brush": [Vector3(0.70, 0.92, -1.27), 12.0],
	"air": [Vector3(0.86, 0.92, -1.48), 0.0],
	"cloth": [Vector3(-0.60, 0.92, -1.40), 18.0],
	"multimeter": [Vector3(-0.63, 0.92, -1.14), 16.0],
}

const GAMEPAD_POS := Vector3(0.33, MAT_Y, -1.02)
const SLOT_POS := {"laptop": [LAPTOP_POS, 4.0], "phone": [PHONE_POS, -12.0], "gamepad": [GAMEPAD_POS, 8.0]}
const PART_POS := {"laptop": NEW_BATTERY_POS, "phone": NEW_SCREEN_POS, "gamepad": Vector3(0.50, MAT_Y + 0.0002, -1.02)}
const COVER_ASIDE_BY := {"laptop": COVER_ASIDE, "gamepad": Vector3(0.10, MAT_Y + 0.0002, -0.99)}

# --- world --------------------------------------------------------------------
var room: Room
var cam: Camera3D
var devices: Dictionary = {}           # id -> device node
var hand: Node3D
var hand_tools: Dictionary = {}        # id -> Node3D held in the hand
var bench_tools: Dictionary = {}       # id -> Node3D prop on the bench
var tool_tips: Dictionary = {}         # id -> tip position in hand space
var icon_tex: Dictionary = {}
var tray: Node3D

# --- state --------------------------------------------------------------------
var mode := "menu"                     # menu | walk | inspect | wheel | popup | pause
var prev_mode := "walk"
var day := 1
var minutes := 8 * 60.0
var money := 250.0
var xp := 0
var level := 1
var repaired := 0
var day_profit := 0.0
var tool := "none"
var jobs: Dictionary = {}              # device id -> {order, fault, step, progress, diagnosed, done, used}
var orders: Array = []                 # customer orders (new / accepted / repair)
var inventory: Dictionary = {}         # part key -> count
var ratings: Array = []                # customer star ratings
var next_order_at := 0.0
var order_seq := 0
var FAULTS: Dictionary = Data.faults()
var active_device := ""
var focus_job := "laptop"
var walk_yaw := 0.0
var walk_pitch := -0.42
var hovered_pick := ""
var hovered_target := ""
var inspect_base := Transform3D()
var inspect_focus := Vector3.ZERO
var orbit := Vector2.ZERO
var zoom := 1.0
var rotating := false
var cam_tween: Tween
var hand_press := 0.0
var hand_twist := 0.0
var settings := {"quality": 1, "sensitivity": 1.0, "fullscreen": false}

# --- ui -----------------------------------------------------------------------
var ui: CanvasLayer
var font_bold: Font
var font_xbold: Font
var theme_main: Theme
var menu_root: Control
var menu_buttons: VBoxContainer
var menu_panel_host: Control
var load_button: Button
var hud: Control
var day_label: Label
var time_label: Label
var money_label: Label
var level_label: Label
var xp_label: Label
var xp_bar: ProgressBar
var objective_panel: PanelContainer
var objective_title: Label
var objective_rows: VBoxContainer
var repair_panel: PanelContainer
var repair_title: Label
var repair_rows: VBoxContainer
var step_hint: Label
var prompt: PanelContainer
var prompt_label: Label
var hotbar: HBoxContainer
var hotbar_slots: Dictionary = {}
var hints_bar: HBoxContainer
var toast: PanelContainer
var toast_label: Label
var crosshair: Control
var reticle: Control
var wheel_root: Control
var wheel: Control
var popup_root: Control
var popup_box: VBoxContainer
var pause_root: Control
var fade: ColorRect
var meter_panel: PanelContainer
var board_root: Control
var board_box: VBoxContainer
var board_kind := ""
var orders_badge: Label
var meter_label: Label


func _ready() -> void:
	randomize()
	_load_settings()
	_load_fonts()
	room = Room.new()
	room.build(self)
	_build_camera()
	_build_tray()
	_build_tools()
	_build_hand()
	_reset_jobs()
	_build_icons()
	_build_ui()
	_apply_settings()
	_show_menu()


# =============================================================================
# World setup
# =============================================================================
func _load_fonts() -> void:
	font_bold = _font("res://assets/fonts/Nunito-Bold.ttf")
	font_xbold = _font("res://assets/fonts/Nunito-ExtraBold.ttf")


func _font(path: String) -> Font:
	var f: Font = null
	if ResourceLoader.exists(path):
		f = load(path)
	if f == null:
		var ff := FontFile.new()
		if ff.load_dynamic_font(path) == OK:
			f = ff
	if f == null:
		f = ThemeDB.fallback_font
	return f


func _build_camera() -> void:
	cam = Camera3D.new()
	cam.name = "PlayerCamera"
	cam.fov = 60.0
	cam.near = 0.01
	cam.far = 40.0
	cam.current = true
	add_child(cam)
	_reset_walk_camera()


func _reset_walk_camera() -> void:
	cam.position = Vector3(0.0, EYE_H, -0.25)
	walk_yaw = 0.0
	walk_pitch = -0.46
	cam.rotation = Vector3(walk_pitch, walk_yaw, 0)


func _build_tray() -> void:
	# magnetic screw tray (blue anodised)
	tray = Node3D.new()
	tray.name = "ScrewTray"
	add_child(tray)
	tray.position = TRAY_POS
	tray.rotation_degrees.y = 8
	var blue := Kit.mat(Color("2f6fd6"), 0.3, 0.7)
	Kit.slab(tray, Vector3(0.13, 0.012, 0.09), 0.012, 0.004, Kit.mat(Color("15181c"), 0.6), blue, blue, Vector3(0, 0.006, 0))
	Kit.slab(tray, Vector3(0.115, 0.002, 0.075), 0.01, 0.0008, Kit.mat(Color("101215"), 0.7), null, null, Vector3(0, 0.0115, 0))


func _build_tools() -> void:
	for id in Tools.IDS:
		var prop := Tools.build(id)
		prop.name = "Bench_" + id
		add_child(prop)
		var spot: Array = TOOL_SPOTS[id]
		var rest := Tools.rest_transform(id)
		if id == "multimeter":
			var body: Node3D = prop.get_node("Body")
			body.position = Vector3(0, 0.017, 0)
			body.rotation = Vector3.ZERO
			var probe: Node3D = prop.get_node("Probe")
			probe.position = Vector3(0.065, 0.006, 0.02)
			probe.rotation_degrees = Vector3(0, 0, 90)
		prop.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(spot[1])), spot[0]) * rest
		bench_tools[id] = prop
		var pick := Kit.static_body(self, Kit.box_shape(Vector3(0.16, 0.08, 0.16)), spot[0] + Vector3(0, 0.03, 0), "tool:" + id)
		pick.collision_layer = 1
		pick.set_meta("tool", id)
		prop.set_meta("pick", pick)


func _build_hand() -> void:
	hand = Hand.new()
	add_child(hand)
	hand.visible = false
	for id in Tools.IDS:
		var t := Tools.build(id)
		t.name = "Held_" + id
		if id == "cloth":
			# the cloth sits flat under the palm instead of in the fist
			hand.add_child(t)
			t.position = Vector3(0.0, -0.034, -0.085)
			tool_tips[id] = t.position + Vector3(0, -0.012, 0)
		else:
			hand.tool_mount.add_child(t)
			if id == "air":
				# can body sits in the fist, slightly away from the palm
				t.position = Vector3(-0.012, -0.03, 0.0)
			elif id == "brush":
				t.position = Vector3(0.0, -0.035, 0.0)
			elif id == "multimeter":
				t.position = Vector3(0.0, 0.0, 0.0)
				(t.get_node("Body") as Node3D).visible = false
			var tip: Vector3 = t.get_meta("tip")
			tool_tips[id] = hand.tool_mount.transform * (t.transform * tip)
		t.visible = false
		hand_tools[id] = t


func _reset_jobs() -> void:
	for d in devices.values():
		if is_instance_valid(d):
			d.queue_free()
	devices.clear()
	jobs.clear()


func _fault(id: String) -> Dictionary:
	return FAULTS[jobs[id]["fault"]]


func _dev_name(id: String) -> String:
	return str(Data.DEVICES[id]["name"])


## Puts a customer's device on its bench slot, set up for its fault.
func _spawn_device(id: String, order: Dictionary) -> void:
	if devices.has(id) and is_instance_valid(devices[id]):
		devices[id].queue_free()
	var d: Node3D
	match id:
		"laptop":
			d = Laptop.new()
		"phone":
			d = Phone.new()
		_:
			d = Gamepad.new()
	var slot: Array = SLOT_POS[id]
	d.position = slot[0]
	d.rotation_degrees.y = slot[1]
	add_child(d)
	devices[id] = d
	d.set_pickable(true)
	var fk: String = order["fault"]
	if id == "laptop":
		d.set_dirty(fk == "laptop_battery" or fk == "laptop_fan")
	elif id == "phone" and fk != "phone_screen":
		d.set_screen_ok()
	jobs[id] = {"order": order, "fault": fk, "step": 0, "progress": 0, "diagnosed": false, "done": false, "used": []}
	order["status"] = "repair"


## Renders each tool once into a transparent texture (hotbar / wheel icons).
func _build_icons() -> void:
	for id in Tools.IDS:
		var vp := SubViewport.new()
		vp.size = Vector2i(192, 192)
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.msaa_3d = Viewport.MSAA_4X
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(vp)
		var root3d := Node3D.new()
		vp.add_child(root3d)
		var we := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_CLEAR_COLOR
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color("c8d4e6")
		e.ambient_light_energy = 0.7
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		we.environment = e
		root3d.add_child(we)
		var key := DirectionalLight3D.new()
		key.rotation_degrees = Vector3(-45, -35, 0)
		key.light_energy = 1.6
		root3d.add_child(key)
		var rim := DirectionalLight3D.new()
		rim.rotation_degrees = Vector3(-20, 150, 0)
		rim.light_energy = 0.9
		rim.light_color = Color("9fd3ff")
		root3d.add_child(rim)
		var t := Tools.build(id)
		root3d.add_child(t)
		var c := Camera3D.new()
		c.projection = Camera3D.PROJECTION_ORTHOGONAL
		root3d.add_child(c)
		match id:
			"screwdriver":
				t.rotation_degrees = Vector3(0, 0, -45)
				t.position = Vector3(0.0, 0.045, 0)
				c.size = 0.19
			"brush":
				t.rotation_degrees = Vector3(0, 0, -40)
				t.position = Vector3(0.0, 0.0, 0)
				c.size = 0.16
			"air":
				t.rotation_degrees = Vector3(12, -30, -18)
				t.position = Vector3(0.0, -0.045, 0)
				c.size = 0.2
			"cloth":
				t.rotation_degrees = Vector3(55, 30, 0)
				c.size = 0.115
			"multimeter":
				var body: Node3D = t.get_node("Body")
				body.position = Vector3.ZERO
				body.rotation_degrees = Vector3(78, 0, 0)
				var probe: Node3D = t.get_node("Probe")
				probe.position = Vector3(0.055, -0.02, 0.05)
				probe.rotation_degrees = Vector3(0, 0, -25)
				c.size = 0.17
		c.position = Vector3(0, 0, 0.6)
		icon_tex[id] = vp.get_texture()
		_freeze_viewport_later(vp)


func _freeze_viewport_later(vp: SubViewport) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE


# =============================================================================
# Main loop
# =============================================================================
func _process(delta: float) -> void:
	if mode in ["walk", "inspect", "wheel"]:
		minutes += delta * (1.0 if mode != "wheel" else 0.25)
		if minutes >= 20 * 60:
			_end_of_day()
		elif mode != "wheel":
			_order_tick()
	match mode:
		"walk":
			_walk_move(delta)
			_walk_hover()
			_update_hand_walk(delta)
		"inspect":
			_update_inspect_camera(delta)
			_inspect_hover()
			_update_hand_inspect(delta)
		"wheel":
			pass
	if hud and hud.visible:
		_update_hud_values()
	if reticle and reticle.visible:
		reticle.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event as InputEventKey)
	match mode:
		"walk":
			if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				var sens: float = 0.0024 * float(settings["sensitivity"])
				walk_yaw -= event.relative.x * sens
				walk_pitch = clampf(walk_pitch - event.relative.y * sens, -1.35, 1.2)
				cam.rotation = Vector3(walk_pitch, walk_yaw, 0)
			elif event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
						Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
					else:
						_interact_walk()
				elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
					_cycle_tool(-1)
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_cycle_tool(1)
		"inspect":
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_inspect_click()
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					rotating = event.pressed
				elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
					zoom = clampf(zoom - 0.08, 0.55, 1.35)
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
					zoom = clampf(zoom + 0.08, 0.55, 1.35)
			elif event is InputEventMouseMotion and rotating:
				orbit.x = clampf(orbit.x - event.relative.x * 0.006, -0.9, 0.9)
				orbit.y = clampf(orbit.y - event.relative.y * 0.005, -0.5, 0.45)


func _handle_key(e: InputEventKey) -> void:
	var k := e.keycode
	if mode == "menu" or mode == "popup":
		if k == KEY_ESCAPE and mode == "popup" and popup_root.has_meta("closable"):
			_close_popup()
		return
	if mode == "pause":
		if k == KEY_ESCAPE:
			_resume()
		return
	if mode == "board":
		if k == KEY_ESCAPE or (k == KEY_P and board_kind == "orders") or (k == KEY_L and board_kind == "shop"):
			_close_board()
		elif k == KEY_P:
			_open_board("orders")
		elif k == KEY_L:
			_open_board("shop")
		return
	if mode == "wheel":
		if k == KEY_ESCAPE or k == KEY_TAB:
			_close_wheel()
		elif k == KEY_E or k == KEY_ENTER:
			wheel.confirm()
		return
	if k == KEY_ESCAPE:
		if mode == "inspect":
			_exit_inspect()
		else:
			_pause()
	elif k == KEY_TAB:
		_open_wheel()
	elif k == KEY_P:
		_open_board("orders")
	elif k == KEY_L:
		_open_board("shop")
	elif k >= KEY_1 and k <= KEY_5:
		var id: String = Tools.IDS[k - KEY_1]
		_equip(id if tool != id else "none")
	elif k == KEY_Q:
		_equip("none")
	elif k == KEY_E and mode == "walk":
		_interact_walk()
	elif k == KEY_R and mode == "inspect":
		orbit = Vector2.ZERO
		zoom = 1.0


# =============================================================================
# Walk mode
# =============================================================================
func _walk_move(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if dir != Vector3.ZERO:
		dir = dir.normalized().rotated(Vector3.UP, walk_yaw)
		var speed := 2.2 if Input.is_key_pressed(KEY_SHIFT) else 1.4
		var p := cam.position + dir * speed * delta
		p.x = clampf(p.x, -2.3, 2.3)
		p.z = clampf(p.z, -0.62, 2.3)
		# keep out of the furniture either side of the bench
		if p.z < -0.75 and absf(p.x) > 1.1:
			p.z = -0.75
		p.y = EYE_H + sin(Time.get_ticks_msec() * 0.009) * 0.006
		cam.position = p


func _ray(from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	q.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(q)


func _walk_hover() -> void:
	var center := get_viewport().get_visible_rect().size * 0.5
	var from := cam.project_ray_origin(center)
	var hit := _ray(from, from + cam.project_ray_normal(center) * 2.4, 1)
	var pick := ""
	var where := Vector3.ZERO
	if not hit.is_empty() and hit.collider.has_meta("target"):
		var t := str(hit.collider.get_meta("target"))
		var dev_id := str(hit.collider.get_meta("device", ""))
		if t == "device" and devices.has(dev_id) and jobs.has(dev_id):
			pick = "device:" + dev_id
			where = (devices[dev_id] as Node3D).global_position + Vector3(0, 0.12, 0)
		elif t.begins_with("tool:"):
			pick = t
			where = hit.collider.global_position + Vector3(0, 0.07, 0)
	if pick != hovered_pick:
		if hovered_pick.begins_with("device:"):
			var old_id := hovered_pick.substr(7)
			if devices.has(old_id) and is_instance_valid(devices[old_id]):
				devices[old_id].set_device_highlight(false)
		hovered_pick = pick
		if pick.begins_with("device:"):
			devices[pick.substr(7)].set_device_highlight(true)
	if pick == "":
		prompt.hide()
		return
	var text := ""
	if pick.begins_with("device:"):
		var id := pick.substr(7)
		text = "Reparar %s de %s" % [_dev_name(id), jobs[id]["order"]["customer"]] if not jobs[id]["done"] else "%s reparado" % _dev_name(id)
	else:
		var tid := pick.substr(5)
		text = "Pegar %s" % Tools.NAMES[tid] if tool != tid else "Pousar %s" % Tools.NAMES[tid]
	_show_prompt("E", text, where)


func _show_prompt(key: String, text: String, world_pos: Vector3) -> void:
	prompt_label.text = text
	var kc: Label = prompt.get_meta("key")
	kc.text = key
	if cam.is_position_behind(world_pos):
		prompt.hide()
		return
	var sp := cam.unproject_position(world_pos)
	prompt.show()
	prompt.reset_size()
	prompt.position = sp - Vector2(prompt.size.x * 0.5, prompt.size.y + 6)


func _interact_walk() -> void:
	if hovered_pick.begins_with("device:"):
		var id := hovered_pick.substr(7)
		if not jobs.has(id) or jobs[id]["done"]:
			return
		_enter_inspect(id)
	elif hovered_pick.begins_with("tool:"):
		var tid := hovered_pick.substr(5)
		_equip("none" if tool == tid else tid)


# =============================================================================
# Inspect (repair) mode
# =============================================================================
func _enter_inspect(id: String) -> void:
	active_device = id
	focus_job = id
	mode = "inspect"
	prompt.hide()
	for d in devices.values():
		d.set_device_highlight(false)
		d.set_pickable(false)
	hovered_pick = ""
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	orbit = Vector2.ZERO
	zoom = 1.0
	crosshair.hide()
	reticle.show()
	repair_panel.show()
	objective_panel.hide()
	hints_bar.show()
	_hotbar_compact(true)
	hand.visible = true
	inspect_base = cam.global_transform
	inspect_focus = cam.global_position
	_begin_step(false)
	_refresh_repair_panel()


func _exit_inspect() -> void:
	var d: Node3D = devices.get(active_device)
	if d and d.busy:
		return
	if d:
		d.set_active_targets([])
		d.set_hover("")
	for dev in devices.values():
		dev.set_pickable(true)
	mode = "walk"
	active_device = ""
	rotating = false
	reticle.hide()
	crosshair.show()
	repair_panel.hide()
	objective_panel.show()
	hints_bar.hide()
	_hotbar_compact(false)
	_refresh_objective()
	var back := Transform3D(Basis.from_euler(Vector3(walk_pitch, walk_yaw, 0)), Vector3(clampf(cam.global_position.x, -2.0, 2.0), EYE_H, -0.25))
	_move_camera(back, 0.6)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _move_camera(target: Transform3D, duration: float) -> void:
	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()
	if duration <= 0.0:
		cam.global_transform = target
		return
	cam_tween = create_tween()
	cam_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cam_tween.tween_property(cam, "global_transform", target, duration)


func _step_def(id: String) -> Dictionary:
	var steps: Array = _fault(id)["steps"]
	var s: int = jobs[id]["step"]
	if s >= steps.size():
		return {}
	return steps[s]


## Called when entering a step (or re-entering inspect mode on the current step).
func _begin_step(run_enter := true) -> void:
	var id := active_device
	var d: Node3D = devices[id]
	var step := _step_def(id)
	if step.is_empty():
		return
	var delay := 0.0
	if run_enter and step.has("enter"):
		delay = _run_enter(id, str(step["enter"]))
	elif not run_enter:
		# coming back into a job: make sure the device is in the right pose
		delay = _restore_pose(id)
	d.set_active_targets([])
	var view: String = step.get("view", "overview")
	var go := func() -> void:
		_set_inspect_view(d.view_transform(view))
		_activate_step_targets()
	if delay > 0.0:
		d.busy = true
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			d.busy = false
			go.call())
	else:
		go.call()
	_refresh_repair_panel()


func _activate_step_targets() -> void:
	var id := active_device
	if id == "" or not jobs.has(id):
		return
	var step := _step_def(id)
	if step.is_empty():
		return
	var d: Node3D = devices[id]
	_ensure_part(id, step)
	var remaining: Array = []
	var done_list: Array = jobs[id].get("used", [])
	var targets: Array = step["targets"]
	# repeated actions on one target (cleaning, wiping) keep it active
	var repeat_same := targets.size() < int(step.get("need", 1))
	for t in targets:
		if repeat_same or not done_list.has(t):
			remaining.append(t)
	d.set_active_targets(remaining)


## Install steps need the spare part on the mat: take it from stock or ask to buy it.
func _ensure_part(id: String, step: Dictionary) -> void:
	var act := str(step.get("act", ""))
	if not (act == "install_part" or act == "install_screen"):
		return
	var part := str(step.get("part", ""))
	var d: Node3D = devices[id]
	if part == "" or d.has_new_part(part):
		return
	if int(inventory.get(part, 0)) > 0:
		inventory[part] = int(inventory[part]) - 1
		d.spawn_part(part, PART_POS[id])
		_toast("Tiraste do stock: %s" % Data.PARTS[part]["name"], false, GREEN)
	else:
		_toast("Falta a peça: %s. Compra-a na Loja (L)." % Data.PARTS[part]["name"], true)


func _restore_pose(_id: String) -> float:
	return 0.0


func _set_inspect_view(t: Transform3D) -> void:
	inspect_base = t
	var d: Node3D = devices[active_device]
	var dist := t.origin.distance_to(d.global_position)
	inspect_focus = t.origin - t.basis.z * dist
	orbit = Vector2.ZERO
	zoom = 1.0
	_move_camera(t, 0.75)


func _update_inspect_camera(delta: float) -> void:
	if cam_tween and cam_tween.is_running():
		return
	var offset := inspect_base.origin - inspect_focus
	if offset.length() < 0.01:
		return
	offset = offset.rotated(Vector3.UP, orbit.x)
	var right := offset.cross(Vector3.UP).normalized()
	if right.length() > 0.001:
		offset = offset.rotated(right, orbit.y)
	offset *= zoom
	var eye := inspect_focus + offset
	var target := Transform3D(Basis.looking_at(inspect_focus - eye, Vector3.UP), eye)
	cam.global_transform = cam.global_transform.interpolate_with(target, minf(1.0, delta * 10.0))


func _inspect_hover() -> void:
	var d: Node3D = devices.get(active_device)
	if d == null:
		return
	var mp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mp)
	var hit := _ray(from, from + cam.project_ray_normal(mp) * 3.0, 1)
	var id := ""
	if not hit.is_empty() and hit.collider.has_meta("target") and hit.collider.get_meta("device", "") == active_device:
		id = str(hit.collider.get_meta("target"))
	hovered_target = id
	if not d.busy:
		d.set_hover(id)
	else:
		d.set_hover("")


func _inspect_click() -> void:
	var id := active_device
	var d: Node3D = devices.get(id)
	if d == null or d.busy or (cam_tween and cam_tween.is_running()):
		return
	if hovered_target == "":
		return
	var step := _step_def(id)
	if step.is_empty():
		return
	if not (step["targets"] as Array).has(hovered_target):
		return
	var allowed = step["tool"]
	var ok := false
	if allowed is Array:
		ok = (allowed as Array).has(tool)
	else:
		ok = str(allowed) == tool
	if not ok:
		var need := _tool_need_text(allowed)
		_toast("Precisas de: %s" % need, true)
		_flash_needed_slot(allowed)
		return
	var target := hovered_target
	d.set_hover("")
	var dur := _perform(id, str(step["act"]), target)
	_hand_action(dur)
	var used: Array = jobs[id].get("used", [])
	used.append(target)
	jobs[id]["used"] = used
	d.set_active_targets([])
	d.busy = true
	get_tree().create_timer(dur + 0.05).timeout.connect(func() -> void:
		d.busy = false
		_after_action(id))


func _tool_need_text(allowed) -> String:
	if allowed is Array:
		var parts: Array = []
		for a in allowed:
			parts.append("%s (%d)" % [Tools.NAMES[a], Tools.IDS.find(a) + 1])
		return " ou ".join(parts)
	if str(allowed) == "none":
		return "mão livre (Q)"
	return "%s (tecla %d)" % [Tools.NAMES[str(allowed)], Tools.IDS.find(str(allowed)) + 1]


func _after_action(id: String) -> void:
	var step := _step_def(id)
	var need: int = step.get("need", 1)
	jobs[id]["progress"] = int(jobs[id]["progress"]) + 1
	minutes += 2.0
	_gain_xp(5)
	if int(jobs[id]["progress"]) >= need and not bool(step.get("repeatable_until", false)):
		_advance_step(id)
	else:
		_activate_step_targets()
		_refresh_repair_panel()


func _advance_step(id: String) -> void:
	jobs[id]["step"] = int(jobs[id]["step"]) + 1
	jobs[id]["progress"] = 0
	jobs[id]["used"] = []
	var steps: Array = _fault(id)["steps"]
	if int(jobs[id]["step"]) >= steps.size():
		_refresh_repair_panel()
		get_tree().create_timer(1.5).timeout.connect(func() -> void: _job_complete(id))
		return
	_begin_step(true)


## Performs a step action; returns its duration in seconds.
func _perform(id: String, act: String, target: String) -> float:
	var d: Node3D = devices[id]
	var step := _step_def(id)
	match act:
		"open_lid":
			d.set_lid(112, 0.9)
			return 0.9
		"power_dead":
			d.press_power(false)
			d.show_dead_battery()
			_toast("Não liga... o ecrã pisca \"Bateria 0%\". Vamos medir.")
			return 1.2
		"power_hot":
			d.press_power(false)
			d.boot_then_fail("SOBREAQUECIMENTO\nTemperatura do CPU: 98 °C\nA desligar...", Color("ff6b5b"))
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.6).timeout.connect(func() -> void:
				_toast("Arranca e desliga-se a ferver. Avaria: SOBREAQUECIMENTO", false, GREEN))
			return 2.0
		"power_nodisk":
			d.press_power(false)
			d.boot_then_fail("Nenhum dispositivo de arranque encontrado.\nInsira um disco e reinicie.", Color("e8eef4"))
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.6).timeout.connect(func() -> void:
				_toast("O sistema não encontra o disco. Avaria: SSD", false, GREEN))
			return 2.0
		"power_lowbat":
			d.press_button_only()
			d.show_message("Bateria 1%\nA desligar...", Color("ff6b5b"), 1.8)
			_toast("Liga e desliga-se logo... e o ecrã está levantado de um lado.")
			return 1.2
		"power_nocharge":
			d.press_button_only()
			d.show_message("Bateria fraca\nLigue o carregador", Color("ffcf6b"), 1.8)
			_toast("Sem bateria, e o cabo não carrega. Vamos medir a porta.")
			return 1.2
		"measure":
			var digits: Label3D = bench_tools["multimeter"].get_node("Body/Digits")
			var reading := str(step.get("reading", "0.00"))
			meter_panel.show()
			var tw := create_tween()
			for v in ["12.6", "4.18", "0.71", reading]:
				tw.tween_callback(func() -> void:
					digits.text = v
					meter_label.text = v + " V")
				tw.tween_interval(0.25)
			tw.tween_interval(2.5)
			tw.tween_callback(meter_panel.hide)
			jobs[id]["diagnosed"] = true
			var result := str(step.get("result", ""))
			get_tree().create_timer(1.0).timeout.connect(func() -> void: _toast(result, false, GREEN))
			return 1.1
		"unscrew":
			var idx := int(target.right(1))
			d.unscrew(idx, tray.global_position + Vector3(0, 0.012, 0))
			return 0.95
		"screw_in":
			var idx2 := int(target.right(1))
			d.screw_in(idx2)
			return 0.85
		"remove_cover":
			d.remove_cover(COVER_ASIDE_BY.get(id, COVER_ASIDE))
			return 1.2
		"replace_cover":
			d.replace_cover()
			return 1.05
		"clean_fan":
			_dust_puff(d.targets["fan"].global_position)
			if d.clean_fan():
				_toast("Ventoinha limpa!", false, GREEN)
			return 0.65
		"remove_part":
			d.remove_part(str(step["part"]), OLD_PART_BIN)
			return 1.4
		"install_part":
			d.install_part(str(step["part"]))
			return 1.0
		"power_on":
			if id == "laptop":
				d.press_power(true)
			else:
				d.press_power("on")
			get_tree().create_timer(0.8).timeout.connect(func() -> void:
				_toast("Funciona perfeitamente! Reparação concluída.", false, GREEN))
			return 1.6
		"power_glitch":
			d.press_power("glitch")
			_toast("O ecrã pisca com riscos... parece danificado.")
			return 1.0
		"wipe":
			if d.wipe():
				jobs[id]["diagnosed"] = true
				_toast("Vidro e painel rachados. Avaria: ECRÃ PARTIDO", false, GREEN)
			return 0.55
		"open_screen":
			d.open_screen()
			return 1.1
		"remove_screen":
			d.remove_old_screen(OLD_SCREEN_ASIDE)
			return 1.25
		"install_screen":
			d.install_new_screen()
			return 1.0
		"close_screen":
			d.close_screen()
			return 0.95
		"blow_port":
			_dust_puff(d.targets["port"].global_position)
			return 0.6
		"pad_on":
			d.set_led(true)
			_toast("Liga. Vamos ver o que se passa.")
			return 0.6
		"pad_drift":
			d.wiggle_stick(true)
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				_toast("O analógico não volta ao centro. Avaria: DRIFT", false, GREEN))
			return 0.9
		"pad_test":
			d.wiggle_stick(false)
			d.set_led(true)
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				_toast("Analógico perfeito, sem drift! Reparação concluída.", false, GREEN))
			return 1.0
		"pad_stuck":
			d.press_a(true)
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(0.8).timeout.connect(func() -> void:
				_toast("O botão fica preso — sujidade pegajosa. Avaria: BOTÕES", false, GREEN))
			return 1.3
		"clean_buttons":
			_dust_puff(d.targets["buttons"].global_position)
			d.clean_buttons()
			return 0.6
		"pad_ok":
			d.press_a(false)
			d.set_led(true)
			get_tree().create_timer(0.4).timeout.connect(func() -> void:
				_toast("Os botões estão como novos! Reparação concluída.", false, GREEN))
			return 0.8
	return 0.4


func _run_enter(id: String, what: String) -> float:
	var d: Node3D = devices[id]
	match what:
		"flip_bottom":
			if id == "laptop":
				d.set_lid(0, 0.6)
				get_tree().create_timer(0.6).timeout.connect(func() -> void: d.flip(true, 1.0))
				return 1.7
			d.flip(true, 0.9)
			return 1.0
		"flip_top":
			d.flip(false, 0.9)
			return 1.0
		"flip_top_open":
			d.flip(false, 1.0)
			get_tree().create_timer(1.05).timeout.connect(func() -> void: d.set_lid(112, 0.8))
			return 1.9
	return 0.0


func _dust_puff(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 40
	p.lifetime = 1.2
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.22
	p.gravity = Vector3(0, -0.05, 0)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.2
	var m := SphereMesh.new()
	m.radius = 0.0025
	m.height = 0.005
	var mat := Kit.mat(Color(0.75, 0.72, 0.66, 0.6), 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material = mat
	p.mesh = m
	add_child(p)
	p.global_position = pos + Vector3(0, 0.01, 0)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


# =============================================================================
# Hand
# =============================================================================
func _equip(id: String) -> void:
	tool = id
	for tid in hand_tools.keys():
		(hand_tools[tid] as Node3D).visible = tid == id
		var prop: Node3D = bench_tools[tid]
		prop.visible = tid != id
	if id == "none":
		hand.set_pose("point" if mode == "inspect" else "relaxed")
	elif id == "cloth":
		hand.set_pose("pinch")
	else:
		hand.set_pose("grip")
	_refresh_hotbar()
	if (mode == "walk" or mode == "inspect") and id != "none":
		_toast("%s na mão." % Tools.NAMES[id])


func _cycle_tool(dir: int) -> void:
	var list: Array = ["none"] + Tools.IDS
	var i := list.find(tool)
	_equip(list[(i + dir + list.size()) % list.size()])


func _hand_action(dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "hand_press", 1.0, minf(0.18, dur * 0.3))
	if tool == "screwdriver":
		tw.parallel().tween_property(self, "hand_twist", hand_twist + TAU * 1.5, maxf(0.3, dur * 0.7))
	elif tool in ["brush", "cloth"]:
		tw.parallel().tween_method(func(v: float) -> void: hand_twist = sin(v) * 0.6, 0.0, TAU * 2.0, maxf(0.3, dur * 0.8))
	tw.tween_property(self, "hand_press", 0.0, 0.2)
	tw.tween_callback(func() -> void:
		if tool != "screwdriver":
			hand_twist = 0.0)


func _update_hand_inspect(delta: float) -> void:
	if not hand.visible:
		return
	var mp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mp)
	var dir := cam.project_ray_normal(mp)
	var hit := _ray(from, from + dir * 3.0, 3)
	var p: Vector3
	if not hit.is_empty():
		p = hit.position
	else:
		var t := (MAT_Y + 0.02 - from.y) / dir.y if absf(dir.y) > 0.001 else 0.5
		p = from + dir * clampf(t, 0.05, 2.0)
	var cb := cam.global_transform.basis
	var right := Vector3(cb.x.x, 0, cb.x.z).normalized()
	var fwd := Vector3(-cb.z.x, 0, -cb.z.z).normalized()
	var basis: Basis
	var tip: Vector3
	if tool == "none" or tool == "cloth":
		# palm down, fingers pointing forward/down to the cursor
		var f := (Vector3.DOWN * (0.55 if tool == "none" else 0.15) + fwd * 0.8 - right * 0.25).normalized()
		var z_axis := -f
		var y_axis := (Vector3.UP - z_axis * Vector3.UP.dot(z_axis)).normalized()
		var x_axis := y_axis.cross(z_axis).normalized()
		basis = Basis(x_axis, y_axis, z_axis)
		tip = hand.index_tip_local() if tool == "none" else tool_tips["cloth"]
	else:
		var d := (Vector3.DOWN * 1.0 + fwd * 0.28 - right * 0.32).normalized()
		if tool == "air":
			d = (Vector3.DOWN + fwd * 0.12).normalized()
		var a := (right * 0.75 - fwd * 0.55 + Vector3.UP * 0.15).normalized()
		var x_axis := d
		var z_axis := (a - x_axis * a.dot(x_axis)).normalized()
		var y_axis := z_axis.cross(x_axis).normalized()
		basis = Basis(x_axis, y_axis, z_axis)
		if hand_twist != 0.0:
			basis = basis.rotated(d, hand_twist * (0.25 if tool == "screwdriver" else 1.0))
		tip = tool_tips[tool]
	if tool == "air":
		# spray from a short distance, keeping the nozzle on the cursor ray
		p -= dir * 0.13
	var press_dir := (p - from).normalized()
	var lift := 0.012 * (1.0 - hand_press)
	var target_origin := p - basis * tip - press_dir * lift
	var target := Transform3D(basis.orthonormalized(), target_origin)
	hand.global_transform = hand.global_transform.interpolate_with(target, minf(1.0, delta * 16.0))


func _update_hand_walk(delta: float) -> void:
	hand.visible = tool != "none"
	if not hand.visible:
		return
	var t := Time.get_ticks_msec() * 0.001
	var bob := Vector3(sin(t * 1.3) * 0.003, sin(t * 2.1) * 0.003, 0)
	var local: Transform3D
	if tool == "cloth":
		var zc := Vector3(0.35, -0.25, 1.0).normalized()
		var yc := Vector3(0, 1, 0)
		yc = (yc - zc * yc.dot(zc)).normalized()
		local = Transform3D(Basis(yc.cross(zc), yc, zc), Vector3(0.16, -0.17, -0.36) + bob)
	else:
		# tool points forward / slightly up-left, wrist comes from the bottom right
		var x := Vector3(-0.35, 0.3, -1.0).normalized()
		var z := Vector3(0.55, -0.35, 0.7)
		z = (z - x * z.dot(x)).normalized()
		local = Transform3D(Basis(x, z.cross(x), z), Vector3(0.19, -0.115, -0.31) + bob)
	var target := cam.global_transform * local
	hand.global_transform = hand.global_transform.interpolate_with(target, minf(1.0, delta * 14.0))


# =============================================================================
# Progression
# =============================================================================
func _gain_xp(amount: int) -> void:
	xp += amount
	while xp >= 100:
		xp -= 100
		level += 1
		_toast("Subiste para o nível %d!" % level, false, YELLOW)


func _spend(amount: float, what: String) -> void:
	money -= amount
	day_profit -= amount
	_toast("-%s  %s" % [_eur(amount), what])


func _abs_minutes() -> float:
	return float(day - 1) * 1440.0 + minutes


func _clock_text(abs_min: float) -> String:
	var d := int(abs_min / 1440.0) + 1
	var m := int(fmod(abs_min, 1440.0))
	var t := "%02d:%02d" % [m / 60, m % 60]
	return t if d == day else "Dia %d, %s" % [d, t]


func _reputation() -> float:
	if ratings.is_empty():
		return 5.0
	var total := 0.0
	for r in ratings:
		total += float(r)
	return total / ratings.size()


## Creates a random customer order (device + fault + complaint + payment + deadline).
func _new_order(silent := false) -> void:
	var keys: Array = FAULTS.keys()
	# avoid flooding the same device
	var fk: String = keys[randi() % keys.size()]
	var f: Dictionary = FAULTS[fk]
	var cust: Array = Data.CUSTOMERS[randi() % Data.CUSTOMERS.size()]
	var complaints: Array = f["complaints"]
	order_seq += 1
	var rep_bonus := 0.9 + 0.04 * _reputation()
	var pay := snappedf(float(f["pay"]) * randf_range(0.9, 1.2) * rep_bonus, 5.0)
	var o := {
		"id": order_seq, "customer": cust[0], "color": cust[1], "device": f["device"], "fault": fk,
		"complaint": complaints[randi() % complaints.size()], "pay": pay,
		"deadline": _abs_minutes() + randf_range(150, 330), "expires": _abs_minutes() + 150, "status": "new",
	}
	orders.append(o)
	if not silent:
		_toast("Novo cliente: %s trouxe um %s. Abre os Pedidos (P)." % [o["customer"], _dev_name(o["device"]).to_lower()], false, YELLOW)
	_refresh_orders_badge()


func _order_tick() -> void:
	var now := _abs_minutes()
	if now >= next_order_at:
		var pending := 0
		for o in orders:
			if o["status"] == "new":
				pending += 1
		if pending < 3 and minutes < 18 * 60:
			_new_order()
		next_order_at = now + randf_range(50, 110) / clampf(_reputation() / 4.0, 0.7, 1.25)
	# unanswered requests walk out
	for o in orders.duplicate():
		if o["status"] == "new" and now > float(o["expires"]):
			orders.erase(o)
			_toast("%s cansou-se de esperar e foi embora." % o["customer"], true)
			_refresh_orders_badge()


func _accept_order(o: Dictionary) -> void:
	o["status"] = "accepted"
	_toast("Pedido de %s aceite." % o["customer"], false, GREEN)
	_place_waiting_orders()
	_refresh_orders_panel()
	_refresh_objective()


func _decline_order(o: Dictionary) -> void:
	orders.erase(o)
	_refresh_orders_panel()
	_refresh_orders_badge()


## Moves accepted orders onto free bench slots.
func _place_waiting_orders() -> void:
	for o in orders:
		if o["status"] == "accepted" and not jobs.has(o["device"]):
			_spawn_device(o["device"], o)
			var d: Node3D = devices[o["device"]]
			d.scale = Vector3(0.01, 0.01, 0.01)
			var t := create_tween()
			t.tween_property(d, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if mode == "walk":
				focus_job = o["device"]
	_refresh_orders_badge()


func _job_complete(id: String) -> void:
	jobs[id]["done"] = true
	var o: Dictionary = jobs[id]["order"]
	var f := _fault(id)
	var on_time := _abs_minutes() <= float(o["deadline"])
	var tip := snappedf(float(o["pay"]) * (randf_range(0.1, 0.25) if on_time else 0.0), 1.0)
	var stars := 5 if on_time else 3
	if on_time and _abs_minutes() > float(o["deadline"]) - 30.0:
		stars = 4
	var star_txt := "★".repeat(stars) + "☆".repeat(5 - stars)
	_open_popup("Reparação concluída!", [
		["%s — %s" % [_dev_name(id), f["fault"]], TEXT],
		["Cliente: %s" % o["customer"], MUTED],
		["Pagamento:  %s" % _eur(float(o["pay"])), GREEN],
		["Gorjeta:  %s" % _eur(tip) if tip > 0 else "Sem gorjeta (entregue fora de prazo)", GREEN if tip > 0 else Color("ffb4a8")],
		["Avaliação:  %s     +%d XP" % [star_txt, int(f["xp"])], YELLOW],
	], [["Entregar a %s" % o["customer"], func() -> void: _deliver(id, tip, stars)]], false)


func _deliver(id: String, tip: float, stars: int) -> void:
	var o: Dictionary = jobs[id]["order"]
	var f := _fault(id)
	var gain := float(o["pay"]) + tip
	money += gain
	day_profit += gain
	repaired += 1
	ratings.append(stars)
	if ratings.size() > 30:
		ratings.pop_front()
	_gain_xp(int(f["xp"]))
	_close_popup()
	_exit_inspect_forced()
	orders.erase(o)
	jobs.erase(id)
	var d: Node3D = devices[id]
	d.set_pickable(false)
	d.set_device_highlight(false)
	hovered_pick = ""
	devices.erase(id)
	var tw := create_tween()
	tw.tween_property(d, "scale", Vector3(0.01, 0.01, 0.01), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		d.queue_free()
		_place_waiting_orders()
		_refresh_objective())
	_toast("+%s  %s ficou muito contente!" % [_eur(gain), o["customer"]], false, GREEN)
	_save_game()


func _exit_inspect_forced() -> void:
	var d: Node3D = devices.get(active_device)
	if d:
		d.busy = false
	if mode == "popup":
		mode = "inspect"
	_exit_inspect()


func _end_of_day() -> void:
	minutes = 20 * 60
	var finished_day := day
	var p := day_profit
	_open_popup("Fim do Dia %d" % finished_day, [
		["A oficina fecha às 20:00.", TEXT],
		["Resultado do dia:  %s" % _eur(p), GREEN if p >= 0 else Color("e74c3c")],
		["Equipamentos reparados (total):  %d" % repaired, MUTED],
		["Reputação:  %.1f ★" % _reputation(), YELLOW],
	], [["Começar o Dia %d" % (finished_day + 1), func() -> void:
		day = finished_day + 1
		minutes = 8 * 60
		day_profit = 0.0
		next_order_at = _abs_minutes() + 20.0
		for o in orders.duplicate():
			if o["status"] == "new":
				orders.erase(o)
		_new_order(true)
		_new_order(true)
		_close_popup()
		_refresh_orders_badge()
		_save_game()]], false)


# =============================================================================
# Save / settings
# =============================================================================
func _save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"day": day, "minutes": minutes, "money": money, "xp": xp, "level": level, "repaired": repaired, "ratings": ratings, "inventory": inventory}))


func _has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _load_game() -> bool:
	if not _has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return false
	day = int(data.get("day", 1))
	minutes = float(data.get("minutes", 480))
	money = float(data.get("money", 250))
	xp = int(data.get("xp", 0))
	level = int(data.get("level", 1))
	repaired = int(data.get("repaired", 0))
	ratings = data.get("ratings", [])
	inventory = {}
	var inv = data.get("inventory", {})
	if inv is Dictionary:
		for k in inv.keys():
			inventory[k] = int(inv[k])
	return true


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		settings["quality"] = int(cfg.get_value("video", "quality", 1))
		settings["sensitivity"] = float(cfg.get_value("input", "sensitivity", 1.0))
		settings["fullscreen"] = bool(cfg.get_value("video", "fullscreen", false))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", settings["quality"])
	cfg.set_value("video", "fullscreen", settings["fullscreen"])
	cfg.set_value("input", "sensitivity", settings["sensitivity"])
	cfg.save(SETTINGS_PATH)


func _apply_settings() -> void:
	var q: int = settings["quality"]
	var e: Environment = room.env
	e.ssao_enabled = q >= 1
	e.ssao_radius = 0.6
	e.ssao_intensity = 1.6
	e.ssil_enabled = q >= 2
	e.ssr_enabled = q >= 2
	e.ssr_max_steps = 48
	e.volumetric_fog_enabled = q >= 2
	e.volumetric_fog_density = 0.012
	e.volumetric_fog_albedo = Color("c9d6ff")
	e.volumetric_fog_emission = Color(0, 0, 0)
	e.glow_enabled = true
	room.sun.shadow_enabled = true
	for l in room.spot_lights:
		l.shadow_enabled = q >= 1 or l == room.lamp_light
	get_viewport().msaa_3d = Viewport.MSAA_2X if q >= 1 else Viewport.MSAA_DISABLED
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if q >= 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)


# =============================================================================
# UI construction
# =============================================================================
func _build_theme() -> void:
	theme_main = Theme.new()
	theme_main.default_font = font_bold
	theme_main.default_font_size = 18
	theme_main.set_color("font_color", "Label", TEXT)


func _panel_style(bg := PANEL_BG, radius := 12, border := PANEL_BORDER, pad := Vector4(16, 10, 16, 10)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	return sb


func _panel(bg := PANEL_BG, radius := 12, pad := Vector4(16, 10, 16, 10)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style(bg, radius, PANEL_BORDER, pad))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _label(text: String, size := 18, color := TEXT, f: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if f:
		l.add_theme_font_override("font", f)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _icon(kind: String, size := 22.0, color := TEXT) -> Control:
	var c := UIcon.new()
	return c.setup(kind, color, size, YELLOW)


func _keycap(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f2f5f8")
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_offset = Vector2(0, 2)
	sb.shadow_size = 1
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := _label(text, 15, Color("10161d"), font_xbold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.set_meta("label", l)
	return p


func _build_ui() -> void:
	_build_theme()
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var base := Control.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.theme = theme_main
	ui.add_child(base)
	_build_hud(base)
	_build_wheel(base)
	_build_menu(base)
	_build_board(base)
	_build_pause(base)
	_build_popup(base)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(fade)


# --- HUD ----------------------------------------------------------------------
func _build_hud(base: Control) -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(hud)

	# top-left: day + time
	var tl := HBoxContainer.new()
	tl.position = Vector2(22, 18)
	tl.add_theme_constant_override("separation", 10)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tl)
	var day_pill := _pill_with_icon("calendar")
	day_label = day_pill.get_meta("label")
	tl.add_child(day_pill)
	var time_pill := _pill_with_icon("clock")
	time_label = time_pill.get_meta("label")
	tl.add_child(time_pill)

	# top-right: money, level, xp
	var tr := HBoxContainer.new()
	tr.anchor_left = 1.0
	tr.anchor_right = 1.0
	tr.offset_left = -520
	tr.offset_right = -22
	tr.offset_top = 18
	tr.alignment = BoxContainer.ALIGNMENT_END
	tr.add_theme_constant_override("separation", 10)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tr)
	var money_pill := _pill_with_icon("cash")
	money_label = money_pill.get_meta("label")
	tr.add_child(money_pill)
	var lvl_pill := _pill_with_icon("star")
	level_label = lvl_pill.get_meta("label")
	tr.add_child(lvl_pill)
	var xp_pill := _panel(PANEL_BG, 10, Vector4(14, 6, 14, 6))
	var xpv := VBoxContainer.new()
	xpv.add_theme_constant_override("separation", 2)
	xp_pill.add_child(xpv)
	xp_label = _label("0 / 100 XP", 14, TEXT)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xpv.add_child(xp_label)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(120, 6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.12)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = YELLOW
	fg.set_corner_radius_all(3)
	xp_bar.add_theme_stylebox_override("background", bg)
	xp_bar.add_theme_stylebox_override("fill", fg)
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xpv.add_child(xp_bar)
	tr.add_child(xp_pill)

	# objective panel (walk)
	objective_panel = _panel(PANEL_BG, 12, Vector4(16, 12, 18, 14))
	objective_panel.anchor_left = 1.0
	objective_panel.anchor_right = 1.0
	objective_panel.offset_left = -300
	objective_panel.offset_right = -22
	objective_panel.offset_top = 78
	hud.add_child(objective_panel)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 7)
	objective_panel.add_child(ov)
	var oh := HBoxContainer.new()
	oh.add_theme_constant_override("separation", 8)
	oh.add_child(_icon("chevron", 18))
	objective_title = _label("Objetivo Atual", 19, YELLOW, font_xbold)
	oh.add_child(objective_title)
	ov.add_child(oh)
	objective_rows = VBoxContainer.new()
	objective_rows.add_theme_constant_override("separation", 6)
	ov.add_child(objective_rows)

	# repair panel (inspect)
	repair_panel = _panel(PANEL_BG, 12, Vector4(16, 12, 18, 14))
	repair_panel.position = Vector2(22, 74)
	repair_panel.custom_minimum_size = Vector2(330, 0)
	hud.add_child(repair_panel)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	repair_panel.add_child(rv)
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 8)
	rh.add_child(_icon("chevron", 18))
	repair_title = _label("Reparação: Portátil", 19, YELLOW, font_xbold)
	rh.add_child(repair_title)
	rv.add_child(rh)
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	rv.add_child(sep)
	repair_rows = VBoxContainer.new()
	repair_rows.add_theme_constant_override("separation", 4)
	rv.add_child(repair_rows)
	step_hint = _label("", 14, MUTED)
	step_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	step_hint.custom_minimum_size = Vector2(300, 0)
	rv.add_child(step_hint)
	repair_panel.hide()

	# interact prompt
	prompt = _panel(Color(0.04, 0.07, 0.11, 0.9), 9, Vector4(8, 5, 12, 5))
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 8)
	prompt.add_child(ph)
	var kc := _keycap("E")
	ph.add_child(kc)
	prompt.set_meta("key", kc.get_meta("label"))
	prompt_label = _label("Interagir", 17, TEXT)
	ph.add_child(prompt_label)
	hud.add_child(prompt)
	prompt.hide()

	# hotbar
	hotbar = HBoxContainer.new()
	hotbar.anchor_left = 0.5
	hotbar.anchor_right = 0.5
	hotbar.anchor_top = 1.0
	hotbar.anchor_bottom = 1.0
	hotbar.add_theme_constant_override("separation", 8)
	hotbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hotbar)
	for i in range(Tools.IDS.size()):
		var id: String = Tools.IDS[i]
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(66, 66)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex := TextureRect.new()
		tex.texture = icon_tex[id]
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.offset_left = 5
		tex.offset_top = 5
		tex.offset_right = -5
		tex.offset_bottom = -5
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(tex)
		var num := _label(str(i + 1), 13, TEXT, font_xbold)
		num.position = Vector2(6, 2)
		slot.add_child(num)
		hotbar.add_child(slot)
		hotbar_slots[id] = slot
	_hotbar_compact(false)

	# key hints (inspect)
	hints_bar = HBoxContainer.new()
	hints_bar.anchor_left = 0.5
	hints_bar.anchor_right = 0.5
	hints_bar.anchor_top = 1.0
	hints_bar.anchor_bottom = 1.0
	hints_bar.offset_top = -62
	hints_bar.offset_bottom = -20
	hints_bar.add_theme_constant_override("separation", 10)
	hints_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hints_bar)
	hints_bar.hide()

	# toast
	toast = _panel(Color(0.04, 0.07, 0.11, 0.92), 10, Vector4(16, 8, 16, 8))
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 1.0
	toast.anchor_bottom = 1.0
	toast.offset_top = -150
	toast.offset_bottom = -110
	toast_label = _label("", 17, TEXT)
	toast.add_child(toast_label)
	toast.modulate.a = 0.0
	hud.add_child(toast)

	# shortcuts (orders / shop) bottom-left
	var sc := HBoxContainer.new()
	sc.anchor_top = 1.0
	sc.anchor_bottom = 1.0
	sc.offset_left = 22
	sc.offset_top = -62
	sc.offset_bottom = -22
	sc.add_theme_constant_override("separation", 10)
	sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(sc)
	for it in [["P", "Pedidos"], ["L", "Loja"]]:
		var pp := _panel(Color(0.04, 0.07, 0.11, 0.88), 10, Vector4(10, 6, 14, 6))
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 8)
		pp.add_child(hh)
		hh.add_child(_keycap(it[0]))
		hh.add_child(_label(it[1], 17))
		if it[0] == "P":
			orders_badge = _label("", 15, Color("10161d"), font_xbold)
			var bp := PanelContainer.new()
			var bsb := StyleBoxFlat.new()
			bsb.bg_color = YELLOW
			bsb.set_corner_radius_all(9)
			bsb.content_margin_left = 7
			bsb.content_margin_right = 7
			bp.add_theme_stylebox_override("panel", bsb)
			bp.add_child(orders_badge)
			hh.add_child(bp)
			orders_badge.set_meta("wrap", bp)
		sc.add_child(pp)
	hud.set_meta("shortcuts", sc)

	# multimeter readout
	meter_panel = _panel(Color("1a1d12"), 10, Vector4(18, 10, 18, 12))
	meter_panel.anchor_left = 1.0
	meter_panel.anchor_right = 1.0
	meter_panel.offset_left = -250
	meter_panel.offset_right = -22
	meter_panel.offset_top = 80
	var mv := VBoxContainer.new()
	meter_panel.add_child(mv)
	mv.add_child(_label("MULTÍMETRO  •  V DC", 13, Color("f2c218"), font_xbold))
	var lcd := PanelContainer.new()
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color("9fb39a")
	lsb.set_corner_radius_all(6)
	lsb.content_margin_left = 12
	lsb.content_margin_right = 12
	lcd.add_theme_stylebox_override("panel", lsb)
	meter_label = _label("0.00 V", 44, Color("1b231b"), font_xbold)
	meter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lcd.add_child(meter_label)
	mv.add_child(lcd)
	hud.add_child(meter_panel)
	meter_panel.hide()

	# crosshair + inspect reticle
	crosshair = Control.new()
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.draw.connect(func() -> void:
		crosshair.draw_circle(Vector2.ZERO, 3.2, Color(0, 0, 0, 0.5))
		crosshair.draw_circle(Vector2.ZERO, 2.2, Color(1, 1, 1, 0.9)))
	hud.add_child(crosshair)
	reticle = Control.new()
	reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.draw.connect(_draw_reticle)
	hud.add_child(reticle)
	reticle.hide()


func _pill_with_icon(kind: String) -> PanelContainer:
	var p := _panel(PANEL_BG, 10, Vector4(12, 7, 16, 7))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	h.add_child(_icon(kind, 24))
	var l := _label("", 18, TEXT, font_xbold)
	h.add_child(l)
	p.set_meta("label", l)
	return p


func _draw_reticle() -> void:
	var mp := reticle.get_local_mouse_position()
	var on_target := hovered_target != ""
	var col := YELLOW if on_target else Color(1, 1, 1, 0.75)
	if on_target and tool == "screwdriver":
		var a0 := Time.get_ticks_msec() * 0.004
		reticle.draw_arc(mp, 17, a0, a0 + PI * 1.4, 24, Color(0, 0, 0, 0.5), 5.0, true)
		reticle.draw_arc(mp, 17, a0, a0 + PI * 1.4, 24, Color.WHITE, 3.0, true)
		var tip := mp + Vector2(cos(a0 + PI * 1.4), sin(a0 + PI * 1.4)) * 17
		var dir := Vector2(cos(a0 + PI * 1.4 + PI * 0.5), sin(a0 + PI * 1.4 + PI * 0.5))
		reticle.draw_colored_polygon(PackedVector2Array([tip + dir * 7, tip + dir.orthogonal() * 6, tip - dir.orthogonal() * 6]), Color.WHITE)
		reticle.draw_circle(mp, 3, Color.WHITE)
	else:
		reticle.draw_arc(mp, 10 if on_target else 7, 0, TAU, 32, Color(0, 0, 0, 0.45), 4.0, true)
		reticle.draw_arc(mp, 10 if on_target else 7, 0, TAU, 32, col, 2.0, true)
		reticle.draw_circle(mp, 2.0, col)


func _hotbar_compact(compact: bool) -> void:
	var n := Tools.IDS.size()
	var w := 66.0 * n + 8.0 * (n - 1)
	if compact:
		hotbar.anchor_left = 1.0
		hotbar.anchor_right = 1.0
		hotbar.offset_left = -w - 22
		hotbar.offset_right = -22
		hotbar.offset_top = -88
		hotbar.offset_bottom = -22
		hotbar.scale = Vector2(0.8, 0.8)
		hotbar.pivot_offset = Vector2(w, 66)
	else:
		hotbar.anchor_left = 0.5
		hotbar.anchor_right = 0.5
		hotbar.offset_left = -w * 0.5
		hotbar.offset_right = w * 0.5
		hotbar.offset_top = -88
		hotbar.offset_bottom = -22
		hotbar.scale = Vector2.ONE
	_refresh_hotbar()


func _refresh_hotbar() -> void:
	for id in hotbar_slots.keys():
		var slot: Panel = hotbar_slots[id]
		var sel: bool = id == tool
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.1, 0.16, 0.88) if not sel else Color(0.16, 0.13, 0.05, 0.92)
		sb.set_corner_radius_all(10)
		sb.border_color = YELLOW if sel else Color(1, 1, 1, 0.1)
		sb.set_border_width_all(3 if sel else 1)
		sb.shadow_color = Color(0, 0, 0, 0.3)
		sb.shadow_size = 6
		slot.add_theme_stylebox_override("panel", sb)


func _flash_needed_slot(allowed) -> void:
	var ids: Array = allowed if allowed is Array else [allowed]
	for id in ids:
		if hotbar_slots.has(id):
			var slot: Panel = hotbar_slots[id]
			var tw := create_tween()
			for i in range(3):
				tw.tween_property(slot, "modulate", Color(1.6, 1.3, 0.5), 0.12)
				tw.tween_property(slot, "modulate", Color.WHITE, 0.12)


func _set_hints(items: Array) -> void:
	for c in hints_bar.get_children():
		hints_bar.remove_child(c)
		c.queue_free()
	for it in items:
		var p := _panel(Color(0.04, 0.07, 0.11, 0.88), 10, Vector4(12, 6, 14, 6))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		p.add_child(h)
		var key: String = it[0]
		if key.begins_with("mouse"):
			h.add_child(_icon(key, 24))
		else:
			h.add_child(_keycap(key))
		h.add_child(_label(it[1], 17, TEXT))
		hints_bar.add_child(p)
	await get_tree().process_frame
	hints_bar.reset_size()
	hints_bar.offset_left = -hints_bar.size.x * 0.5
	hints_bar.offset_right = hints_bar.size.x * 0.5


func _update_hud_values() -> void:
	day_label.text = "Dia %d" % day
	var m := int(minutes)
	time_label.text = "%02d:%02d" % [m / 60, m % 60]
	money_label.text = _eur(money)
	level_label.text = str(level)
	xp_label.text = "%d / 100 XP" % xp
	xp_bar.value = xp


func _eur(v: float) -> String:
	var neg := v < 0
	var cents := int(round(absf(v) * 100.0))
	var s := "%d,%02d" % [cents / 100, cents % 100]
	return ("-€ " if neg else "€ ") + s


func _toast(text: String, warn := false, color := TEXT) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", Color("ffb4a8") if warn else color)
	toast.reset_size()
	toast.offset_left = -toast.size.x * 0.5
	toast.offset_right = toast.size.x * 0.5
	var tw := create_tween()
	toast.modulate.a = 0.0
	tw.tween_property(toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.6)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
	if toast.has_meta("tw"):
		var old: Tween = toast.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	toast.set_meta("tw", tw)


func _row(text: String, state: String) -> Control:
	# state: done | active | todo
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.07) if state == "active" else Color(0, 0, 0, 0)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	wrap.add_theme_stylebox_override("panel", sb)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	wrap.add_child(h)
	var kind := "check" if state == "done" else ("box_active" if state == "active" else "box")
	h.add_child(_icon(kind, 18, Color(1, 1, 1, 0.55)))
	var l := _label(text, 16, TEXT if state != "todo" else Color(0.85, 0.9, 0.95, 0.8))
	h.add_child(l)
	return wrap


func _refresh_objective() -> void:
	if objective_rows == null:
		return
	for c in objective_rows.get_children():
		c.queue_free()
	if not jobs.has(focus_job) or jobs[focus_job]["done"]:
		focus_job = ""
		for id in jobs.keys():
			if not jobs[id]["done"]:
				focus_job = id
				break
	if focus_job == "":
		objective_title.text = "Objetivo Atual"
		var waiting := 0
		for o in orders:
			if o["status"] == "new":
				waiting += 1
		objective_rows.add_child(_row("Não há trabalho na bancada", "done"))
		objective_rows.add_child(_row("Abre os Pedidos (P) e aceita um cliente", "active"))
		if waiting > 0:
			objective_rows.add_child(_label("%d cliente(s) à espera de resposta" % waiting, 13, YELLOW))
		return
	var id := focus_job
	var j: Dictionary = jobs[id]
	var o: Dictionary = j["order"]
	objective_title.text = "%s de %s" % [_dev_name(id), o["customer"]]
	var s: int = j["step"]
	var steps: Array = _fault(id)["steps"]
	var items := [
		["Examinar o %s" % _dev_name(id).to_lower(), s >= 1],
		["Diagnosticar a avaria", bool(j["diagnosed"])],
		["Reparar o equipamento", s >= steps.size() - 1],
		["Testar e entregar", bool(j["done"])],
	]
	var active_set := false
	for it in items:
		var done: bool = it[1]
		var st := "done" if done else ("active" if not active_set else "todo")
		if not done:
			active_set = true
		objective_rows.add_child(_row(it[0], st))
	var late := _abs_minutes() > float(o["deadline"])
	objective_rows.add_child(_label("Prazo: %s%s" % [_clock_text(float(o["deadline"])), "  (atrasado!)" if late else ""], 13, Color("ffb4a8") if late else MUTED))
	var others: Array = []
	for other in jobs.keys():
		if other != id and not jobs[other]["done"]:
			others.append(_dev_name(other))
	if not others.is_empty():
		objective_rows.add_child(_label("Também na bancada: %s" % ", ".join(others), 13, MUTED))


func _refresh_repair_panel() -> void:
	if active_device == "":
		return
	var id := active_device
	repair_title.text = "Reparação: %s" % _dev_name(id)
	for c in repair_rows.get_children():
		c.queue_free()
	var j: Dictionary = jobs[id]
	var steps: Array = _fault(id)["steps"]
	var cur: int = j["step"]
	var cur_group: int = steps[cur]["g"] if cur < steps.size() else 99
	var groups: Array = _fault(id)["groups"]
	for gi in range(groups.size()):
		var text: String = groups[gi]
		if gi == 1 and bool(j["diagnosed"]):
			text += " (%s)" % _fault(id)["fault"]
		if gi == 2:
			var total := 0
			var done_count := 0
			for si in range(steps.size()):
				if str(steps[si]["act"]) == "unscrew":
					total = int(steps[si].get("need", 1))
					done_count = total if cur > si else (int(j["progress"]) if cur == si else 0)
			if total > 0:
				text += " (%d/%d)" % [done_count, total]
		var st := "done" if gi < cur_group else ("active" if gi == cur_group else "todo")
		repair_rows.add_child(_row(text, st))
	if cur < steps.size():
		var step: Dictionary = steps[cur]
		var need: int = step.get("need", 1)
		var extra := "  (%d/%d)" % [int(j["progress"]), need] if need > 1 else ""
		step_hint.text = "➜ " + str(step["text"]) + extra + "\nFerramenta: " + _tool_need_text(step["tool"])
		_set_hints([["mouse_l", str(step["verb"])], ["mouse_r", "Rodar"], ["TAB", "Ferramentas"], ["Esc", "Voltar"]])
	else:
		step_hint.text = "Reparação concluída!"


# --- orders board + parts shop -------------------------------------------------
func _build_board(base: Control) -> void:
	board_root = Control.new()
	board_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_child(board_root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_root.add_child(dim)
	var p := _panel(Color(0.035, 0.06, 0.1, 0.97), 16, Vector4(24, 18, 24, 20))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -390
	p.offset_right = 390
	p.offset_top = -300
	p.offset_bottom = 300
	board_root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	# tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)
	for t in [["orders", "Pedidos  (P)"], ["shop", "Loja de Peças  (L)"]]:
		var b := Button.new()
		b.text = t[1]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(190, 40)
		b.add_theme_font_override("font", font_xbold)
		b.add_theme_font_size_override("font_size", 18)
		var kind: String = t[0]
		b.pressed.connect(func() -> void: _open_board(kind))
		tabs.add_child(b)
		b.set_meta("kind", kind)
	board_root.set_meta("tabs", tabs)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(fill)
	var money_l := _label("", 18, TEXT, font_xbold)
	tabs.add_child(money_l)
	board_root.set_meta("money", money_l)
	var close := Button.new()
	close.text = "Fechar (Esc)"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_board)
	tabs.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	board_box = VBoxContainer.new()
	board_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_box.add_theme_constant_override("separation", 10)
	scroll.add_child(board_box)
	board_root.hide()


func _open_board(kind: String) -> void:
	if mode != "board":
		prev_mode = mode
	mode = "board"
	board_kind = kind
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	prompt.hide()
	board_root.show()
	_refresh_board()


func _close_board() -> void:
	board_root.hide()
	mode = prev_mode if prev_mode in ["walk", "inspect"] else "walk"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mode == "walk" else Input.MOUSE_MODE_HIDDEN
	if mode == "inspect":
		_activate_step_targets()
	_refresh_objective()


func _refresh_orders_panel() -> void:
	if board_root and board_root.visible:
		_refresh_board()


func _refresh_orders_badge() -> void:
	if orders_badge == null:
		return
	var n := 0
	for o in orders:
		if o["status"] == "new":
			n += 1
	orders_badge.text = str(n)
	(orders_badge.get_meta("wrap") as Control).visible = n > 0


func _refresh_board() -> void:
	for c in board_box.get_children():
		board_box.remove_child(c)
		c.queue_free()
	var tabs: HBoxContainer = board_root.get_meta("tabs")
	for b in tabs.get_children():
		if b is Button and b.has_meta("kind"):
			var sel: bool = b.get_meta("kind") == board_kind
			var sb := StyleBoxFlat.new()
			sb.bg_color = YELLOW if sel else Color(0.1, 0.15, 0.22, 1)
			sb.set_corner_radius_all(10)
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", sb)
			b.add_theme_stylebox_override("pressed", sb)
			b.add_theme_color_override("font_color", Color("10161d") if sel else TEXT)
			b.add_theme_color_override("font_hover_color", Color("10161d") if sel else TEXT)
	(board_root.get_meta("money") as Label).text = "%s    ★ %.1f" % [_eur(money), _reputation()]
	if board_kind == "orders":
		_fill_orders()
	else:
		_fill_shop()


func _fill_orders() -> void:
	if orders.is_empty():
		board_box.add_child(_label("Ainda não há clientes. Vão chegando ao longo do dia.", 18, MUTED))
		return
	var status_txt := {"new": ["NOVO PEDIDO", YELLOW], "accepted": ["NA FILA", Color("7fb3ff")], "repair": ["NA BANCADA", GREEN]}
	for o in orders:
		var card := _panel(Color(0.07, 0.11, 0.17, 1.0), 12, Vector4(14, 12, 14, 12))
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		card.add_child(h)
		# avatar with initial
		var av := Control.new()
		av.custom_minimum_size = Vector2(56, 56)
		var col: Color = o["color"]
		var initial: String = str(o["customer"]).left(1)
		var fnt := font_xbold
		av.draw.connect(func() -> void:
			av.draw_circle(Vector2(28, 28), 27, col)
			av.draw_string(fnt, Vector2(0, 38), initial, HORIZONTAL_ALIGNMENT_CENTER, 56, 28, Color("10161d")))
		h.add_child(av)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		h.add_child(info)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 10)
		top.add_child(_label("%s  •  %s" % [o["customer"], _dev_name(o["device"])], 19, TEXT, font_xbold))
		var st: Array = status_txt[o["status"]]
		top.add_child(_label(st[0], 13, st[1], font_xbold))
		info.add_child(top)
		var q := _label("“%s”" % o["complaint"], 16, Color("d3dde8"))
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.custom_minimum_size = Vector2(420, 0)
		info.add_child(q)
		var part: String = FAULTS[o["fault"]]["part"]
		var extra := ""
		if part != "" and o["status"] != "new":
			extra = "   •   Peça em stock: %d" % int(inventory.get(part, 0))
		info.add_child(_label("Pagamento: %s   •   Prazo: %s%s" % [_eur(float(o["pay"])), _clock_text(float(o["deadline"])), extra], 14, MUTED))
		var btns := VBoxContainer.new()
		btns.add_theme_constant_override("separation", 6)
		h.add_child(btns)
		if o["status"] == "new":
			var acc := _small_button("Aceitar", true)
			acc.pressed.connect(func() -> void: _accept_order(o))
			btns.add_child(acc)
			var dec := _small_button("Recusar", false)
			dec.pressed.connect(func() -> void: _decline_order(o))
			btns.add_child(dec)
		elif o["status"] == "accepted":
			btns.add_child(_label("Bancada ocupada", 13, MUTED))
		board_box.add_child(card)


func _fill_shop() -> void:
	board_box.add_child(_label("Entrega expresso: as peças chegam de imediato à prateleira.", 15, MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	board_box.add_child(grid)
	for key in Data.PARTS.keys():
		var pinfo: Dictionary = Data.PARTS[key]
		var card := _panel(Color(0.07, 0.11, 0.17, 1.0), 12, Vector4(14, 10, 14, 10))
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.custom_minimum_size = Vector2(355, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(str(pinfo["name"]), 17, TEXT, font_xbold))
		info.add_child(_label("%s   •   Em stock: %d" % [_eur(float(pinfo["price"])), int(inventory.get(key, 0))], 14, MUTED))
		h.add_child(info)
		var buy := _small_button("Comprar", true)
		var k: String = key
		buy.disabled = money < float(pinfo["price"])
		buy.pressed.connect(func() -> void: _buy_part(k))
		h.add_child(buy)
		grid.add_child(card)


func _buy_part(key: String) -> void:
	var price := float(Data.PARTS[key]["price"])
	if money < price:
		_toast("Dinheiro insuficiente.", true)
		return
	money -= price
	day_profit -= price
	inventory[key] = int(inventory.get(key, 0)) + 1
	_toast("Comprado: %s (-%s)" % [Data.PARTS[key]["name"], _eur(price)], false, GREEN)
	_refresh_board()


func _small_button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(110, 36)
	b.add_theme_font_override("font", font_xbold)
	b.add_theme_font_size_override("font_size", 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = YELLOW if primary else Color(0.14, 0.2, 0.29, 1)
	sb.set_corner_radius_all(9)
	var hv := sb.duplicate() as StyleBoxFlat
	hv.bg_color = sb.bg_color.lightened(0.15)
	var ds := sb.duplicate() as StyleBoxFlat
	ds.bg_color = Color(0.2, 0.22, 0.25, 1)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.add_theme_stylebox_override("disabled", ds)
	b.add_theme_color_override("font_color", Color("10161d") if primary else TEXT)
	b.add_theme_color_override("font_hover_color", Color("10161d") if primary else TEXT)
	return b


# --- tool wheel -----------------------------------------------------------------
func _build_wheel(base: Control) -> void:
	wheel_root = Control.new()
	wheel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wheel_root.mouse_filter = Control.MOUSE_FILTER_STOP
	base.add_child(wheel_root)
	var blur := ColorRect.new()
	blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, 3.2).rgb;
	COLOR = vec4(c * 0.55, 1.0);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	blur.material = sm
	wheel_root.add_child(blur)
	wheel = Radial.new()
	wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wheel_root.add_child(wheel)
	wheel.setup(icon_tex, font_xbold)
	wheel.chosen.connect(func(id: String) -> void:
		_equip(id)
		_close_wheel())
	var hb := HBoxContainer.new()
	hb.anchor_left = 0.5
	hb.anchor_right = 0.5
	hb.anchor_top = 1.0
	hb.anchor_bottom = 1.0
	hb.offset_left = -230
	hb.offset_right = 230
	hb.offset_top = -64
	hb.offset_bottom = -22
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 10)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for it in [["mouse", "Selecionar"], ["E", "Confirmar"], ["Esc", "Fechar"]]:
		var p := _panel(Color(0.04, 0.07, 0.11, 0.9), 10, Vector4(12, 6, 14, 6))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		p.add_child(h)
		if str(it[0]) == "mouse":
			h.add_child(_icon("mouse", 24))
		else:
			h.add_child(_keycap(it[0]))
		h.add_child(_label(it[1], 17))
		hb.add_child(p)
	wheel_root.add_child(hb)
	wheel_root.hide()


func _open_wheel() -> void:
	prev_mode = mode
	mode = "wheel"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	prompt.hide()
	wheel_root.show()
	wheel.open(tool)
	Input.warp_mouse(get_viewport().get_visible_rect().size * 0.5)


func _close_wheel() -> void:
	wheel_root.hide()
	mode = prev_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mode == "walk" else Input.MOUSE_MODE_HIDDEN


# --- main menu -------------------------------------------------------------------
func _build_menu(base: Control) -> void:
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_child(menu_root)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/menu_workshop.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(bg)
	# left sidebar gradient
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.02, 0.05, 0.09, 0.96), Color(0.02, 0.05, 0.09, 0.86), Color(0.02, 0.05, 0.09, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 4
	var side := TextureRect.new()
	side.texture = gt
	side.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	side.stretch_mode = TextureRect.STRETCH_SCALE
	side.anchor_bottom = 1.0
	side.offset_right = 520
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(side)

	var col := VBoxContainer.new()
	col.anchor_bottom = 1.0
	col.offset_left = 54
	col.offset_right = 404
	col.offset_top = 48
	col.offset_bottom = -30
	col.add_theme_constant_override("separation", 10)
	menu_root.add_child(col)
	col.add_child(_logo())
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 22)
	col.add_child(sp)
	menu_buttons = VBoxContainer.new()
	menu_buttons.add_theme_constant_override("separation", 10)
	col.add_child(menu_buttons)
	menu_buttons.add_child(_menu_button("Começar Jogo", "play", true, _new_game))
	load_button = _menu_button("Carregar Jogo", "folder", false, _continue_game)
	menu_buttons.add_child(load_button)
	menu_buttons.add_child(_menu_button("Definições", "gear", false, func() -> void: _show_menu_panel("settings")))
	menu_buttons.add_child(_menu_button("Créditos", "info", false, func() -> void: _show_menu_panel("credits")))
	menu_buttons.add_child(_menu_button("Sair", "power", false, func() -> void: get_tree().quit()))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fill)
	col.add_child(_label("%s  •  Compra, repara e revende" % VERSION, 14, Color(0.75, 0.82, 0.9, 0.7)))
	# right side host for settings / credits panels (inside the sidebar width)
	menu_panel_host = Control.new()
	menu_panel_host.anchor_bottom = 1.0
	menu_panel_host.offset_left = 420
	menu_panel_host.offset_right = 800
	menu_panel_host.offset_top = 210
	menu_root.add_child(menu_panel_host)


func _logo() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -14)
	var neon := Color("8fd8ff")
	for line in ["FIX & FLIP", "TECH"]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var l := _label(line, 66, neon, font_xbold)
		l.add_theme_color_override("font_outline_color", Color(0.1, 0.45, 1.0, 0.9))
		l.add_theme_constant_override("outline_size", 9)
		l.add_theme_color_override("font_shadow_color", Color(0.1, 0.5, 1.0, 0.55))
		l.add_theme_constant_override("shadow_outline_size", 22)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)
		h.add_child(l)
		if line == "TECH":
			var gear := _icon("gear", 46, YELLOW)
			gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(gear)
		box.add_child(h)
	var pill := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.08, 0.16, 0.7)
	sb.border_color = Color("3ab7ff")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0.1, 0.55, 1.0, 0.45)
	sb.shadow_size = 12
	pill.add_theme_stylebox_override("panel", sb)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var pl := _label("Oficina de Eletrónica", 24, Color("bfeaff"), font_xbold)
	pl.add_theme_color_override("font_outline_color", Color(0.1, 0.45, 1.0, 0.7))
	pl.add_theme_constant_override("outline_size", 4)
	pill.add_child(pl)
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 14)
	wrap.add_child(box)
	wrap.add_child(pill)
	return wrap


func _menu_button(text: String, icon_kind: String, primary: bool, action: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 50)
	b.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("f5b82e") if primary else Color(0.09, 0.14, 0.21, 0.88)
	normal.set_corner_radius_all(10)
	normal.border_color = Color(1, 1, 1, 0.08) if not primary else Color("ffd477")
	normal.set_border_width_all(1)
	normal.shadow_color = Color(0, 0, 0, 0.35)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("ffc94d") if primary else Color(0.15, 0.22, 0.32, 0.95)
	hover.border_color = Color("f5b82e")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.09, 0.14, 0.21, 0.5)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", disabled)
	b.pressed.connect(action)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 20
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var ic := _icon(icon_kind, 22, Color("10161d") if primary else YELLOW)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := _label(text, 20, Color("10161d") if primary else TEXT, font_xbold)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	b.set_meta("label", l)
	return b


func _show_menu_panel(which: String) -> void:
	for c in menu_panel_host.get_children():
		c.queue_free()
	var p := _panel(Color(0.04, 0.07, 0.12, 0.93), 14, Vector4(22, 18, 22, 18))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.custom_minimum_size = Vector2(360, 0)
	menu_panel_host.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	if which == "settings":
		v.add_child(_label("Definições", 24, YELLOW, font_xbold))
		v.add_child(_label("Qualidade gráfica", 16, MUTED))
		var q := OptionButton.new()
		for t in ["Baixa (PC fraco)", "Média", "Alta (SSIL, reflexos, nevoeiro)"]:
			q.add_item(t)
		q.selected = int(settings["quality"])
		q.item_selected.connect(func(i: int) -> void:
			settings["quality"] = i
			_apply_settings()
			_save_settings())
		v.add_child(q)
		v.add_child(_label("Sensibilidade do rato", 16, MUTED))
		var s := HSlider.new()
		s.min_value = 0.3
		s.max_value = 2.5
		s.step = 0.05
		s.value = float(settings["sensitivity"])
		s.value_changed.connect(func(val: float) -> void:
			settings["sensitivity"] = val
			_save_settings())
		v.add_child(s)
		var fs := CheckButton.new()
		fs.text = "Ecrã inteiro"
		fs.button_pressed = bool(settings["fullscreen"])
		fs.toggled.connect(func(on: bool) -> void:
			settings["fullscreen"] = on
			_apply_settings()
			_save_settings())
		v.add_child(fs)
	else:
		v.add_child(_label("Créditos", 24, YELLOW, font_xbold))
		var t := _label("Fix & Flip Tech — protótipo de simulação de oficina.\n\nModelos 3D, materiais e animações gerados por código no Godot 4.\nTipo de letra: Nunito (SIL Open Font License).\n\nObrigado por jogares!", 16, TEXT)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(316, 0)
		v.add_child(t)
	var close := _menu_button("Voltar", "play", false, func() -> void:
		for c in menu_panel_host.get_children():
			c.queue_free())
	v.add_child(close)


func _show_menu() -> void:
	mode = "menu"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_root.show()
	hud.hide()
	pause_root.hide()
	wheel_root.hide()
	popup_root.hide()
	board_root.hide()
	hand.visible = false
	load_button.disabled = not _has_save()
	(load_button.get_meta("label") as Label).modulate.a = 1.0 if _has_save() else 0.45
	_reset_walk_camera()


func _new_game() -> void:
	day = 1
	minutes = 8 * 60
	money = 250
	xp = 0
	level = 1
	repaired = 0
	day_profit = 0
	ratings = []
	inventory = {"battery": 1, "phone_screen": 1}
	_reset_jobs()
	orders.clear()
	_save_game()
	_start_game(true)


func _continue_game() -> void:
	if _load_game():
		_reset_jobs()
		orders.clear()
		_start_game(false)


func _start_game(first: bool) -> void:
	for c in menu_panel_host.get_children():
		c.queue_free()
	var tw := create_tween()
	fade.color.a = 0.0
	tw.tween_property(fade, "color:a", 1.0, 0.3)
	tw.tween_callback(func() -> void:
		menu_root.hide()
		hud.show()
		mode = "walk"
		_reset_walk_camera()
		_equip("none")
		crosshair.show()
		reticle.hide()
		objective_panel.show()
		repair_panel.hide()
		hints_bar.hide()
		_hotbar_compact(false)
		focus_job = ""
		next_order_at = _abs_minutes() + 40.0
		_new_order(true)
		_new_order(true)
		_refresh_objective()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if first:
			_toast("Bem-vindo à oficina! Tens clientes à espera: carrega P para ver os pedidos.", false, YELLOW)
		else:
			_toast("Bem-vindo de volta! Carrega P para ver os pedidos.", false, YELLOW))
	tw.tween_property(fade, "color:a", 0.0, 0.5)


# --- pause / popups --------------------------------------------------------------
func _build_pause(base: Control) -> void:
	pause_root = Control.new()
	pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_child(pause_root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_root.add_child(dim)
	var p := _panel(Color(0.04, 0.07, 0.12, 0.95), 14, Vector4(26, 20, 26, 22))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -180
	p.offset_right = 180
	p.offset_top = -170
	p.offset_bottom = 170
	pause_root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(_label("Pausa", 28, YELLOW, font_xbold))
	v.add_child(_menu_button("Continuar", "play", true, _resume))
	v.add_child(_menu_button("Guardar Jogo", "folder", false, func() -> void:
		_save_game()
		_toast("Jogo guardado.", false, GREEN)))
	v.add_child(_menu_button("Menu Principal", "info", false, func() -> void:
		_save_game()
		_show_menu()))
	v.add_child(_menu_button("Sair", "power", false, func() -> void:
		_save_game()
		get_tree().quit()))
	pause_root.hide()


func _pause() -> void:
	mode = "pause"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_root.show()


func _resume() -> void:
	pause_root.hide()
	mode = "walk"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_popup(base: Control) -> void:
	popup_root = Control.new()
	popup_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_child(popup_root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_root.add_child(dim)
	var p := _panel(Color(0.04, 0.07, 0.12, 0.96), 16, Vector4(28, 22, 28, 24))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -230
	p.offset_right = 230
	p.offset_top = -170
	p.offset_bottom = 170
	popup_root.add_child(p)
	popup_box = VBoxContainer.new()
	popup_box.add_theme_constant_override("separation", 10)
	p.add_child(popup_box)
	popup_root.hide()


func _open_popup(title: String, lines: Array, buttons: Array, closable: bool) -> void:
	prev_mode = mode if mode != "popup" else prev_mode
	mode = "popup"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	prompt.hide()
	for c in popup_box.get_children():
		c.queue_free()
	popup_box.add_child(_label(title, 28, YELLOW, font_xbold))
	for ln in lines:
		var l := _label(str(ln[0]), 18, ln[1])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		popup_box.add_child(l)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	popup_box.add_child(sp)
	for b in buttons:
		popup_box.add_child(_menu_button(str(b[0]), "play", true, b[1]))
	if closable:
		popup_root.set_meta("closable", true)
	elif popup_root.has_meta("closable"):
		popup_root.remove_meta("closable")
	popup_root.show()


func _close_popup() -> void:
	popup_root.hide()
	mode = prev_mode if prev_mode != "popup" else "walk"
	if mode == "walk":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif mode == "inspect":
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
