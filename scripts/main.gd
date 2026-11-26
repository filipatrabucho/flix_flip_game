extends Node3D
## Fix & Flip Tech — game controller: menu, workshop walk mode, repair
## (inspect) mode with a gloved hand, tool wheel, HUD and progression.

const Kit = preload("res://scripts/kit.gd")
const Room = preload("res://scripts/room.gd")
const Laptop = preload("res://scripts/laptop.gd")
const Phone = preload("res://scripts/phone.gd")
const Gamepad = preload("res://scripts/gamepad.gd")
const ConsoleDev = preload("res://scripts/console.gd")
const HandheldDev = preload("res://scripts/handheld.gd")
const RotaryDev = preload("res://scripts/rotary_phone.gd")
const RadioDev = preload("res://scripts/radio.gd")
const DeviceBase = preload("res://scripts/device_base.gd")
const Data = preload("res://scripts/jobs_data.gd")
const I18n = preload("res://scripts/i18n.gd")
const Story = preload("res://scripts/story_data.gd")
const CustomerScene = preload("res://scripts/customer.gd")
const AudioMgr = preload("res://scripts/audio.gd")
const Hand = preload("res://scripts/glove_hand.gd")
const Tools = preload("res://scripts/tools3d.gd")
const UIcon = preload("res://scripts/ui_icon.gd")
const Staff = preload("res://scripts/staff_data.gd")
const Radial = preload("res://scripts/radial_menu.gd")

const SAVE_PATH := "user://fix_flip_save_%d.json"
const OLD_SAVE_PATH := "user://fix_flip_save.json"
const SETTINGS_PATH := "user://fix_flip_settings.cfg"
const VERSION := "v1.4"

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
	"screwdriver": [Vector3(0.66, 0.92, -1.02), -32.0],
	"brush": [Vector3(0.78, 0.92, -1.05), 12.0],
	"air": [Vector3(0.92, 0.92, -1.2), 0.0],
	"cloth": [Vector3(0.66, 0.92, -1.30), 18.0],
	"multimeter": [Vector3(0.86, 0.92, -1.38), -10.0],
}

const GAMEPAD_POS := Vector3(0.33, MAT_Y, -1.02)
const SLOT_POS := {"laptop": [LAPTOP_POS, 4.0], "phone": [PHONE_POS, -12.0], "gamepad": [GAMEPAD_POS, 8.0]}
const PART_POS := {"laptop": NEW_BATTERY_POS, "phone": NEW_SCREEN_POS, "gamepad": Vector3(0.50, MAT_Y + 0.0002, -1.02)}
const COVER_ASIDE_BY := {"laptop": COVER_ASIDE, "gamepad": Vector3(0.10, MAT_Y + 0.0002, -0.99)}
## Bench spots: position, yaw, size class, where removed covers go and where spare parts appear.
const SPOTS := {
	"A": {"pos": Vector3(-0.12, MAT_Y, -1.22), "yaw": 4.0, "size": "L", "cover": Vector3(-0.15, MAT_Y + 0.001, -1.56), "part": Vector3(0.145, MAT_Y + 0.0002, -1.24)},
	"C": {"pos": Vector3(-0.72, 0.92, -1.30), "yaw": 8.0, "size": "L", "cover": Vector3(-0.74, 0.921, -1.03), "part": Vector3(-0.40, MAT_Y + 0.0002, -1.04)},
	"B": {"pos": Vector3(0.29, MAT_Y, -1.17), "yaw": -12.0, "size": "S", "cover": Vector3(0.47, MAT_Y + 0.0003, -1.42), "part": Vector3(0.475, MAT_Y + 0.0002, -1.2)},
	"D": {"pos": Vector3(0.33, MAT_Y, -1.02), "yaw": 8.0, "size": "S", "cover": Vector3(0.12, MAT_Y + 0.0002, -0.99), "part": Vector3(0.50, MAT_Y + 0.0002, -1.02)},
}

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
var order_number := 0
var FAULTS: Dictionary = Data.faults()
var customers: Dictionary = {}         # order id -> customer node
var counter_queue: Array = []
var upgrades: Dictionary = {}          # upgrade id -> true
var deliveries: Array = []             # parts in transit: {key, arrive}
var parcels: Array = []                # parcels on the receiving shelf: {key, node, body, slot}
var reserved_slots: Array = []         # receiving slots the postman is walking to
var postman_keys: Array = []
var carrying: Dictionary = {}          # {"order": o} while holding a repaired device
var carry_node: Node3D
var shelf_items: Array = [null, null, null, null]   # pickup shelf slots -> {order, node}
var shelf_bodies: Array = []
var cash_items: Array = []             # money left on the counter: {amount, node, body}
var part_icons: Dictionary = {}
var shop_filter := "all"
var story_chapter := 0
var story_deliveries := 0
var story_flags: Dictionary = {}
var rent_due_day := 0
var rent_amount := 300
var dialog_root: Control
var dialog_avatar: Control
var dialog_name: Label
var dialog_text: Label
var dialog_buttons: HBoxContainer
var dialog_lines: Array = []
var dialog_btns: Array = []
var dialog_done := Callable()
var dialog_prev_mode := "walk"
var audio: Node
var step_accum := 0.0
var active_device := ""
var focus_job := "laptop"
var walk_yaw := 0.0
var walk_pitch := -0.42
var hovered_pick := ""
var hovered_target := ""
var hovered_cash: Dictionary = {}
var hovered_parcel: Dictionary = {}
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
var pause_panel: PanelContainer
var pause_main: VBoxContainer
var pause_settings_box: VBoxContainer
var current_slot := 1
var stamina := 100.0
var hunger := 100.0                    # 100 = full, 0 = starving
var energy_bar: ProgressBar
var hunger_bar: ProgressBar
var tired_warned := false
var coffee_body: StaticBody3D
var decor_items: Array = []            # {id, node, body}
var moving: Dictionary = {}            # object being rearranged
var hovered_movable: Dictionary = {}
var fade: ColorRect
var meter_panel: PanelContainer
var board_root: Control
var board_box: VBoxContainer
var board_kind := ""
var orders_badge: Label
var expansion := 0                 # 0 none, 1 annex, 2 full expansion
var staff: Array = []              # hired employees
var candidates: Array = []         # job applicants (refreshed daily)
var staff_seq := 0
var staff_first := true            # new jobs go to idle technicians before the player's bench
var staff_last_min := -1.0
var staff_nodes: Dictionary = {}   # staff id -> CustomerScene
var flip_offers: Array = []        # used devices for sale (refreshed daily)
var daily_goals: Array = []
var stats: Dictionary = {}
var achievements: Dictionary = {}
var annex_door_body: StaticBody3D
var retail_stock: Dictionary = {}    # product -> units in the back store
var stand_items: Array = []          # display stand slots: null or {"key", "qty", "node"}
var shopper_next := 0.0
var meter_label: Label


func T(s: String) -> String:
	return I18n.t(s)


func _sfx(name: String, vol := 1.0) -> void:
	if audio:
		audio.play(name, vol)


func _ready() -> void:
	randomize()
	_load_settings()
	_migrate_old_save()
	audio = AudioMgr.new()
	add_child(audio)
	audio.set_volumes(float(settings.get("music", 0.6)), float(settings.get("sfx", 0.8)))
	_load_fonts()
	room = Room.new()
	room.build(self)
	_build_camera()
	_build_tray()
	_build_tools()
	_build_hand()
	_reset_jobs()
	_build_icons()
	_build_shelf_targets()
	_build_place_colliders()
	var bell_body := Kit.static_body(self, Kit.sphere_shape(0.07), room.bell.global_position + Vector3(0, 0.03, 0), "bell")
	bell_body.collision_layer = 1
	for si in range(room.stools.size()):
		var sb := Kit.static_body(self, Kit.sphere_shape(0.22), room.stools[si] + Vector3(0, 0.62, 0), "stool:%d" % si)
		sb.collision_layer = 1
	for t in [["bed", room.bed_pos + Vector3(0, 0.15, 0), Vector3(0.8, 0.35, 2.0)], ["fridge", room.fridge_pos + Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.6)], ["kettle", room.kettle_pos + Vector3(0, 0.55, 0), Vector3(0.5, 0.3, 0.4)]]:
		var tb := Kit.static_body(self, Kit.box_shape(t[2]), t[1], t[0])
		tb.collision_layer = 1
	_build_ui()
	_apply_settings()
	_show_menu()


# =============================================================================
# World setup
# =============================================================================
func _load_fonts() -> void:
	font_bold = _font("res://assets/fonts/Nunito-Bold.ttf")
	font_xbold = _font("res://assets/fonts/Nunito-ExtraBold.ttf")
	# symbols (★ ✓ ➜ ✕) are missing from Nunito and browsers have no system fallback fonts
	var sym := _font("res://assets/fonts/DejaVuSans-Symbols.ttf")
	if sym != ThemeDB.fallback_font:
		for f in [font_bold, font_xbold, ThemeDB.fallback_font]:
			if f and f != sym:
				var fb: Array[Font] = f.fallbacks
				if not fb.has(sym):
					fb.append(sym)
					f.fallbacks = fb


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


func _clear_customers() -> void:
	for c in customers.values():
		if is_instance_valid(c):
			c.queue_free()
	customers.clear()
	counter_queue.clear()


func _fault(id: String) -> Dictionary:
	return FAULTS[jobs[id]["fault"]]


func _dev_name(id: String) -> String:
	return T(str(Data.DEVICES[id]["name"]))


func _free_spot(device: String) -> String:
	var size: String = Data.SIZE.get(device, "S")
	var used: Array = []
	for j in jobs.values():
		used.append(j.get("spot", ""))
	var order := ["A", "C"] if size == "L" else ["B", "D", "A", "C"]
	if device == "laptop":
		order = ["A", "C"]
	for sp in order:
		if not used.has(sp):
			return sp
	return ""


func _spot(id: String) -> Dictionary:
	return SPOTS[jobs[id].get("spot", "A")]


## Puts a customer's device on a free bench spot, set up for its fault.
func _spawn_device(id: String, order: Dictionary) -> void:
	if devices.has(id) and is_instance_valid(devices[id]):
		devices[id].queue_free()
	var spot_key := _free_spot(id)
	if spot_key == "":
		spot_key = "A"
	var d: Node3D
	match id:
		"laptop":
			d = Laptop.new()
		"phone":
			d = Phone.new()
		"console":
			d = ConsoleDev.new()
		"handheld":
			d = HandheldDev.new()
		"rotary":
			d = RotaryDev.new()
		"radio":
			d = RadioDev.new()
		_:
			d = Gamepad.new()
	var spot: Dictionary = SPOTS[spot_key]
	d.position = spot["pos"]
	d.rotation_degrees.y = spot["yaw"]
	add_child(d)
	devices[id] = d
	d.set_pickable(true)
	var fk: String = order["fault"]
	if id == "laptop":
		d.set_dirty(fk == "laptop_battery" or fk == "laptop_fan")
	elif id == "phone" and fk != "phone_screen":
		d.set_screen_ok()
	elif d.has_method("set_dirty"):
		d.set_dirty(fk in ["console_overheat", "rotary_bell", "radio_static"])
	jobs[id] = {"order": order, "fault": fk, "step": 0, "progress": 0, "diagnosed": false, "done": false, "used": [], "spot": spot_key}
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
	if mode in ["walk", "inspect", "wheel", "sit"]:
		var dm := delta * (0.25 if mode == "wheel" else (4.0 if mode == "sit" else 1.0))
		minutes += dm
		hunger = maxf(0.0, hunger - dm * 0.09)
		if mode == "sit":
			stamina = minf(100.0, stamina + dm * (0.12 if hunger > 0.0 else 0.03))
		else:
			stamina = maxf(0.0, stamina - dm * 0.035 * (2.5 if hunger <= 0.0 else (1.6 if hunger < 25.0 else 1.0)))
		_update_fatigue()
		if minutes >= 20 * 60:
			_end_of_day()
		elif mode != "wheel":
			_order_tick()
	for c in customers.values():
		if is_instance_valid(c):
			c.look_target = cam.global_position
	if mode == "move":
		_walk_move(delta)
		_update_move()
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
	for de in decor_items:
		if de["id"] == "clock" and is_instance_valid(de["node"]):
			var mm := int(minutes) % 720
			(de["node"].get_node("HourHand") as Node3D).rotation.z = -TAU * mm / 720.0
			(de["node"].get_node("MinuteHand") as Node3D).rotation.z = -TAU * (mm % 60) / 60.0
	if reticle and reticle.visible:
		reticle.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event as InputEventKey)
	if mode == "move":
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var sens3: float = 0.0024 * float(settings["sensitivity"])
			walk_yaw -= event.relative.x * sens3
			walk_pitch = clampf(walk_pitch - event.relative.y * sens3, -1.35, 1.2)
			cam.rotation = Vector3(walk_pitch, walk_yaw, 0)
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_end_move(true)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_rotate_moving(1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0)
		return
	if mode == "sit" and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens2: float = 0.0024 * float(settings["sensitivity"])
		walk_yaw -= event.relative.x * sens2
		walk_pitch = clampf(walk_pitch - event.relative.y * sens2, -1.35, 1.2)
		cam.rotation = Vector3(walk_pitch, walk_yaw, 0)
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
	if mode == "dialog":
		if k == KEY_E or k == KEY_ENTER or k == KEY_SPACE or k == KEY_KP_ENTER:
			_dialog_advance()
		return
	if mode == "move":
		if k == KEY_ESCAPE:
			_end_move(false)
		elif k == KEY_R:
			_rotate_moving()
		elif k == KEY_G or k == KEY_E or k == KEY_ENTER:
			_end_move(true)
		return
	if mode == "sit":
		if k == KEY_ESCAPE:
			_pause()
		elif k in [KEY_E, KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			_stand_up()
		return
	if mode == "board":
		if k == KEY_ESCAPE or (k == KEY_P and board_kind == "orders") or (k == KEY_L and board_kind == "shop") or (k == KEY_U and board_kind == "upgrades") or (k == KEY_F and board_kind == "team") or (k == KEY_M and board_kind == "goals"):
			_close_board()
		elif k == KEY_F:
			_open_board("team")
		elif k == KEY_M:
			_open_board("goals")
		elif k == KEY_U:
			_open_board("upgrades")
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
	elif k == KEY_U:
		_open_board("upgrades")
	elif k == KEY_F:
		_open_board("team")
	elif k == KEY_M:
		_open_board("goals")
	elif k >= KEY_1 and k <= KEY_5:
		var id: String = Tools.IDS[k - KEY_1]
		_equip(id if tool != id else "none")
	elif k == KEY_Q:
		_equip("none")
	elif k == KEY_E and mode == "walk":
		_interact_walk()
	elif k == KEY_G and mode == "walk" and not hovered_movable.is_empty():
		_start_move(hovered_movable)
	elif k == KEY_R and mode == "inspect":
		orbit = Vector2.ZERO
		zoom = 1.0
	elif k == KEY_T and mode == "inspect" and jobs.has(active_device):
		_delegate_best(jobs[active_device]["order"])
	elif k == KEY_T and mode == "walk" and hovered_pick.begins_with("device:") and jobs.has(hovered_pick.substr(7)):
		_delegate_best(jobs[hovered_pick.substr(7)]["order"])


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
		var o := cam.position
		if not _walk_ok(p):
			if _walk_ok(Vector3(p.x, o.y, o.z)):
				p = Vector3(p.x, o.y, o.z)
			elif _walk_ok(Vector3(o.x, o.y, p.z)):
				p = Vector3(o.x, o.y, p.z)
			else:
				p = o
		p.y = EYE_H + sin(Time.get_ticks_msec() * 0.009) * 0.006
		step_accum += cam.position.distance_to(p)
		if step_accum > 0.62:
			step_accum = 0.0
			_sfx("step", 0.5)
		cam.position = p


## Walkable areas: shop floor (minus the counter), doorway, back room.
func _walk_ok(p: Vector3) -> bool:
	var in_main := p.x >= -2.3 and p.x <= 2.3 and p.z <= 2.3 and (p.z >= -0.62 or (p.x < -2.0 and p.z >= -1.05))
	if in_main and p.x > -0.65 and p.x < 1.65 and p.z > 1.0 and p.z < 1.95:
		in_main = false
	if in_main and p.x > -2.35 and p.x < -0.5 and p.z > 2.08:
		in_main = false
	if in_main and p.x < -2.05 and p.z > 1.78:
		in_main = false
	var in_door := p.x >= -2.98 and p.x <= -2.2 and p.z >= -1.05 and p.z <= -0.45
	var in_back := p.x >= -4.45 and p.x <= -2.88 and p.z >= -1.55 and p.z <= 0.42
	if expansion >= 1:
		var in_adoor := p.x >= 2.2 and p.x <= 2.95 and p.z >= -0.82 and p.z <= -0.28
		var in_annex := p.x >= 2.85 and p.x <= 5.5 and p.z >= -0.78 and p.z <= (0.42 if expansion >= 2 else 1.25)
		if in_adoor or in_annex:
			return true
	return in_main or in_door or in_back


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
		elif t == "stand":
			pick = "stand"
			where = hit.collider.global_position + Vector3(0, 0.85, 0)
		elif t == "bell":
			pick = "bell"
			where = hit.collider.global_position + Vector3(0, 0.08, 0)
		elif t.begins_with("stool:"):
			pick = t
			where = hit.collider.global_position + Vector3(0, 0.3, 0)
		elif t in ["bed", "fridge", "kettle", "coffee_machine"]:
			pick = t
			where = hit.collider.global_position + Vector3(0, 0.35, 0)
		elif t.begins_with("shelf:") or t == "cash" or t.begins_with("parcel"):
			pick = t
			where = hit.collider.global_position + Vector3(0, 0.12, 0)
			if t == "cash":
				pick = "cash"
				hovered_cash = hit.collider.get_meta("cash")
				hovered_pick = ""
			elif t.begins_with("parcel"):
				hovered_parcel = hit.collider.get_meta("parcel")
		elif t == "customer":
			var cn: Node3D = hit.collider.get_meta("customer")
			if is_instance_valid(cn) and not cn.walking:
				pick = "cust:%d" % cn.order_id
				where = cn.global_position + Vector3(0, 2.0 * cn.height, 0)
	hovered_movable = {}
	if not hit.is_empty() and hit.collider.has_meta("target"):
		var mt := str(hit.collider.get_meta("target"))
		if mt.begins_with("tool:"):
			var tid2 := mt.substr(5)
			if tool != tid2:
				hovered_movable = {"node": bench_tools[tid2], "kind": "tool", "id": tid2, "pick": hit.collider, "place": "surface"}
		elif mt == "device" and devices.has(str(hit.collider.get_meta("device", ""))):
			var did := str(hit.collider.get_meta("device"))
			hovered_movable = {"node": devices[did], "kind": "device", "id": did, "pick": hit.collider, "place": "surface"}
		elif mt.begins_with("upgrade:") or mt == "coffee_machine":
			var uid := "coffee" if mt == "coffee_machine" else mt.substr(8)
			if room.upgrade_nodes.has(uid):
				hovered_movable = {"node": room.upgrade_nodes[uid], "kind": "upgrade", "id": uid, "pick": hit.collider, "place": UPGRADE_PLACE.get(uid, "surface")}
				if mt != "coffee_machine":
					pick = mt
					where = hit.collider.global_position + Vector3(0, 0.2, 0)
		elif mt.begins_with("decor:"):
			var di := int(mt.substr(6))
			if di < decor_items.size():
				var de: Dictionary = decor_items[di]
				hovered_movable = {"node": de["node"], "kind": "decor", "id": de["id"], "pick": hit.collider, "place": Room.DECOR[de["id"]]["place"]}
				pick = mt
				where = hit.collider.global_position + Vector3(0, 0.25, 0)
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
	if pick.begins_with("shelf:"):
		var si := int(pick.substr(6))
		if not carrying.is_empty() and shelf_items[si] == null:
			text = T("Pousar no lugar #%d") % (si + 1)
		elif carrying.is_empty() and shelf_items[si] != null:
			var so: Dictionary = shelf_items[si]["order"]
			text = T("Pegar pedido #%d (%s)") % [int(so["number"]), so["customer"]]
		else:
			prompt.hide()
			return
		_show_prompt("E", text, where)
		return
	if pick == "bell":
		_show_prompt("E", T("Tocar a campainha"), where)
		return
	if pick == "stand":
		var back := 0
		for k in retail_stock.keys():
			back += int(retail_stock[k])
		_show_prompt("E", T("Repor o expositor (%d em armazém)") % back if back > 0 else T("Expositor: %d produtos  •  Encomendar mais") % _stand_count(), where)
		return
	if pick == "bed":
		_show_prompt("E", T("Fechar a loja e dormir"), where)
		return
	if pick.begins_with("stool:"):
		_show_prompt("E", T("Sentar e esperar por clientes"), where)
		return
	if pick == "fridge":
		_show_prompt("E", T("Comer um snack (%s)") % _eur(3.0), where)
		return
	if pick == "kettle":
		_show_prompt("E", T("Fazer um café (%s)") % _eur(1.0), where)
		return
	if pick == "coffee_machine":
		_show_prompt("E", T("Tirar um café"), where)
		return
	if pick == "cash":
		_show_prompt("E", T("Guardar %s na caixa") % _eur(float(hovered_cash.get("amount", 0.0))), where)
		return
	if pick.begins_with("parcel"):
		_show_prompt("E", T("Abrir encomenda: %s") % _item_name(str(hovered_parcel.get("key", "battery"))), where)
		return
	if pick.begins_with("upgrade:"):
		var un := T(str(Data.UPGRADES[pick.substr(8)]["name"]))
		_show_prompt("G", un, where)
		prompt_label.text = T("Mover %s") % un
		return
	if pick.begins_with("decor:"):
		_show_prompt("G", T(Room.DECOR[hovered_movable.get("id", "rug")]["name"]), where)
		prompt_label.text = T("Mover %s") % T(Room.DECOR[hovered_movable.get("id", "rug")]["name"])
		return
	if pick.begins_with("cust:"):
		var cc: Node3D = customers.get(int(pick.substr(5)))
		if cc == null:
			prompt.hide()
			return
		var purpose := str(cc.get_meta("purpose", "order"))
		text = (T("Entregar a %s") if purpose == "pickup" else T("Falar com %s")) % cc.display_name
	elif pick.begins_with("device:"):
		var id := pick.substr(7)
		text = T("Reparar %s de %s") % [_dev_name(id), jobs[id]["order"]["customer"]] if not jobs[id]["done"] else T("Pegar %s reparado") % _dev_name(id).to_lower()
		if not jobs[id]["done"] and _tech_count() > 0:
			text += "    [T] " + T("Passar a técnico")
	else:
		var tid := pick.substr(5)
		text = T("Pegar %s") % T(Tools.NAMES[tid]) if tool != tid else T("Pousar %s") % T(Tools.NAMES[tid])
	_show_prompt("E", text, where)


func _show_prompt(key: String, text: String, world_pos: Vector3) -> void:
	if not hovered_movable.is_empty() and mode == "walk":
		text += "    [G] " + T("Mover")
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
	if hovered_pick.begins_with("cust:"):
		var cc: Node3D = customers.get(int(hovered_pick.substr(5)))
		if cc and is_instance_valid(cc):
			_talk_to_customer(cc)
		return
	if hovered_pick.begins_with("shelf:"):
		var si := int(hovered_pick.substr(6))
		if not carrying.is_empty() and shelf_items[si] == null:
			_shelf_place(si)
		elif carrying.is_empty() and shelf_items[si] != null:
			_shelf_take(si)
		return
	if hovered_pick.begins_with("stool:"):
		_sit(int(hovered_pick.substr(6)))
		return
	if hovered_pick in ["bed", "fridge", "kettle", "coffee_machine"]:
		_use_comfort(hovered_pick)
		return
	if hovered_pick == "stand":
		_stand_restock()
		return
	if hovered_pick == "bell":
		room.ring_bell()
		if audio:
			audio.play("bell", 0.8, 0.12)
		return
	if hovered_pick == "cash":
		if not hovered_cash.is_empty() and cash_items.has(hovered_cash):
			_collect_cash(hovered_cash)
		return
	if hovered_pick.begins_with("parcel"):
		if not hovered_parcel.is_empty() and parcels.has(hovered_parcel):
			_open_parcel(hovered_parcel)
		return
	if hovered_pick.begins_with("device:"):
		var id := hovered_pick.substr(7)
		if not jobs.has(id):
			return
		if jobs[id]["done"]:
			_pick_device(id)
			return
		if not carrying.is_empty():
			_toast(T("Pousa primeiro o que tens nas mãos."), true)
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
		d.spawn_part(part, _spot(id)["part"])
		_toast(T("Tiraste do stock: %s") % T(Data.PARTS[part]["name"]), false, GREEN)
	else:
		var coming := false
		for dl in deliveries:
			if dl["key"] == part:
				coming = true
		for pc in parcels:
			if pc["key"] == part:
				_toast(T("A peça está na receção (junto à porta): abre a encomenda."), true)
				return
		if coming:
			_toast(T("A peça vem a caminho. Volta quando chegar à receção."), true)
		else:
			_toast(T("Falta a peça: %s. Compra-a na Loja (L).") % T(Data.PARTS[part]["name"]), true)


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
		_toast(T("Precisas de: %s") % need, true)
		_flash_needed_slot(allowed)
		return
	if stamina <= 0.5:
		_toast(T("Estás exausto! Bebe um café ou vai dormir no quarto das traseiras."), true)
		return
	stamina = maxf(0.0, stamina - 1.0)
	var target := hovered_target
	d.set_hover("")
	var dur := _perform(id, str(step["act"]), target) / DeviceBase.anim_speed
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
			parts.append(T("%s (%d)") % [T(Tools.NAMES[a]), Tools.IDS.find(a) + 1])
		return T(" ou ").join(parts)
	if str(allowed) == "none":
		return T("mão livre (Q)")
	return T("%s (tecla %d)") % [T(Tools.NAMES[str(allowed)]), Tools.IDS.find(str(allowed)) + 1]


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
	_act_sound(act)
	match act:
		"open_lid":
			d.set_lid(112, 0.9)
			return 0.9
		"power_dead":
			d.press_power(false)
			d.show_dead_battery()
			_toast(T("Não liga... o ecrã pisca \"Bateria 0%\". Vamos medir."))
			return 1.2
		"power_hot":
			d.press_power(false)
			d.boot_then_fail(T("SOBREAQUECIMENTO\nTemperatura do CPU: 98 °C\nA desligar..."), Color("ff6b5b"))
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.6).timeout.connect(func() -> void:
				_toast(T("Arranca e desliga-se a ferver. Avaria: SOBREAQUECIMENTO"), false, GREEN))
			return 2.0
		"power_nodisk":
			d.press_power(false)
			d.boot_then_fail(T("Nenhum dispositivo de arranque encontrado.\nInsira um disco e reinicie."), Color("e8eef4"))
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.6).timeout.connect(func() -> void:
				_toast(T("O sistema não encontra o disco. Avaria: SSD"), false, GREEN))
			return 2.0
		"power_lowbat":
			d.press_button_only()
			d.show_message(T("Bateria 1%\nA desligar..."), Color("ff6b5b"), 1.8)
			_toast(T("Liga e desliga-se logo... e o ecrã está levantado de um lado."))
			return 1.2
		"power_nocharge":
			d.press_button_only()
			d.show_message(T("Bateria fraca\nLigue o carregador"), Color("ffcf6b"), 1.8)
			_toast(T("Sem bateria, e o cabo não carrega. Vamos medir a porta."))
			return 1.2
		"measure":
			var digits: Label3D = bench_tools["multimeter"].get_node("Body/Digits")
			var reading := str(step.get("reading", "0.00"))
			meter_panel.show()
			var tw := create_tween()
			for v in ["12.6", "4.18", "0.71", reading]:
				tw.tween_callback(func() -> void:
					digits.text = v
					meter_label.text = v + T(" V"))
				tw.tween_interval(0.25)
			tw.tween_interval(2.5)
			tw.tween_callback(meter_panel.hide)
			jobs[id]["diagnosed"] = true
			var result := T(str(step.get("result", "")))
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
			d.remove_cover(_spot(id)["cover"] + (Vector3(0, -0.0056, 0) if id == "laptop" else Vector3.ZERO))
			return 1.2
		"replace_cover":
			d.replace_cover()
			return 1.05
		"clean_fan":
			_dust_puff(d.targets["fan"].global_position)
			if d.clean_fan():
				_toast(T("Ventoinha limpa!"), false, GREEN)
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
				_toast(T("Funciona perfeitamente! Reparação concluída."), false, GREEN))
			return 1.6
		"power_glitch":
			d.press_power("glitch")
			_toast(T("O ecrã pisca com riscos... parece danificado."))
			return 1.0
		"wipe":
			if not d.has_method("wipe"):
				return 0.55
			if d.wipe():
				jobs[id]["diagnosed"] = true
				_toast(T("Vidro e painel rachados. Avaria: ECRÃ PARTIDO"), false, GREEN)
			return 0.55
		"open_screen":
			d.open_screen()
			return 1.1
		"remove_screen":
			d.remove_old_screen(_spot(id)["cover"])
			return 1.25
		"install_screen":
			d.install_new_screen()
			return 1.0
		"close_screen":
			d.close_screen()
			return 0.95
		"blow_port":
			_dust_puff(d.targets[target].global_position)
			return 0.6
		"pad_on":
			d.set_led(true)
			_toast(T("Liga. Vamos ver o que se passa."))
			return 0.6
		"pad_drift":
			d.wiggle_stick(true)
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				_toast(T("O analógico não volta ao centro. Avaria: DRIFT"), false, GREEN))
			return 0.9
		"pad_test":
			d.wiggle_stick(false)
			d.set_led(true)
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				_toast(T("Analógico perfeito, sem drift! Reparação concluída."), false, GREEN))
			return 1.0
		"pad_stuck":
			d.press_a(true)
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(0.8).timeout.connect(func() -> void:
				_toast(T("O botão fica preso — sujidade pegajosa. Avaria: BOTÕES"), false, GREEN))
			return 1.3
		"clean_buttons":
			_dust_puff(d.targets["buttons"].global_position)
			d.clean_buttons()
			return 0.6
		"pad_ok":
			d.press_a(false)
			d.set_led(true)
			get_tree().create_timer(0.4).timeout.connect(func() -> void:
				_toast(T("Os botões estão como novos! Reparação concluída."), false, GREEN))
			return 0.8
		"clean":
			if d.dust:
				_dust_puff(d.dust.global_position)
			if d.clean():
				_toast(T("Está limpo!"), false, GREEN)
			return 0.65
		"power_flash_off":
			d.power(false)
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				_toast(T("Liga e desliga-se logo, a ferver e cheia de pó. Avaria: SOBREAQUECIMENTO"), false, GREEN))
			return 1.4
		"power_drive":
			d.power(true)
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				d.set_led(false)
				_toast(T("Liga, mas o leitor só faz cliques. Avaria: LEITOR DE DISCOS"), false, GREEN))
			return 1.4
		"power_none":
			_toast(T("Nada... nem uma luz. Vamos medir a porta."))
			return 0.8
		"power_ok", "power_ok_quiet":
			d.power(true)
			if d.screen_label:
				d.show_message(T("FX POCKET\nPronto a jogar!"), Color("8fd8ff"), 2.5)
			if act == "power_ok":
				get_tree().create_timer(0.8).timeout.connect(func() -> void:
					_toast(T("Funciona perfeitamente! Reparação concluída."), false, GREEN))
			return 1.2
		"buttons_stuck":
			jobs[id]["diagnosed"] = true
			_toast(T("Os botões rangem e ficam presos — areia. Avaria: BOTÕES"), false, GREEN)
			return 0.8
		"buttons_ok":
			_toast(T("Os botões estão como novos! Reparação concluída."), false, GREEN)
			return 0.8
		"ring_fail":
			d.ring(false)
			_toast(T("Há sinal de linha, mas a campainha não dá um pio."))
			return 1.0
		"dial_ok_diag":
			d.spin_dial()
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				_toast(T("O disco marca bem. O problema é a campainha. Avaria: CAMPAINHA"), false, GREEN))
			return 1.4
		"ring_ok":
			d.ring(true)
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				_sfx("bell")
				_toast(T("Trrrim! Toca como antigamente. Reparação concluída."), false, GREEN))
			return 1.2
		"hook_tone":
			d.ring(false)
			_toast(T("Há sinal de linha."))
			return 0.8
		"dial_stuck":
			jobs[id]["diagnosed"] = true
			_toast(T("O disco encrava a meio — pó e gordura velha. Avaria: DISCO PRESO"), false, GREEN)
			return 0.8
		"dial_ok":
			d.spin_dial()
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				_toast(T("O disco gira suave e volta ao sítio. Reparação concluída."), false, GREEN))
			return 1.4
		"radio_dead":
			d.set_tubes(true, 2)
			_toast(T("A luz acende... mas não sai som."))
			return 1.0
		"tune_silent":
			d.tune()
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				_toast(T("Nem um chiado — uma das válvulas não acende. Avaria: VÁLVULA"), false, GREEN))
			return 1.2
		"radio_static":
			d.set_tubes(true)
			_toast(T("Liga, mas só se ouve chiado..."))
			return 1.0
		"tune_crackle":
			d.tune()
			jobs[id]["diagnosed"] = true
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				_toast(T("O chiado piora ao rodar — sintonia suja. Avaria: SINTONIA"), false, GREEN))
			return 1.2
		"radio_on":
			d.set_tubes(true)
			d.tune()
			get_tree().create_timer(0.8).timeout.connect(func() -> void:
				_toast(T("Música clara como cristal! Reparação concluída."), false, GREEN))
			return 1.2
	return 0.4


func _act_sound(act: String) -> void:
	match act:
		"unscrew", "screw_in":
			_sfx("screw")
		"remove_cover", "replace_cover", "remove_part", "install_part", "remove_screen", "install_screen", "open_lid", "open_screen", "close_screen", "open_case":
			_sfx("part", 0.7)
		"clean_fan", "clean_buttons", "clean":
			_sfx("spray" if tool == "air" else ("wipe" if tool == "cloth" else "brush"))
		"blow_port":
			_sfx("spray")
		"wipe":
			_sfx("wipe")
		"measure":
			_sfx("beep")
		"power_on", "pad_ok", "pad_test", "test_ok", "power_ok", "power_ok_quiet", "radio_on", "dial_ok", "buttons_ok":
			get_tree().create_timer(0.3).timeout.connect(func() -> void: _sfx("power_on"))
		"power_dead", "power_hot", "power_nodisk", "power_lowbat", "power_nocharge", "power_glitch", "pad_drift", "pad_stuck", "test_fail", "power_flash_off", "power_drive", "power_none", "ring_fail", "radio_dead", "radio_static", "tune_silent", "tune_crackle", "dial_stuck", "buttons_stuck":
			get_tree().create_timer(0.5).timeout.connect(func() -> void: _sfx("power_fail", 0.7))
		_:
			_sfx("click", 0.6)


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
	if id != "none" and not carrying.is_empty():
		_toast(T("Pousa primeiro o que tens nas mãos."), true)
		return
	if id != tool:
		_sfx("pickup", 0.7)
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
		_toast(T("%s na mão.") % T(Tools.NAMES[id]))


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
		_toast(T("Subiste para o nível %d!") % level, false, YELLOW)
		_sfx("levelup")


func _spend(amount: float, what: String) -> void:
	money -= amount
	day_profit -= amount
	_toast(T("-%s  %s") % [_eur(amount), what])


func _abs_minutes() -> float:
	return float(day - 1) * 1440.0 + minutes


func _clock_text(abs_min: float) -> String:
	var d := int(abs_min / 1440.0) + 1
	var m := int(fmod(abs_min, 1440.0))
	var t := "%02d:%02d" % [m / 60, m % 60]
	return t if d == day else T("Dia %d, %s") % [d, t]


func _reputation() -> float:
	if ratings.is_empty():
		return 5.0
	var total := 0.0
	for r in ratings:
		total += float(r)
	return total / ratings.size()


## Creates a customer order (random, or a story order) and sends the customer in.
func _new_order(silent := false, story_key := "") -> Dictionary:
	var fk := ""
	var cust_name := ""
	var cust_color := Color.WHITE
	var complaint := ""
	var pay := 0.0
	var vip := false
	if story_key != "":
		var so: Dictionary = Story.STORY_ORDERS[story_key]
		var ch: Dictionary = Story.CHARACTERS[str(so.get("char", story_key))]
		fk = so["fault"]
		cust_name = T(str(ch["name"]))
		cust_color = ch["color"]
		complaint = I18n.pick(so["complaint"])
		pay = float(so["pay"])
	else:
		var keys: Array = []
		for k in FAULTS.keys():
			if FAULTS[k]["device"] == "gamepad" and not bool(story_flags.get("leo", false)):
				continue
			keys.append(k)
		fk = keys[randi() % keys.size()]
		var cust: Array = Data.CUSTOMERS[randi() % Data.CUSTOMERS.size()]
		cust_name = cust[0]
		cust_color = cust[1]
		var complaints: Array = FAULTS[fk]["complaints"]
		complaint = T(complaints[randi() % complaints.size()])
		var rep_bonus := 0.9 + 0.04 * _reputation()
		vip = _chapter_id() not in ["c1"] and randf() < 0.1
		pay = snappedf(float(FAULTS[fk]["pay"]) * randf_range(0.9, 1.2) * (1.8 if vip else 1.0) * rep_bonus * (1.15 if bool(story_flags.get("press", false)) else 1.0) * (1.1 if upgrades.has("display") else 1.0), 5.0)
	order_seq += 1
	var o := {
		"id": order_seq, "number": _next_order_number(), "customer": cust_name, "color": cust_color, "device": FAULTS[fk]["device"], "fault": fk,
		"complaint": complaint, "pay": pay, "story": story_key,
		"deadline": _abs_minutes() + randf_range(180, 330), "expires": _abs_minutes() + (9999.0 if story_key != "" else (230.0 if upgrades.has("coffee") else 170.0)), "status": "new",
	}
	if story_key != "":
		o["char"] = str(Story.STORY_ORDERS[story_key].get("char", story_key))
	if vip:
		o["vip"] = true
		o["deadline"] = _abs_minutes() + randf_range(100, 160)
	orders.append(o)
	_spawn_customer(o, "order")
	if not silent:
		if vip:
			_toast(T("Cliente VIP no balcão: %s paga a dobrar, mas tem pressa!") % o["customer"], false, YELLOW)
		else:
			_toast(T("Novo cliente no balcão: %s trouxe um %s.") % [o["customer"], _dev_name(o["device"]).to_lower()], false, YELLOW)
	_refresh_orders_badge()
	return o


func _next_order_number() -> int:
	order_number += 1
	return order_number


## Calm start: one job at a time in the first chapters, more as the story advances.
func _max_open_orders() -> int:
	var base := 4
	match _chapter_id():
		"c1", "c2":
			base = 2
		"c3", "c4":
			base = 3
	return base + expansion + _tech_count()


func _open_orders() -> int:
	return orders.size()


func _order_tick() -> void:
	var now := _abs_minutes()
	if now >= next_order_at:
		var pending := 0
		for o in orders:
			if o["status"] == "new":
				pending += 1
		if _open_orders() < _max_open_orders() and pending == 0 and minutes < 18 * 60:
			_new_order()
		var rate := clampf(_reputation() / 4.0, 0.7, 1.25) * (1.5 if bool(story_flags.get("press", false)) else 1.0) * (1.3 if upgrades.has("neon") else 1.0) * (1.0 + 0.3 * expansion + 0.12 * _tech_count())
		# irregular gaps: sometimes two people close together, sometimes a long quiet spell
		var gap := randf_range(25, 70) if randf() < 0.35 else randf_range(70, 150)
		next_order_at = now + gap / rate
	# unanswered requests walk out
	for o in orders.duplicate():
		if o["status"] == "new" and now > float(o["expires"]):
			orders.erase(o)
			_customer_leave(int(o["id"]), "sad")
			_toast(T("%s cansou-se de esperar e foi embora.") % o["customer"], true)
			_refresh_orders_badge()
	_story_tick()
	_delivery_tick()
	_staff_tick()
	_shopper_tick()


func _accept_order(o: Dictionary) -> void:
	if o["status"] != "new":
		return
	o["status"] = "accepted"
	_toast(T("Pedido de %s aceite.") % o["customer"], false, GREEN)
	var c: Node3D = customers.get(int(o["id"]))
	if c:
		c.hold(null)
		c.set_mood("happy")
	_customer_leave(int(o["id"]), "happy")
	_place_waiting_orders()
	_refresh_orders_panel()
	_refresh_objective()


func _decline_order(o: Dictionary) -> void:
	if str(o.get("story", "")) != "":
		_toast(T("Esta pessoa precisa mesmo de ti... aceita o pedido!"), true)
		return
	orders.erase(o)
	_customer_leave(int(o["id"]), "sad")
	_refresh_orders_panel()
	_refresh_orders_badge()


## Moves accepted orders onto free bench slots.
func _place_waiting_orders() -> void:
	if staff_first:
		_staff_assign_all()
	for o in orders:
		if o["status"] == "accepted" and not jobs.has(o["device"]) and _free_spot(str(o["device"])) != "":
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
	o["status"] = "done"
	_toast(T("Reparado! Pega no equipamento (E) e leva-o à prateleira «Prontos a entregar»."), false, GREEN)
	_exit_inspect_forced()
	_refresh_objective()


## Payment summary for a finished order (when the customer picks it up).
func _order_payment(o: Dictionary) -> Dictionary:
	var on_time := _abs_minutes() <= float(o["deadline"])
	var tip_mult := (1.1 if upgrades.has("coffee") else 1.0) * (1.1 if upgrades.has("speaker") else 1.0)
	var tip := snappedf(float(o["pay"]) * (randf_range(0.1, 0.25) if on_time else 0.0) * tip_mult, 1.0)
	var stars := 5 if on_time else 3
	if on_time and _abs_minutes() > float(o["deadline"]) - 30.0:
		stars = 4
	if o.has("quality"):
		stars = mini(stars, int(o["quality"]))
	if bool(o.get("flip", false)):
		tip = 0.0
		stars = 5
	return {"tip": tip, "stars": stars, "on_time": on_time}


## Picks the finished device up from the bench (frees the bench spot).
func _pick_device(id: String) -> void:
	if not carrying.is_empty():
		_toast(T("Já tens as mãos ocupadas."), true)
		return
	var o: Dictionary = jobs[id]["order"]
	var d: Node3D = devices[id]
	d.set_pickable(false)
	d.set_device_highlight(false)
	hovered_pick = ""
	devices.erase(id)
	jobs.erase(id)
	d.queue_free()
	o["status"] = "carried"
	_start_carry(o)
	_sfx("pickup")
	_toast(T("Leva-o à prateleira «Prontos a entregar» (junto à parede esquerda)."))
	_place_waiting_orders()
	_refresh_objective()


func _start_carry(o: Dictionary) -> void:
	carrying = {"order": o}
	if carry_node and is_instance_valid(carry_node):
		carry_node.queue_free()
	carry_node = Node3D.new()
	cam.add_child(carry_node)
	var st := _device_standin(str(o["device"]))
	carry_node.add_child(st)
	carry_node.position = Vector3(0.0, -0.17, -0.5)
	carry_node.rotation_degrees = Vector3(10, 0, 0)
	_equip("none")


func _end_carry() -> void:
	carrying = {}
	if carry_node and is_instance_valid(carry_node):
		carry_node.queue_free()
	carry_node = null


## Invisible colliders used when placing objects: floor (layer 8) and walls (layer 4).
func _build_place_colliders() -> void:
	var floor_b := Kit.static_body(self, Kit.box_shape(Vector3(7.4, 0.1, 4.6)), Vector3(-1.0, -0.05, 0.4))
	floor_b.collision_layer = 8
	var walls := [
		[Vector3(5.2, 2.8, 0.1), Vector3(0, 1.4, -1.8)],
		[Vector3(5.2, 2.8, 0.1), Vector3(0, 1.4, 2.65)],
		[Vector3(0.1, 2.8, 0.85), Vector3(2.65, 1.4, -1.35)],
		[Vector3(0.1, 2.8, 2.8), Vector3(2.65, 1.4, 1.25)],
		[Vector3(3.2, 2.8, 0.1), Vector3(4.25, 1.4, -1.8)],
		[Vector3(3.2, 2.8, 0.1), Vector3(4.25, 1.4, 1.55)],
		[Vector3(0.1, 2.8, 3.3), Vector3(5.85, 1.4, -0.12)],
		[Vector3(0.1, 2.8, 3.0), Vector3(-2.65, 1.4, 1.1)],
		[Vector3(0.1, 2.8, 0.6), Vector3(-2.65, 1.4, -1.45)],
		[Vector3(1.95, 2.8, 0.1), Vector3(-3.67, 1.4, -1.8)],
		[Vector3(1.95, 2.8, 0.1), Vector3(-3.67, 1.4, 0.65)],
		[Vector3(0.1, 2.8, 2.4), Vector3(-4.7, 1.4, -0.57)],
	]
	for w in walls:
		var b := Kit.static_body(self, Kit.box_shape(w[0]), w[1])
		b.collision_layer = 4
	var annex_floor := Kit.static_body(self, Kit.box_shape(Vector3(3.2, 0.1, 3.3)), Vector3(4.25, -0.05, -0.12))
	annex_floor.collision_layer = 8
	annex_door_body = Kit.static_body(self, Kit.box_shape(Vector3(0.1, 2.8, 0.8)), Vector3(2.65, 1.4, -0.55))
	annex_door_body.collision_layer = 4


func _build_shelf_targets() -> void:
	for b in shelf_bodies:
		if is_instance_valid(b):
			b.queue_free()
	shelf_bodies.clear()
	for i in range(shelf_items.size()):
		var b := Kit.static_body(self, Kit.box_shape(Vector3(0.42, 0.34, 0.38)), room.pickup_slots[i] + Vector3(0, 0.17, 0), "shelf:%d" % i)
		b.collision_layer = 1
		shelf_bodies.append(b)


func _shelf_place(i: int) -> void:
	var o: Dictionary = carrying["order"]
	_end_carry()
	_put_on_shelf(o, i)
	_toast(T("Pedido #%d pronto na prateleira. %s foi avisado.") % [int(o["number"]), o["customer"]], false, GREEN)


func _put_on_shelf(o: Dictionary, i: int) -> void:
	var node := _device_standin(str(o["device"]))
	add_child(node)
	node.global_position = room.pickup_slots[i] + Vector3(0, 0.04, 0)
	node.rotation_degrees = Vector3(0, 90, 0)
	var tag := Label3D.new()
	tag.text = "#%d  %s" % [int(o["number"]), str(o["customer"])]
	tag.font_size = 32
	tag.pixel_size = 0.0009
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 0.12, 0)
	tag.outline_size = 6
	node.add_child(tag)
	shelf_items[i] = {"order": o, "node": node}
	o["status"] = "shelf"
	o["shelf"] = i + 1
	_sfx("part", 0.7)
	if not customers.has(int(o["id"])):
		get_tree().create_timer(randf_range(3.0, 6.0)).timeout.connect(func() -> void:
			if o["status"] in ["shelf", "carried"]:
				_spawn_customer(o, "pickup")
				_refresh_objective())
	_refresh_objective()


func _shelf_take(i: int) -> void:
	var item: Dictionary = shelf_items[i]
	var o: Dictionary = item["order"]
	(item["node"] as Node3D).queue_free()
	shelf_items[i] = null
	o["status"] = "carried"
	_start_carry(o)
	_sfx("pickup")
	_refresh_objective()


## Customer received their device: stats now, money goes on the counter.
func _finish_order(o: Dictionary, tip: float, stars: int, auto_cash := false) -> void:
	var f: Dictionary = FAULTS[o["fault"]]
	var gain := float(o["pay"]) + tip
	repaired += 1
	story_deliveries += 1
	ratings.append(stars)
	if ratings.size() > 30:
		ratings.pop_front()
	_gain_xp(int(f["xp"]))
	orders.erase(o)
	_end_carry()
	var c: Node3D = customers.get(int(o["id"]))
	if c:
		c.hold(_device_standin(str(o["device"])))
		c.set_mood("happy")
	if gain > 0.0 and auto_cash:
		money += gain
		day_profit += gain
		room.ring_register(_eur(gain))
		_sfx("cash", 0.8)
		_goal_progress("earn", gain)
	elif gain > 0.0:
		_spawn_cash(gain, c.global_position if c else Vector3(0.6, 0, 2.0))
	_track_delivery(o, stars)
	_customer_leave(int(o["id"]), "happy")
	next_order_at = minf(next_order_at, _abs_minutes() + 12.0)
	_save_game()
	_story_check()
	_refresh_objective()


func _spawn_cash(amount: float, near: Vector3) -> void:
	var n := Node3D.new()
	add_child(n)
	var x := clampf(near.x, 0.1, 1.2)
	n.global_position = Vector3(x + cash_items.size() * 0.12, Room.COUNTER_TOP, Room.COUNTER_Z + 0.12)
	var note := Kit.fabric(Color("7fb77e"), 0.9, 0.3, 60.0)
	for i in range(int(clampf(amount / 25.0, 2, 8))):
		var b := Kit.box(n, Vector3(0.14, 0.0015, 0.07), note, Vector3(randf_range(-0.01, 0.01), 0.001 + i * 0.0016, randf_range(-0.01, 0.01)))
		b.rotation_degrees.y = randf_range(-12, 12)
	for i in range(3):
		Kit.cyl(n, 0.012, 0.003, Kit.chrome(Color("e6c56a")), Vector3(0.09 + i * 0.012, 0.0015 + i * 0.003, 0.03))
	var l := Label3D.new()
	l.text = _eur(amount)
	l.font_size = 40
	l.pixel_size = 0.001
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color("2ecc71")
	l.outline_size = 8
	l.position = Vector3(0, 0.07, 0)
	n.add_child(l)
	var body := Kit.static_body(n, Kit.box_shape(Vector3(0.2, 0.08, 0.14)), Vector3(0, 0.03, 0), "cash")
	body.collision_layer = 1
	var item := {"amount": amount, "node": n, "body": body}
	body.set_meta("cash", item)
	cash_items.append(item)
	_refresh_objective()
	_toast(T("O cliente deixou o dinheiro no balcão. Guarda-o na caixa (E)."), false, YELLOW)


func _collect_cash(item: Dictionary) -> void:
	cash_items.erase(item)
	var n: Node3D = item["node"]
	(item["body"] as StaticBody3D).collision_layer = 0
	money += float(item["amount"])
	day_profit += float(item["amount"])
	var t := create_tween()
	t.tween_property(n, "global_position", room.register.global_position + Vector3(0, 0.15, 0), 0.35)
	t.parallel().tween_property(n, "scale", Vector3(0.3, 0.3, 0.3), 0.35)
	t.tween_callback(n.queue_free)
	room.ring_register(_eur(float(item["amount"])))
	_sfx("cash")
	_toast(T("+%s na caixa registadora!") % _eur(float(item["amount"])), false, GREEN)
	_goal_progress("earn", float(item["amount"]))
	_save_game()
	_refresh_objective()


func _exit_inspect_forced() -> void:
	var d: Node3D = devices.get(active_device)
	if d:
		d.busy = false
	if mode == "popup":
		mode = "inspect"
	if mode == "inspect":
		_exit_inspect()


func _end_of_day() -> void:
	minutes = 20 * 60
	var finished_day := day
	var wages := _pay_wages()
	var goals_done := 0
	for g in daily_goals:
		if bool(g.get("done", false)):
			goals_done += 1
	var p := day_profit
	var lines := [
		[T("A oficina fecha às 20:00."), TEXT],
		[T("Resultado do dia:  %s") % _eur(p), GREEN if p >= 0 else Color("e74c3c")],
		[T("Equipamentos reparados (total):  %d") % repaired, MUTED],
		[T("Reputação:  %.1f ★") % _reputation(), YELLOW],
		[T("Metas do dia cumpridas:  %d/%d") % [goals_done, daily_goals.size()], Color("8fd8ff")],
	]
	if wages > 0.0:
		lines.insert(2, [T("Salários da equipa:  -%s") % _eur(wages), Color("ffb4a8")])
	stamina = maxf(stamina, 80.0)
	var rent_today := rent_due_day > 0 and finished_day >= rent_due_day
	if rent_today:
		lines.append([T("Renda a pagar hoje:  %s") % _eur(float(rent_amount)), Color("ffcf6b")])
	_open_popup(T("Fim do Dia %d") % finished_day, lines, [[T("Começar o Dia %d") % (finished_day + 1), func() -> void:
		_close_popup()
		if rent_today:
			_pay_rent()
		day = finished_day + 1
		minutes = 8 * 60
		day_profit = 0.0
		next_order_at = _abs_minutes() + 20.0
		for o in orders.duplicate():
			if o["status"] == "new":
				orders.erase(o)
				_customer_leave(int(o["id"]), "neutral", true)
		_new_day_refresh()
		_morning_orders()
		_refresh_orders_badge()
		_save_game()]], false)


func _morning_orders() -> void:
	var queued := story_flags.get("queue", []) as Array
	if not queued.is_empty():
		var key: String = queued.pop_front()
		story_flags["queue"] = queued
		_new_order(true, key)
	elif _open_orders() < _max_open_orders():
		_new_order(true)


# =============================================================================
# 3D customers at the counter
# =============================================================================
const DOOR_OUT := Vector3(2.0, 0.0, 3.4)
const DOOR_IN := Vector3(2.0, 0.0, 2.15)
const QUEUE_SPOTS := [Vector3(0.45, 0.0, 2.08), Vector3(1.05, 0.0, 2.2), Vector3(1.5, 0.0, 2.32), Vector3(0.95, 0.0, 2.45)]


func _spawn_customer(o: Dictionary, purpose: String, story_char := "") -> Node3D:
	var oid := int(o.get("id", -1))
	if customers.has(oid) and is_instance_valid(customers[oid]):
		return customers[oid]
	var c: Node3D = CustomerScene.new()
	var who := story_char if story_char != "" else str(o.get("char", o.get("story", "")))
	var look: Dictionary = {}
	if who != "" and Story.CHARACTERS.has(who):
		look = Story.CHARACTERS[who].get("look", {})
	c.setup(str(o["customer"]), hash(str(o["customer"])) + oid * 7, look)
	c.order_id = oid
	c.set_meta("purpose", purpose)
	c.set_meta("order", o)
	add_child(c)
	c.global_position = DOOR_OUT
	c.rotation.y = PI
	if purpose == "order" and o.has("device"):
		c.hold(_device_standin(str(o["device"])))
		c.set_mood("worried")
	customers[oid] = c
	counter_queue.append(oid)
	room.open_door()
	_sfx("door_chime", 0.7)
	c.walk_path([DOOR_IN, _queue_spot(counter_queue.size() - 1)], func() -> void:
		c.rotation.y = PI
		c.look_enabled = true
		c.set_bubble("ok" if purpose == "pickup" else "!"))
	return c


func _queue_spot(i: int) -> Vector3:
	return QUEUE_SPOTS[mini(i, QUEUE_SPOTS.size() - 1)]


func _customer_leave(oid: int, mood := "neutral", instant := false) -> void:
	var c: Node3D = customers.get(oid)
	counter_queue.erase(oid)
	customers.erase(oid)
	if c == null or not is_instance_valid(c):
		return
	if instant:
		c.queue_free()
		return
	c.set_bubble("")
	c.look_enabled = false
	c.set_mood(mood)
	c.pick.collision_layer = 0
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		c.walk_path([DOOR_IN, DOOR_OUT], func() -> void: c.queue_free())
		get_tree().create_timer(1.0).timeout.connect(room.open_door))
	_update_queue()


func _update_queue() -> void:
	for i in range(counter_queue.size()):
		var c: Node3D = customers.get(counter_queue[i])
		if c and is_instance_valid(c) and not c.walking:
			var spot := _queue_spot(i)
			if c.global_position.distance_to(spot) > 0.1:
				c.look_enabled = false
				c.walk_path([spot], func() -> void:
					c.rotation.y = PI
					c.look_enabled = true)


## Small stand-in of a device for customers to carry.
func _device_standin(device: String) -> Node3D:
	var n := Node3D.new()
	match device:
		"laptop":
			Kit.slab(n, Vector3(0.31, 0.018, 0.22), 0.011, 0.003, Kit.aluminium(Color("7a8189"), 0.34))
			n.rotation_degrees = Vector3(-10, 0, 0)
		"phone":
			Kit.slab(n, Vector3(0.072, 0.008, 0.148), 0.01, 0.002, Kit.black_glass(), Kit.aluminium(Color("4a5a6e"), 0.22))
			n.rotation_degrees = Vector3(-60, 0, 0)
			n.position = Vector3(0.08, 0.05, 0)
		"gamepad":
			Kit.slab(n, Vector3(0.12, 0.024, 0.068), 0.026, 0.008, Kit.plastic(Color("2a2e35"), 0.42))
			for sx in [-1.0, 1.0]:
				Kit.capsule(n, 0.021, 0.085, Kit.plastic(Color("2a2e35"), 0.42), Vector3(sx * 0.048, -0.004, 0.034), Vector3(62, 0, sx * -14.0))
			n.rotation_degrees = Vector3(-40, 0, 0)
		"console", "handheld", "rotary", "radio":
			var real: Node3D
			match device:
				"console":
					real = ConsoleDev.new()
				"handheld":
					real = HandheldDev.new()
				"rotary":
					real = RotaryDev.new()
				_:
					real = RadioDev.new()
			if real.surface_body:
				real.surface_body.collision_layer = 0
			real.set_process(false)
			n.add_child(real)
			if device == "handheld":
				n.rotation_degrees = Vector3(-50, 0, 0)
	return n


func _talk_to_customer(c: Node3D) -> void:
	var purpose := str(c.get_meta("purpose", "order"))
	var o: Dictionary = c.get_meta("order", {})
	room.ring_bell()
	_sfx("bell", 0.7)
	if purpose == "story":
		var scene := str(c.get_meta("scene", ""))
		c.set_bubble("talk")
		_play_scene(scene, func() -> void:
			var after: Callable = c.get_meta("after", Callable())
			_customer_leave(c.order_id, "happy")
			if after.is_valid():
				after.call())
		return
	if purpose == "browse":
		_open_dialog([[c.display_name, o.get("color", Color.WHITE), T("Estou só a ver o expositor, obrigado!")]], [[T("Esteja à vontade"), _close_dialog]])
		return
	if purpose == "buy":
		var pk := str(o.get("product", "charger"))
		_open_dialog([[c.display_name, o.get("color", Color.WHITE), T("Queria levar isto, se faz favor: %s.") % T(str(Data.PRODUCTS[pk]["name"])) + "\n\n" + T("Preço:  %s") % _eur(float(o["pay"]))]], [[T("Vender (%s)") % _eur(float(o["pay"])), func() -> void:
			_close_dialog()
			_sell_product(o, false)]])
		return
	if purpose == "pickup":
		var story_key := str(o.get("story", ""))
		var holding_it: bool = not carrying.is_empty() and carrying["order"] == o
		if not holding_it:
			var where := ""
			if o.get("status", "") == "shelf":
				where = "\n" + T("(Está na prateleira «Prontos a entregar», lugar #%d.)") % int(o.get("shelf", 0))
			var wrong := ""
			if not carrying.is_empty():
				wrong = T("Hmm, isso não é meu.") + " "
			var hello := T("Olá! Venho buscar o pedido #%d — %s.") % [int(o["number"]), _dev_name(str(o["device"]))]
			if bool(o.get("flip", false)):
				hello = T("Olá! Vi o anúncio do %s usado (#%d). Ainda está à venda?") % [_dev_name(str(o["device"])), int(o["number"])]
			_open_dialog([[str(o["customer"]), o["color"], wrong + hello + where]], [[T("Vou buscar!"), _close_dialog]])
			return
		var pay := _order_payment(o)
		var stars: int = pay["stars"]
		var tip: float = pay["tip"]
		var star_txt := "%s  (%d/5)" % ["★".repeat(stars), stars]
		var after_scene := ""
		if story_key != "":
			after_scene = Story.STORY_ORDERS[story_key]["deliver"]
		var text := T("Já está pronto? Que maravilha!") + "\n\n" + T("Pagamento:  %s") % _eur(float(o["pay"]))
		if bool(o.get("flip", false)):
			text = T("Está impecável! Fico com ele.") + "\n\n" + T("Preço de venda:  %s") % _eur(float(o["pay"]))
		if tip > 0:
			text += "     " + T("Gorjeta:  %s") % _eur(tip)
		text += "\n" + T("Avaliação:  %s") % star_txt
		_open_dialog([[str(o["customer"]), o["color"], text]], [[T("Entregar a %s") % o["customer"], func() -> void:
			_close_dialog()
			_finish_order(o, tip, stars)
			if after_scene != "":
				get_tree().create_timer(0.3).timeout.connect(func() -> void: _play_scene(after_scene, func() -> void: _story_after_delivery(story_key)))
		]])
		return
	# new order: complaint + accept / decline
	var text2 := "“%s”" % o["complaint"] + "\n\n" + T("Pagamento: %s   •   Prazo: %s") % [_eur(float(o["pay"])), _clock_text(float(o["deadline"]))]
	var accept_scene := ""
	if str(o.get("story", "")) != "":
		accept_scene = Story.STORY_ORDERS[str(o["story"])]["accept"]
	var show_order := func() -> void:
		_open_dialog([[str(o["customer"]) + "  •  " + _dev_name(str(o["device"])), o["color"], text2]], [
			[T("Aceitar"), func() -> void:
				_close_dialog()
				_accept_order(o)],
			[T("Recusar"), func() -> void:
				_close_dialog()
				_decline_order(o)],
		])
	if accept_scene != "" and not bool(o.get("intro_done", false)):
		o["intro_done"] = true
		_play_scene(accept_scene, show_order)
	else:
		show_order.call()


# =============================================================================
# Dialogue box
# =============================================================================
func _build_dialog(base: Control) -> void:
	dialog_root = Control.new()
	dialog_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog_root.mouse_filter = Control.MOUSE_FILTER_STOP
	base.add_child(dialog_root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.25)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_root.add_child(shade)
	var p := _panel(Color(0.035, 0.06, 0.1, 0.96), 16, Vector4(22, 18, 24, 18))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 1.0
	p.anchor_bottom = 1.0
	p.offset_left = -440
	p.offset_right = 440
	p.offset_top = -250
	p.offset_bottom = -30
	dialog_root.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)
	dialog_avatar = Control.new()
	dialog_avatar.custom_minimum_size = Vector2(84, 84)
	dialog_avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dialog_avatar.draw.connect(func() -> void:
		var col: Color = dialog_avatar.get_meta("color", Color.GRAY)
		dialog_avatar.draw_circle(Vector2(42, 42), 41, col)
		dialog_avatar.draw_arc(Vector2(42, 42), 41, 0, TAU, 48, Color(1, 1, 1, 0.5), 2.0, true)
		var nm := str(dialog_avatar.get_meta("initial", ""))
		dialog_avatar.draw_string(font_xbold, Vector2(0, 56), nm, HORIZONTAL_ALIGNMENT_CENTER, 84, 40, Color("10161d")))
	h.add_child(dialog_avatar)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	h.add_child(v)
	dialog_name = _label("", 22, YELLOW, font_xbold)
	v.add_child(dialog_name)
	dialog_text = _label("", 19, TEXT)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size = Vector2(700, 0)
	dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(dialog_text)
	dialog_buttons = HBoxContainer.new()
	dialog_buttons.add_theme_constant_override("separation", 10)
	dialog_buttons.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(dialog_buttons)
	dialog_root.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_dialog_advance())
	dialog_root.hide()


## lines: [[name, color, text], ...]; buttons (optional, shown on the last line): [[label, Callable], ...]
func _open_dialog(lines: Array, buttons: Array = [], on_done := Callable()) -> void:
	if mode != "dialog":
		dialog_prev_mode = mode if mode != "board" else "walk"
	mode = "dialog"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	prompt.hide()
	dialog_lines = lines.duplicate()
	dialog_btns = buttons
	dialog_done = on_done
	dialog_root.show()
	_dialog_show_line()


func _dialog_show_line() -> void:
	var ln: Array = dialog_lines[0]
	dialog_name.text = str(ln[0])
	dialog_avatar.set_meta("color", ln[1])
	dialog_avatar.set_meta("initial", str(ln[0]).replace("Sr. ", "").replace("Dona ", "").replace("Avô ", "").replace("Grandpa ", "").left(1))
	dialog_avatar.queue_redraw()
	dialog_text.text = str(ln[2])
	dialog_text.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(dialog_text, "visible_ratio", 1.0, clampf(str(ln[2]).length() * 0.012, 0.25, 1.6))
	for c in dialog_buttons.get_children():
		dialog_buttons.remove_child(c)
		c.queue_free()
	if dialog_lines.size() == 1 and not dialog_btns.is_empty():
		for b in dialog_btns:
			var btn := _small_button(str(b[0]), dialog_buttons.get_child_count() == 0)
			btn.custom_minimum_size = Vector2(150, 40)
			btn.pressed.connect(b[1])
			dialog_buttons.add_child(btn)
	else:
		dialog_buttons.add_child(_label(T("E / clique para continuar"), 14, MUTED))


func _dialog_advance() -> void:
	if dialog_text.visible_ratio < 1.0:
		dialog_text.visible_ratio = 1.0
		return
	if dialog_lines.size() == 1 and not dialog_btns.is_empty():
		return
	dialog_lines.pop_front()
	if dialog_lines.is_empty():
		var cb := dialog_done
		_close_dialog()
		if cb.is_valid():
			cb.call()
	else:
		_dialog_show_line()


func _close_dialog() -> void:
	dialog_root.hide()
	if mode == "dialog":
		mode = dialog_prev_mode if dialog_prev_mode in ["walk", "inspect"] else "walk"
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mode == "walk" else Input.MOUSE_MODE_HIDDEN
	_refresh_objective()


func _play_scene(key: String, on_done := Callable()) -> void:
	if not Story.SCENES.has(key):
		if on_done.is_valid():
			on_done.call()
		return
	var lines: Array = []
	for ln in Story.SCENES[key]:
		var ch: Dictionary = Story.CHARACTERS[ln[0]]
		lines.append([T(str(ch["name"])), ch["color"], I18n.pick(ln[1])])
	_open_dialog(lines, [], on_done)


# =============================================================================
# Story progression
# =============================================================================
func _chapter() -> Dictionary:
	return Story.CHAPTERS[clampi(story_chapter, 0, Story.CHAPTERS.size() - 1)]


func _chapter_id() -> String:
	return str(_chapter()["id"])


func _set_chapter(i: int) -> void:
	story_chapter = i
	story_deliveries = 0
	var ch := _chapter()
	_toast(I18n.pick(ch["title"]), false, YELLOW)
	if _chapter_id() == "c2":
		rent_due_day = maxi(Story.RENT_DAY, day)
	_refresh_objective()
	_save_game()


## A story character walks in to talk (no device).
func _story_visit(who: String, scene: String, after := Callable()) -> void:
	order_seq += 1
	var ch: Dictionary = Story.CHARACTERS[who]
	var o := {"id": order_seq, "customer": T(str(ch["name"])), "color": ch["color"]}
	var c := _spawn_customer(o, "story", who)
	c.set_meta("scene", scene)
	c.set_meta("after", after)
	_toast(T("%s está no balcão e quer falar contigo.") % T(str(ch["name"])), false, YELLOW)


func _story_begin() -> void:
	_play_scene("intro", func() -> void:
		_story_visit("armando", "armando_arrives", func() -> void:
			_set_chapter(0)
			_new_order(false, "rosa")))


func _story_tick() -> void:
	if mode != "walk" or bool(story_flags.get("busy", false)):
		return
	match _chapter_id():
		"c6":
			if not staff.is_empty() and not bool(story_flags.get("c6_done", false)):
				story_flags["c6_done"] = true
				_story_visit("rosa", "c6_done", func() -> void:
					_set_chapter(6)
					_new_order(false, "rosa_radio"))
		"c8":
			if money >= float(Story.BUILDING_PRICE) and not bool(story_flags.get("bought", false)):
				story_flags["bought"] = true
				_story_visit("armando", "armando_sell", func() -> void:
					money -= float(Story.BUILDING_PRICE)
					day_profit -= float(Story.BUILDING_PRICE)
					rent_amount = 0
					rent_due_day = 0
					_toast(T("O prédio é teu! Já não pagas renda."), false, GREEN)
					_set_chapter(8))


## Called after every delivery.
func _story_check() -> void:
	match _chapter_id():
		"c1":
			if story_deliveries >= 2:
				get_tree().create_timer(1.5).timeout.connect(func() -> void:
					_play_scene("c1_done", func() -> void: _set_chapter(1)))
		"c5":
			if story_deliveries >= Story.C5_DELIVERIES and _reputation() >= 4.3 and not bool(story_flags.get("c5_done", false)):
				story_flags["c5_done"] = true
				get_tree().create_timer(1.5).timeout.connect(func() -> void:
					_story_visit("marta", "c5_done", func() -> void: _set_chapter(5)))
		"c9":
			if int(story_flags.get("fair_day", -1)) != day:
				story_flags["fair_day"] = day
				story_flags["fair_count"] = 0
			story_flags["fair_count"] = int(story_flags.get("fair_count", 0)) + 1
			if int(story_flags["fair_count"]) >= Story.FAIR_TARGET and not bool(story_flags.get("fair_won", false)):
				story_flags["fair_won"] = true
				get_tree().create_timer(1.5).timeout.connect(func() -> void:
					_story_visit("marta", "fair_win", func() -> void:
						_set_chapter(9)
						_new_order(false, "vitor")))
		"c3":
			if story_deliveries >= 6 and _reputation() >= 4.5 and not bool(story_flags.get("press", false)):
				story_flags["press"] = true
				get_tree().create_timer(1.5).timeout.connect(func() -> void:
					_story_visit("marta", "marta_arrives", func() -> void:
						_set_chapter(3)
						var q: Array = story_flags.get("queue", [])
						q.append("armando")
						story_flags["queue"] = q))


func _story_after_delivery(key: String) -> void:
	match key:
		"leo":
			story_flags["leo"] = true
		"armando":
			rent_amount = int(Story.RENT / 2)
			_set_chapter(4)
			_toast(T("Renda reduzida para %s a cada 3 dias.") % _eur(float(rent_amount)), false, YELLOW)
			get_tree().create_timer(4.0).timeout.connect(func() -> void:
				_story_visit("vitor", "vitor_arrives", func() -> void: _new_order(false, "spy")))
		"rosa_radio":
			_set_chapter(7)
		"vitor":
			_set_chapter(10)
			_stat_set("story_end", 1)
			_open_popup(T("Fim da história"), [
				[T("Obrigado por jogares a história da oficina do Avô Júlio!"), TEXT],
				[T("A oficina é tua, a MegaFix é tua parceira e a vila adora-te."), MUTED],
				[T("Continua a crescer: contrata, expande e revende. A oficina nunca fecha."), YELLOW],
			], [[T("Continuar a jogar"), _close_popup]], true)


func _pay_rent() -> void:
	var first := not bool(story_flags.get("rent_paid_once", false))
	var amount := float(rent_amount)
	if money >= amount:
		money -= amount
		day_profit -= amount
		if first:
			story_flags["rent_paid_once"] = true
			_play_scene("rent_paid", func() -> void: _after_first_rent())
		else:
			_toast(T("Renda paga: -%s") % _eur(amount), false, MUTED)
	else:
		var paid := maxf(0.0, money)
		money -= paid
		if first:
			story_flags["rent_paid_once"] = true
			_play_scene("rent_short", func() -> void: _after_first_rent())
		else:
			_toast(T("Não chegou para a renda toda (pagaste %s).") % _eur(paid), true)
	rent_due_day = day + 3


func _after_first_rent() -> void:
	if _chapter_id() == "c2":
		_set_chapter(2)
		var q: Array = story_flags.get("queue", [])
		q.append("leo")
		story_flags["queue"] = q


func _chapter_goal_text() -> String:
	var ch := _chapter()
	var g := I18n.pick(ch["goal"])
	match str(ch["id"]):
		"c1":
			g += "  (%d/2)" % mini(story_deliveries, 2)
		"c2":
			g += "  (%s / %s)" % [_eur(money), _eur(float(Story.RENT))]
		"c3":
			g += "  (%d/6, ★%.1f)" % [mini(story_deliveries, 6), _reputation()]
		"c5":
			g += "  (%d/%d, ★%.1f)" % [mini(story_deliveries, Story.C5_DELIVERIES), Story.C5_DELIVERIES, _reputation()]
		"c6":
			g += "  (%d/1)" % mini(staff.size(), 1)
		"c8":
			g += "  (%s / %s)" % [_eur(money), _eur(float(Story.BUILDING_PRICE))]
		"c9":
			g += "  (%d/%d)" % [int(story_flags.get("fair_count", 0)) if int(story_flags.get("fair_day", -1)) == day else 0, Story.FAIR_TARGET]
	return g


# =============================================================================
# Save / settings
# =============================================================================
func _save_game() -> void:
	var f := FileAccess.open(SAVE_PATH % current_slot, FileAccess.WRITE)
	if f == null:
		return
	var pending_cash := 0.0
	for c in cash_items:
		pending_cash += float(c["amount"])
	var inv_save := inventory.duplicate()
	var retail_save := retail_stock.duplicate()
	var pending_keys: Array = []
	for d in deliveries:
		pending_keys.append(str(d["key"]))
	pending_keys.append_array(postman_keys)
	for pc in parcels:
		pending_keys.append(str(pc["key"]))
	for pk in pending_keys:
		if pk.begins_with("prod:"):
			retail_save[pk.substr(5)] = int(retail_save.get(pk.substr(5), 0)) + Data.PACK
		else:
			inv_save[pk] = int(inv_save.get(pk, 0)) + 1
	var stand_save: Array = []
	for it in stand_items:
		stand_save.append([it["key"], it["qty"]] if it != null else null)
	f.store_string(JSON.stringify({"day": day, "minutes": minutes, "money": money + pending_cash, "xp": xp, "level": level, "repaired": repaired, "ratings": ratings, "inventory": inv_save,
		"story_chapter": story_chapter, "story_deliveries": story_deliveries, "story_flags": story_flags, "rent_due_day": rent_due_day, "rent_amount": rent_amount, "upgrades": upgrades, "stamina": stamina, "hunger": hunger, "decor": _decor_save(), "tools_pos": _tools_save(),
		"expansion": expansion, "staff": _staff_save(), "staff_seq": staff_seq, "staff_first": staff_first, "candidates": candidates, "flip_offers": flip_offers,
		"daily_goals": daily_goals, "stats": stats, "achievements": achievements, "retail": retail_save, "stand": stand_save, "upgrades_pos": _upgrades_pos_save()}))


func _has_save() -> bool:
	for i in range(1, 4):
		if FileAccess.file_exists(SAVE_PATH % i):
			return true
	return false


func _slot_exists(i: int) -> bool:
	return FileAccess.file_exists(SAVE_PATH % i)


func _slot_info(i: int) -> Dictionary:
	if not _slot_exists(i):
		return {}
	var f := FileAccess.open(SAVE_PATH % i, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


## One-time migration of the single save file from older versions into slot 1.
func _migrate_old_save() -> void:
	if FileAccess.file_exists(OLD_SAVE_PATH) and not _slot_exists(1):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(OLD_SAVE_PATH), ProjectSettings.globalize_path(SAVE_PATH % 1))


func _load_game() -> bool:
	if not _slot_exists(current_slot):
		return false
	var f := FileAccess.open(SAVE_PATH % current_slot, FileAccess.READ)
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
	story_chapter = int(data.get("story_chapter", 0))
	story_deliveries = int(data.get("story_deliveries", 0))
	story_flags = data.get("story_flags", {})
	rent_due_day = int(data.get("rent_due_day", 0))
	rent_amount = int(data.get("rent_amount", Story.RENT))
	_clear_decor()
	for de in data.get("decor", []):
		if de is Dictionary and Room.DECOR.has(str(de.get("id", ""))):
			var a: Array = de.get("xf", [])
			if a.size() == 12:
				_spawn_decor(str(de["id"]), Transform3D(Basis(Vector3(a[0], a[1], a[2]), Vector3(a[3], a[4], a[5]), Vector3(a[6], a[7], a[8])), Vector3(a[9], a[10], a[11])))
	var tp = data.get("tools_pos", {})
	if tp is Dictionary:
		for tid in tp.keys():
			var a2: Array = tp[tid]
			if bench_tools.has(tid) and a2.size() == 12:
				var node: Node3D = bench_tools[tid]
				node.global_transform = Transform3D(Basis(Vector3(a2[0], a2[1], a2[2]), Vector3(a2[3], a2[4], a2[5]), Vector3(a2[6], a2[7], a2[8])), Vector3(a2[9], a2[10], a2[11]))
				var pk: Node3D = node.get_meta("pick")
				pk.global_position = Vector3(a2[9], 0.95, a2[11])
	stamina = float(data.get("stamina", 100.0))
	hunger = float(data.get("hunger", 100.0))
	staff_seq = int(data.get("staff_seq", 0))
	staff_first = bool(data.get("staff_first", true))
	stats = data.get("stats", {}) if data.get("stats", {}) is Dictionary else {}
	achievements = data.get("achievements", {}) if data.get("achievements", {}) is Dictionary else {}
	daily_goals = data.get("daily_goals", []) if data.get("daily_goals", []) is Array else []
	candidates = data.get("candidates", []) if data.get("candidates", []) is Array else []
	flip_offers = data.get("flip_offers", []) if data.get("flip_offers", []) is Array else []
	_set_expansion(int(data.get("expansion", 0)))
	_staff_load(data.get("staff", []))
	retail_stock = {}
	var rs = data.get("retail", {})
	if rs is Dictionary:
		for k in rs.keys():
			if Data.PRODUCTS.has(k):
				retail_stock[k] = int(rs[k])
	_stand_clear()
	var ss = data.get("stand", [])
	if ss is Array:
		for i in range(mini(ss.size(), stand_items.size())):
			if ss[i] is Array and Data.PRODUCTS.has(str(ss[i][0])):
				_stand_set(i, str(ss[i][0]), int(ss[i][1]))
	if daily_goals.is_empty() or candidates.is_empty() or flip_offers.is_empty():
		_new_day_refresh()
	upgrades = {}
	var up = data.get("upgrades", {})
	if up is Dictionary:
		for k in up.keys():
			upgrades[k] = true
	room.clear_upgrades()
	_apply_upgrades()
	var upos = data.get("upgrades_pos", {})
	if upos is Dictionary:
		for uid in upos.keys():
			var a3: Array = upos[uid]
			if room.upgrade_nodes.has(uid) and a3.size() == 12:
				(room.upgrade_nodes[uid] as Node3D).global_transform = Transform3D(Basis(Vector3(a3[0], a3[1], a3[2]), Vector3(a3[3], a3[4], a3[5]), Vector3(a3[6], a3[7], a3[8])), Vector3(a3[9], a3[10], a3[11]))
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
		settings["lang"] = str(cfg.get_value("ui", "lang", "pt"))
		settings["music"] = float(cfg.get_value("audio", "music", 0.6))
		settings["sfx"] = float(cfg.get_value("audio", "sfx", 0.8))
	I18n.lang = str(settings.get("lang", "pt"))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", settings["quality"])
	cfg.set_value("video", "fullscreen", settings["fullscreen"])
	cfg.set_value("input", "sensitivity", settings["sensitivity"])
	cfg.set_value("ui", "lang", settings.get("lang", "pt"))
	cfg.set_value("audio", "music", settings.get("music", 0.6))
	cfg.set_value("audio", "sfx", settings.get("sfx", 0.8))
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
	theme_main.set_color("font_color", T("Label"), TEXT)


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
	_build_dialog(base)
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
	var needs := _panel(PANEL_BG, 10, Vector4(12, 6, 14, 6))
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 3)
	needs.add_child(nv)
	for nd in [["bolt", Color("f5d142")], ["food", Color("ff8a5c")]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(_icon(nd[0], 14, nd[1]))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(90, 7)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bgs := StyleBoxFlat.new()
		bgs.bg_color = Color(1, 1, 1, 0.12)
		bgs.set_corner_radius_all(3)
		var fgs := StyleBoxFlat.new()
		fgs.bg_color = nd[1]
		fgs.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", bgs)
		bar.add_theme_stylebox_override("fill", fgs)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
		nv.add_child(row)
		if nd[0] == "bolt":
			energy_bar = bar
		else:
			hunger_bar = bar
	tl.add_child(needs)

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
	xp_label = _label(T("0 / 100 XP"), 14, TEXT)
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
	objective_title = _label(T("Objetivo Atual"), 19, YELLOW, font_xbold)
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
	repair_title = _label(T("Reparação: Portátil"), 19, YELLOW, font_xbold)
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
	prompt_label = _label(T("Interagir"), 17, TEXT)
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
	var sc := VBoxContainer.new()
	sc.anchor_top = 1.0
	sc.anchor_bottom = 1.0
	sc.offset_left = 22
	sc.offset_top = -108
	sc.offset_bottom = -22
	sc.add_theme_constant_override("separation", 6)
	sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(sc)
	var sc_rows := [HBoxContainer.new(), HBoxContainer.new()]
	for r in sc_rows:
		r.add_theme_constant_override("separation", 8)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sc.add_child(r)
	for it in [["F", "Equipa"], ["M", "Metas"], ["P", "Pedidos"], ["L", "Loja"], ["U", "Melhorias"]]:
		var pp := _panel(Color(0.04, 0.07, 0.11, 0.88), 10, Vector4(10, 6, 14, 6))
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 8)
		pp.add_child(hh)
		hh.add_child(_keycap(it[0]))
		hh.add_child(_label(T(it[1]), 17))
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
			bp.visible = false
		(sc_rows[0] if it[0] in ["F", "M"] else sc_rows[1]).add_child(pp)
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
	mv.add_child(_label(T("MULTÍMETRO  •  V DC"), 13, Color("f2c218"), font_xbold))
	var lcd := PanelContainer.new()
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color("9fb39a")
	lsb.set_corner_radius_all(6)
	lsb.content_margin_left = 12
	lsb.content_margin_right = 12
	lcd.add_theme_stylebox_override("panel", lsb)
	meter_label = _label(T("0.00 V"), 44, Color("1b231b"), font_xbold)
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
	day_label.text = T("Dia %d") % day
	var m := int(minutes)
	time_label.text = "%02d:%02d" % [m / 60, m % 60]
	money_label.text = _eur(money)
	level_label.text = str(level)
	xp_label.text = T("%d / 100 XP") % xp
	xp_bar.value = xp
	if energy_bar:
		energy_bar.value = stamina
		hunger_bar.value = hunger


func _eur(v: float) -> String:
	var neg := v < 0
	var cents := int(round(absf(v) * 100.0))
	var s := "%d,%02d" % [cents / 100, cents % 100]
	return ("-€ " if neg else "€ ") + s


func _toast(text: String, warn := false, color := TEXT) -> void:
	_sfx("blip_bad" if warn else "pop", 0.6)
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
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(225, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return wrap


func _refresh_objective() -> void:
	if objective_rows == null:
		return
	for c in objective_rows.get_children():
		c.queue_free()
	# story chapter + goal
	var ch_title := _label(I18n.pick(_chapter()["title"]), 14, Color("8fd8ff"), font_xbold)
	objective_rows.add_child(ch_title)
	var goal := _label("➜ " + _chapter_goal_text(), 14, TEXT)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.custom_minimum_size = Vector2(250, 0)
	objective_rows.add_child(goal)
	if not daily_goals.is_empty():
		var gd := 0
		for g in daily_goals:
			if bool(g.get("done", false)):
				gd += 1
		objective_rows.add_child(_label(T("Metas do dia: %d/%d  (M)") % [gd, daily_goals.size()], 13, YELLOW))
	objective_rows.add_child(HSeparator.new())
	var base_rows := objective_rows.get_child_count()
	# delivery chores always shown first
	if not carrying.is_empty():
		objective_rows.add_child(_row(T("Leva o pedido #%d à prateleira «Prontos a entregar» ou ao cliente") % int(carrying["order"].get("number", 0)), "active"))
	for o in orders:
		if o.get("status", "") == "shelf" and customers.has(int(o["id"])):
			objective_rows.add_child(_row(T("Entrega o pedido #%d a %s") % [int(o["number"]), o["customer"]], "active"))
		elif o.get("status", "") == "shelf":
			objective_rows.add_child(_row(T("À espera que %s venha buscar o pedido #%d") % [o["customer"], int(o["number"])], "todo"))
	if not cash_items.is_empty():
		objective_rows.add_child(_row(T("Guarda o dinheiro do balcão na caixa registadora"), "active"))
	if not parcels.is_empty():
		objective_rows.add_child(_row(T("Abre a encomenda na receção (junto à porta)"), "active"))
	for id in jobs.keys():
		if jobs[id]["done"]:
			objective_rows.add_child(_row(T("Pega no %s reparado e leva-o à prateleira") % _dev_name(id).to_lower(), "active"))
	var chores := objective_rows.get_child_count() > base_rows
	if not jobs.has(focus_job) or jobs[focus_job]["done"]:
		focus_job = ""
		for id in jobs.keys():
			if not jobs[id]["done"]:
				focus_job = id
				break
	if focus_job == "" and chores:
		objective_title.text = T("Objetivo Atual")
		return
	if focus_job == "":
		objective_title.text = T("Objetivo Atual")
		var waiting := 0
		for o in orders:
			if o["status"] == "new":
				waiting += 1
		objective_rows.add_child(_row(T("Não há trabalho na bancada"), "done"))
		objective_rows.add_child(_row(T("Abre os Pedidos (P) e aceita um cliente"), "active"))
		if waiting > 0:
			objective_rows.add_child(_label(T("%d cliente(s) à espera de resposta") % waiting, 13, YELLOW))
		return
	var id := focus_job
	var j: Dictionary = jobs[id]
	var o: Dictionary = j["order"]
	objective_title.text = T("%s de %s") % [_dev_name(id), o["customer"]]
	var s: int = j["step"]
	var steps: Array = _fault(id)["steps"]
	var items := [
		[T("Examinar o %s") % _dev_name(id).to_lower(), s >= 1],
		[T("Diagnosticar a avaria"), bool(j["diagnosed"])],
		[T("Reparar o equipamento"), s >= steps.size() - 1],
		[T("Testar e entregar"), bool(j["done"])],
	]
	var active_set := false
	for it in items:
		var done: bool = it[1]
		var st := "done" if done else ("active" if not active_set else "todo")
		if not done:
			active_set = true
		objective_rows.add_child(_row(it[0], st))
	var late := _abs_minutes() > float(o["deadline"])
	objective_rows.add_child(_label(T("Prazo: %s%s") % [_clock_text(float(o["deadline"])), T("  (atrasado!)") if late else ""], 13, Color("ffb4a8") if late else MUTED))
	var others: Array = []
	for other in jobs.keys():
		if other != id and not jobs[other]["done"]:
			others.append(_dev_name(other))
	if not others.is_empty():
		objective_rows.add_child(_label(T("Também na bancada: %s") % ", ".join(others), 13, MUTED))


func _refresh_repair_panel() -> void:
	if active_device == "":
		return
	var id := active_device
	repair_title.text = T("Reparação: %s") % _dev_name(id)
	for c in repair_rows.get_children():
		c.queue_free()
	var j: Dictionary = jobs[id]
	var steps: Array = _fault(id)["steps"]
	var cur: int = j["step"]
	var cur_group: int = steps[cur]["g"] if cur < steps.size() else 99
	var groups: Array = _fault(id)["groups"]
	for gi in range(groups.size()):
		var text: String = T(groups[gi])
		if gi == 1 and bool(j["diagnosed"]):
			text += T(" (%s)") % T(_fault(id)["fault"])
		if gi == 2:
			var total := 0
			var done_count := 0
			for si in range(steps.size()):
				if str(steps[si]["act"]) == "unscrew":
					total = int(steps[si].get("need", 1))
					done_count = total if cur > si else (int(j["progress"]) if cur == si else 0)
			if total > 0:
				text += T(" (%d/%d)") % [done_count, total]
		var st := "done" if gi < cur_group else ("active" if gi == cur_group else "todo")
		repair_rows.add_child(_row(text, st))
	if cur < steps.size():
		var step: Dictionary = steps[cur]
		var need: int = step.get("need", 1)
		var extra := T("  (%d/%d)") % [int(j["progress"]), need] if need > 1 else ""
		step_hint.text = "➜ " + T(str(step["text"])) + extra + T("\nFerramenta: ") + _tool_need_text(step["tool"])
		var hints := [["mouse_l", T(str(step["verb"]))], ["mouse_r", T("Rodar")], ["TAB", T("Ferramentas")], ["Esc", T("Voltar")]]
		if _tech_count() > 0:
			hints.insert(3, ["T", T("Passar a técnico")])
		_set_hints(hints)
	else:
		step_hint.text = T("Reparação concluída!")


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
	p.offset_left = -500
	p.offset_right = 500
	p.offset_top = -310
	p.offset_bottom = 310
	board_root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	# tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)
	for t in [["orders", "Pedidos (P)"], ["shop", "Peças (L)"], ["upgrades", "Melhorias (U)"], ["decor", "Decoração"], ["team", "Equipa (F)"], ["used", "Mercado"], ["goals", "Metas (M)"]]:
		var b := Button.new()
		b.text = T(t[1])
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 38)
		b.add_theme_font_override("font", font_xbold)
		b.add_theme_font_size_override("font_size", 15)
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
	close.text = "✕"
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
	(board_root.get_meta("money") as Label).text = T("%s    ★ %.1f") % [_eur(money), _reputation()]
	if board_kind == "orders":
		_fill_orders()
	elif board_kind == "upgrades":
		_fill_upgrades()
	elif board_kind == "decor":
		_fill_decor()
	elif board_kind == "team":
		_fill_team()
	elif board_kind == "used":
		_fill_used()
	elif board_kind == "goals":
		_fill_goals()
	else:
		_fill_shop()


func _fill_orders() -> void:
	if orders.is_empty():
		board_box.add_child(_label(T("Ainda não há clientes. Vão chegando ao longo do dia."), 18, MUTED))
		return
	var status_txt := {"new": [T("NOVO PEDIDO"), YELLOW], "accepted": [T("NA FILA"), Color("7fb3ff")], "repair": [T("NA BANCADA"), GREEN], "ready": [T("PRONTO — NO BALCÃO"), GREEN], "done": [T("REPARADO — NA BANCADA"), GREEN], "carried": [T("NAS TUAS MÃOS"), GREEN], "shelf": [T("NA PRATELEIRA"), GREEN], "staff": [T("COM A EQUIPA"), Color("c39bff")]}
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
		top.add_child(_label(T("%s  •  %s") % [o["customer"], _dev_name(o["device"])], 19, TEXT, font_xbold))
		var st: Array = status_txt.get(o["status"], [str(o["status"]).to_upper(), MUTED])
		top.add_child(_label(st[0], 13, st[1], font_xbold))
		if bool(o.get("vip", false)):
			top.add_child(_label("VIP", 13, YELLOW, font_xbold))
		if bool(o.get("flip", false)):
			top.add_child(_label(T("REVENDA"), 13, Color("8fd8ff"), font_xbold))
		if o["status"] == "staff":
			var who := _staff_by_id(int(o.get("staff", -1)))
			if not who.is_empty():
				top.add_child(_label(str(who["name"]).get_slice(" ", 0), 13, Color("c39bff")))
		info.add_child(top)
		var q := _label("“%s”" % T(o["complaint"]), 16, Color("d3dde8"))
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.custom_minimum_size = Vector2(420, 0)
		info.add_child(q)
		var part: String = FAULTS[o["fault"]]["part"]
		var extra := ""
		if part != "" and o["status"] != "new":
			extra = T("   •   Peça em stock: %d") % int(inventory.get(part, 0))
		info.add_child(_label(T("Pagamento: %s   •   Prazo: %s%s") % [_eur(float(o["pay"])), _clock_text(float(o["deadline"])), extra], 14, MUTED))
		var btns := VBoxContainer.new()
		btns.add_theme_constant_override("separation", 6)
		h.add_child(btns)
		if o["status"] == "new":
			var acc := _small_button(T("Aceitar"), true)
			acc.pressed.connect(func() -> void: _accept_order(o))
			btns.add_child(acc)
			var dec := _small_button(T("Recusar"), false)
			dec.pressed.connect(func() -> void: _decline_order(o))
			btns.add_child(dec)
		elif o["status"] == "accepted":
			btns.add_child(_label(T("Bancada ocupada"), 13, MUTED))
		if o["status"] in ["accepted", "repair"] and _tech_count() > 0 and str(o.get("story", "")) == "" and not (_order_on_bench(o) and jobs[_bench_id(o)]["done"]):
			var idle := _idle_techs()
			if idle.is_empty():
				btns.add_child(_label(T("Técnicos ocupados ou fora de horário"), 12, MUTED))
			for e in idle:
				var b := _small_button(T("Passar a %s  ×%.1f") % [_first_name(e), _staff_speed(e, str(o["device"]))], false)
				b.custom_minimum_size = Vector2(190, 32)
				var ee: Dictionary = e
				b.pressed.connect(func() -> void: _delegate_order(o, ee))
				btns.add_child(b)
		board_box.add_child(card)


func _fill_shop() -> void:
	board_box.add_child(_label(T("As encomendas demoram uns minutos e chegam à receção, junto à porta."), 15, MUTED))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	board_box.add_child(chips)
	var filters := ["all", "laptop", "phone", "gamepad", "console", "handheld", "rotary", "radio"]
	for fkey in filters:
		var b := _small_button(T("Todos") if fkey == "all" else _dev_name(fkey), fkey == shop_filter)
		b.custom_minimum_size = Vector2(0, 32)
		var fk: String = fkey
		b.pressed.connect(func() -> void:
			shop_filter = fk
			_refresh_board())
		chips.add_child(b)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	board_box.add_child(grid)
	for key in Data.PARTS.keys():
		var pinfo: Dictionary = Data.PARTS[key]
		if shop_filter != "all" and pinfo["device"] != shop_filter:
			continue
		var card := _panel(Color(0.07, 0.11, 0.17, 1.0), 12, Vector4(10, 8, 12, 8))
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.custom_minimum_size = Vector2(355, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		var icon_bg := PanelContainer.new()
		var isb := StyleBoxFlat.new()
		isb.bg_color = Color(1, 1, 1, 0.06)
		isb.set_corner_radius_all(10)
		icon_bg.add_theme_stylebox_override("panel", isb)
		var tr := TextureRect.new()
		tr.texture = _part_icon(key)
		tr.custom_minimum_size = Vector2(72, 72)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_bg.add_child(tr)
		h.add_child(icon_bg)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(T(str(pinfo["name"])), 16, TEXT, font_xbold))
		info.add_child(_label(_dev_name(str(pinfo["device"])), 13, Color("8fd8ff")))
		var transit := 0
		for dl in deliveries:
			if dl["key"] == key:
				transit += 1
		var stock_txt := T("%s   •   Em stock: %d") % [_eur(float(pinfo["price"])), int(inventory.get(key, 0))]
		if transit > 0:
			stock_txt += "  (+%d %s)" % [transit, T("a caminho")]
		info.add_child(_label(stock_txt, 13, MUTED))
		h.add_child(info)
		var buy := _small_button(T("Comprar"), true)
		var k: String = key
		buy.disabled = money < float(pinfo["price"])
		buy.pressed.connect(func() -> void: _buy_part(k))
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(buy)
		grid.add_child(card)


func _base_speed() -> float:
	return (1.35 if upgrades.has("screwdriver") else 1.0) * (1.1 if upgrades.has("lamp") else 1.0)


func _use_comfort(what: String) -> void:
	match what:
		"fridge":
			if money < 3.0:
				_toast(T("Dinheiro insuficiente."), true)
				return
			money -= 3.0
			day_profit -= 3.0
			hunger = minf(100.0, hunger + 40.0)
			stamina = minf(100.0, stamina + 5.0)
			minutes += 10.0
			_sfx("part", 0.5)
			_toast(T("Que bom! Uma sandes e um sumo. (fome +40)"), false, GREEN)
		"kettle", "coffee_machine":
			var cost := 0.0 if what == "coffee_machine" else 1.0
			if money < cost:
				_toast(T("Dinheiro insuficiente."), true)
				return
			money -= cost
			day_profit -= cost
			var gain := 45.0 if what == "coffee_machine" else 35.0
			stamina = minf(100.0, stamina + gain)
			minutes += 5.0
			_sfx("pickup", 0.6)
			_toast(T("Café quentinho! (energia +%d)") % int(gain), false, GREEN)
		"bed":
			if not carrying.is_empty():
				_toast(T("Pousa primeiro o que tens nas mãos."), true)
				return
			if minutes < 17 * 60:
				_open_popup(T("Fechar a loja mais cedo?"), [
					[T("Ainda é cedo. Se dormires agora, o dia acaba e os clientes à espera vão-se embora."), TEXT],
				], [[T("Fechar e dormir"), func() -> void:
					_close_popup()
					_go_to_sleep()], [T("Continuar a trabalhar"), _close_popup]], true)
			else:
				_go_to_sleep()


## --- rearranging objects ------------------------------------------------------
func _start_move(info: Dictionary) -> void:
	var node: Node3D = info["node"]
	if info["kind"] == "device" and (active_device != "" or (jobs.has(info["id"]) and devices[info["id"]].busy)):
		return
	moving = info.duplicate()
	moving["orig"] = node.global_transform
	var excl: Array[RID] = []
	for b in _bodies_in(node):
		excl.append(b.get_rid())
	if info.has("pick") and is_instance_valid(info["pick"]):
		excl.append((info["pick"] as CollisionObject3D).get_rid())
	moving["exclude"] = excl
	if info["kind"] == "tool":
		moving["yoff"] = node.global_position.y - 0.92
	else:
		moving["yoff"] = 0.0
	mode = "move"
	prompt.hide()
	_set_hints([["mouse_l", T("Pousar")], ["R", T("Rodar")], ["Esc", T("Cancelar")]])
	hints_bar.show()
	_sfx("pickup", 0.6)


func _bodies_in(n: Node) -> Array:
	var out: Array = []
	if n is CollisionObject3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_bodies_in(c))
	return out


func _update_move() -> void:
	if moving.is_empty():
		return
	var node: Node3D = moving["node"]
	var center := get_viewport().get_visible_rect().size * 0.5
	var from := cam.project_ray_origin(center)
	var to := from + cam.project_ray_normal(center) * 3.0
	var place: String = moving["place"]
	var mask := 4 if place == "wall" else (8 if place == "floor" else (2 if moving["kind"] == "device" else 2 | 8))
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	q.exclude = moving["exclude"]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var pos: Vector3 = hit.position
	if place == "wall":
		var nrm: Vector3 = hit.normal
		pos += nrm * 0.005
		pos.y = clampf(pos.y, 0.6, 2.5)
		node.global_transform = Transform3D(Basis.looking_at(-nrm, Vector3.UP), pos)
	else:
		if place == "surface" and hit.normal.y < 0.7:
			return
		if not _place_ok(pos):
			return
		node.global_position = pos + Vector3(0, float(moving["yoff"]), 0)


func _rotate_moving(dir := 1.0) -> void:
	if moving.is_empty() or moving["place"] == "wall":
		return
	(moving["node"] as Node3D).rotate_y(deg_to_rad(15.0) * dir)


func _end_move(confirm: bool) -> void:
	var node: Node3D = moving["node"]
	if not confirm:
		node.global_transform = moving["orig"]
	if moving["kind"] == "tool" and moving.has("pick"):
		(moving["pick"] as Node3D).global_position = node.global_position + Vector3(0, 0.03 - float(moving["yoff"]), 0)
	moving = {}
	mode = "walk"
	hints_bar.hide()
	if confirm:
		_sfx("part", 0.5)
		_save_game()


func _spawn_decor(id: String, xf = null) -> Dictionary:
	var n := room.make_decor(id)
	add_child(n)
	var i := decor_items.size()
	var place: String = Room.DECOR[id]["place"]
	var size := Vector3(0.5, 0.65, 0.06) if place == "wall" else (Vector3(1.0, 0.3, 0.8) if id == "rug" else Vector3(0.35, 0.5, 0.35))
	var body := Kit.static_body(n, Kit.box_shape(size), Vector3(0, 0.0 if place == "wall" else size.y * 0.5, 0.03 if place == "wall" else 0.0), "decor:%d" % i)
	body.collision_layer = 1
	var item := {"id": id, "node": n, "body": body}
	decor_items.append(item)
	if xf != null:
		n.global_transform = xf
	return item


func _buy_decor(id: String) -> void:
	var price := float(Room.DECOR[id]["price"])
	if money < price:
		_toast(T("Dinheiro insuficiente."), true)
		return
	money -= price
	day_profit -= price
	var item := _spawn_decor(id)
	var node: Node3D = item["node"]
	node.global_position = cam.global_position + (-cam.global_transform.basis.z) * 1.2
	_close_board()
	_sfx("cash", 0.5)
	_toast(T("Escolhe onde pôr: olha para o sítio e clica."), false, YELLOW)
	_start_move({"node": node, "kind": "decor", "id": id, "pick": item["body"], "place": Room.DECOR[id]["place"]})


var sit_return := Vector3.ZERO


func _sit(i: int) -> void:
	if not carrying.is_empty():
		_toast(T("Pousa primeiro o que tens nas mãos."), true)
		return
	_equip("none")
	prompt.hide()
	sit_return = cam.position
	mode = "sit"
	var seat: Vector3 = room.stools[i]
	var tw := create_tween()
	tw.tween_property(cam, "position", seat + Vector3(0, 1.22, 0), 0.4).set_trans(Tween.TRANS_CUBIC)
	_sfx("step", 0.5)
	_set_hints([["E", T("Levantar")], ["Esc", T("Pausa")]])
	hints_bar.show()
	_toast(T("Sentado: o tempo passa mais depressa e recuperas energia. E para levantar."), false, YELLOW)


func _stand_up() -> void:
	mode = "walk"
	hints_bar.hide()
	var tw := create_tween()
	tw.tween_property(cam, "position", Vector3(sit_return.x, EYE_H, sit_return.z), 0.35).set_trans(Tween.TRANS_CUBIC)


func _go_to_sleep() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.6)
	tw.tween_callback(func() -> void:
		stamina = 100.0
		hunger = maxf(30.0, hunger - 15.0)
		minutes = maxf(minutes, 20 * 60 - 1)
		_end_of_day()
		_toast(T("Dormiste como uma pedra. Energia no máximo!"), false, GREEN))
	tw.tween_property(fade, "color:a", 0.0, 0.8)


func _update_fatigue() -> void:
	DeviceBase.anim_speed = _base_speed() * (0.7 if stamina < 25.0 else 1.0)
	if stamina < 25.0 and not tired_warned:
		tired_warned = true
		_toast(T("Estás cansado: trabalhas mais devagar. Bebe um café ou vai descansar."), true)
	elif stamina >= 30.0:
		tired_warned = false


func _apply_upgrades() -> void:
	DeviceBase.anim_speed = _base_speed()
	for id in upgrades.keys():
		room.add_upgrade(id)
	coffee_body = null
	if upgrades.has("coffee") and room.upgrade_nodes.has("coffee"):
		coffee_body = (room.upgrade_nodes["coffee"] as Node3D).get_meta("body")


func _buy_upgrade(key: String) -> void:
	var price := float(Data.UPGRADES[key]["price"])
	if upgrades.has(key) or money < price:
		_toast(T("Dinheiro insuficiente."), true)
		return
	money -= price
	day_profit -= price
	upgrades[key] = true
	_apply_upgrades()
	_sfx("cash", 0.6)
	_toast(T("Melhoria instalada: %s") % T(Data.UPGRADES[key]["name"]), false, GREEN)
	_save_game()
	_refresh_board()


func _fill_decor() -> void:
	board_box.add_child(_label(T("Compra e escolhe onde pôr. Em jogo, olha para um objeto e carrega G para o mudar de sítio."), 15, MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	board_box.add_child(grid)
	var where_txt := {"wall": T("Parede"), "floor": T("Chão"), "surface": T("Bancada / balcão")}
	for key in Room.DECOR.keys():
		var d: Dictionary = Room.DECOR[key]
		var card := _panel(Color(0.07, 0.11, 0.17, 1.0), 12, Vector4(14, 10, 14, 10))
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.custom_minimum_size = Vector2(355, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(T(str(d["name"])), 16, TEXT, font_xbold))
		info.add_child(_label("%s   •   %s" % [_eur(float(d["price"])), where_txt[d["place"]]], 13, MUTED))
		h.add_child(info)
		var buy := _small_button(T("Comprar"), true)
		var k: String = key
		buy.disabled = money < float(d["price"])
		buy.pressed.connect(func() -> void: _buy_decor(k))
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(buy)
		grid.add_child(card)


func _fill_upgrades() -> void:
	board_box.add_child(_label(T("Investe na oficina: cada melhoria aparece na loja e tem um efeito permanente."), 15, MUTED))
	for key in Data.UPGRADES.keys():
		var u: Dictionary = Data.UPGRADES[key]
		var card := _panel(Color(0.07, 0.11, 0.17, 1.0), 12, Vector4(14, 10, 14, 10))
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		card.add_child(h)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(T(str(u["name"])), 18, TEXT, font_xbold))
		var dl := _label(T(str(u["desc"])), 15, MUTED)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(480, 0)
		info.add_child(dl)
		h.add_child(info)
		if upgrades.has(key):
			h.add_child(_label(T("Instalado ✓"), 16, GREEN, font_xbold))
		else:
			var buy := _small_button("%s  %s" % [T("Comprar"), _eur(float(u["price"]))], true)
			buy.custom_minimum_size = Vector2(170, 38)
			buy.disabled = money < float(u["price"])
			var k: String = key
			buy.pressed.connect(func() -> void: _buy_upgrade(k))
			h.add_child(buy)
		board_box.add_child(card)


func _buy_part(key: String) -> void:
	var price := float(Data.PARTS[key]["price"])
	if money < price:
		_toast(T("Dinheiro insuficiente."), true)
		return
	money -= price
	day_profit -= price
	var eta := randf_range(15.0, 30.0)
	deliveries.append({"key": key, "arrive": _abs_minutes() + eta})
	_sfx("cash", 0.5)
	_toast(T("Encomenda feita: %s. Chega à receção dentro de ~%d min.") % [T(Data.PARTS[key]["name"]), int(eta)], false, GREEN)
	_refresh_board()


func _delivery_tick() -> void:
	var now := _abs_minutes()
	for d in deliveries.duplicate():
		if now >= float(d["arrive"]):
			var slot := _free_receive_slot()
			if slot < 0:
				return
			deliveries.erase(d)
			_send_postman(str(d["key"]), slot)


## The postman walks in with the parcel, leaves it on the receiving shelf and goes.
func _send_postman(key: String, slot: int) -> void:
	reserved_slots.append(slot)
	postman_keys.append(key)
	var pm: Node3D = CustomerScene.new()
	pm.setup(T("Carteiro"), 4242 + slot, {"skin": Color("e0b08c"), "hair": Color("3a2a1e"), "shirt": Color("2b4f8c"), "pants": Color("1f2a44"), "hair_style": 3, "cap": Color("1d3563"), "extras": ["bag"], "height": 1.0})
	pm.pick.collision_layer = 0
	add_child(pm)
	pm.global_position = DOOR_OUT
	pm.hold(room.make_parcel(""))
	room.open_door()
	_sfx("door_chime", 0.6)
	_toast(T("O carteiro chegou com uma encomenda!"), false, YELLOW)
	var stop := Room.RECEIVE_POS + Vector3(-0.55, 0, 0)
	pm.walk_path([DOOR_IN, Vector3(1.95, 0, 1.4), stop], func() -> void:
		pm.rotation.y = PI * 0.5
		pm.hold(null)
		reserved_slots.erase(slot)
		postman_keys.erase(key)
		_spawn_parcel(key, slot)
		get_tree().create_timer(0.8).timeout.connect(func() -> void:
			pm.walk_path([Vector3(1.95, 0, 1.4), DOOR_IN, DOOR_OUT], func() -> void: pm.queue_free())
			get_tree().create_timer(2.2).timeout.connect(room.open_door)))


func _free_receive_slot() -> int:
	var used: Array = reserved_slots.duplicate()
	for pc in parcels:
		used.append(pc["slot"])
	for i in range(room.receive_slots.size()):
		if not used.has(i):
			return i
	return -1


func _spawn_parcel(key: String, slot: int) -> void:
	var n := room.make_parcel(_item_name(key))
	add_child(n)
	n.global_position = room.receive_slots[slot]
	n.rotation_degrees.y = -90 + randf_range(-8, 8)
	n.scale = Vector3(0.01, 0.01, 0.01)
	create_tween().tween_property(n, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var body := Kit.static_body(n, Kit.box_shape(Vector3(0.28, 0.18, 0.22)), Vector3(0, 0.08, 0), "parcel")
	body.collision_layer = 1
	var item := {"key": key, "node": n, "body": body, "slot": slot}
	body.set_meta("parcel", item)
	parcels.append(item)
	_sfx("door_chime", 0.5)
	_toast(T("Encomenda entregue na receção (junto à porta)!"), false, YELLOW)
	_refresh_objective()


func _open_parcel(item: Dictionary) -> void:
	parcels.erase(item)
	var key: String = item["key"]
	if key.begins_with("prod:"):
		_open_product_parcel(item)
		return
	inventory[key] = int(inventory.get(key, 0)) + 1
	var n: Node3D = item["node"]
	(item["body"] as StaticBody3D).collision_layer = 0
	var t := create_tween()
	t.tween_property(n, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
	t.tween_callback(n.queue_free)
	_sfx("part", 0.7)
	_toast(T("%s guardado no stock.") % T(Data.PARTS[key]["name"]), false, GREEN)
	_goal_progress("parts", 1)
	_refresh_objective()
	if mode == "inspect":
		_activate_step_targets()


func _xf_array(t: Transform3D) -> Array:
	return [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z, t.origin.x, t.origin.y, t.origin.z]


func _decor_save() -> Array:
	var out: Array = []
	for de in decor_items:
		if is_instance_valid(de["node"]):
			out.append({"id": de["id"], "xf": _xf_array((de["node"] as Node3D).global_transform)})
	return out


func _tools_save() -> Dictionary:
	var out := {}
	for tid in bench_tools.keys():
		out[tid] = _xf_array((bench_tools[tid] as Node3D).global_transform)
	return out


## A few decorations already on the walls of grandpa's workshop.
func _default_decor() -> void:
	_spawn_decor("poster_fixit", Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), Vector3(2.597, 1.65, 1.95)))
	_spawn_decor("poster_radio", Transform3D(Basis.looking_at(Vector3(-1, 0, 0), Vector3.UP), Vector3(-2.597, 1.65, 2.05)))
	_spawn_decor("clock", Transform3D(Basis.looking_at(Vector3(0, 0, 1), Vector3.UP), Vector3(-1.75, 2.1, 2.597)))
	_spawn_decor("string_lights", Transform3D(Basis.looking_at(Vector3(0, 0, -1), Vector3.UP), Vector3(1.2, 2.45, -1.745)))
	_spawn_decor("cactus", Transform3D(Basis.IDENTITY, Vector3(1.38, Room.COUNTER_TOP, Room.COUNTER_Z + 0.1)))


func _clear_decor() -> void:
	for de in decor_items:
		if is_instance_valid(de["node"]):
			de["node"].queue_free()
	decor_items.clear()


func _clear_world_items() -> void:
	for pc in parcels:
		if is_instance_valid(pc["node"]):
			pc["node"].queue_free()
	parcels.clear()
	deliveries.clear()
	postman_keys.clear()
	reserved_slots.clear()
	for c in cash_items:
		if is_instance_valid(c["node"]):
			c["node"].queue_free()
	cash_items.clear()
	for i in range(shelf_items.size()):
		if shelf_items[i] != null and is_instance_valid(shelf_items[i]["node"]):
			shelf_items[i]["node"].queue_free()
		shelf_items[i] = null
	_end_carry()


## 3D thumbnail of a spare part for the shop (rendered once, cached).
func _part_icon(key: String) -> Texture2D:
	if part_icons.has(key):
		return part_icons[key]
	var vp := SubViewport.new()
	vp.size = Vector2i(160, 160)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	add_child(vp)
	var root3d := Node3D.new()
	vp.add_child(root3d)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c8d4e6")
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	root3d.add_child(we)
	var key_l := DirectionalLight3D.new()
	key_l.rotation_degrees = Vector3(-50, -30, 0)
	key_l.light_energy = 1.6
	root3d.add_child(key_l)
	var model := _part_model(key)
	root3d.add_child(model)
	var aabb := AABB()
	var first := true
	for m in _meshes_in(model):
		var mi: MeshInstance3D = m
		if mi.mesh == null:
			continue
		var box: AABB = mi.global_transform * mi.mesh.get_aabb()
		aabb = box if first else aabb.merge(box)
		first = false
	var center := aabb.get_center()
	var size := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var c := Camera3D.new()
	c.projection = Camera3D.PROJECTION_ORTHOGONAL
	c.size = maxf(0.02, size * 1.25)
	root3d.add_child(c)
	c.look_at_from_position(center + Vector3(0.25, 0.85, 0.55).normalized() * (size * 3.0 + 0.1), center, Vector3.UP)
	part_icons[key] = vp.get_texture()
	_freeze_viewport_later(vp)
	return part_icons[key]


func _meshes_in(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for ch in n.get_children():
		out.append_array(_meshes_in(ch))
	return out


func _part_model(key: String) -> Node3D:
	var dev: String = Data.PARTS[key]["device"]
	var d: Node3D
	match dev:
		"laptop":
			d = Laptop.new()
		"phone":
			d = Phone.new()
		"console":
			d = ConsoleDev.new()
		"handheld":
			d = HandheldDev.new()
		"rotary":
			d = RotaryDev.new()
		"radio":
			d = RadioDev.new()
		_:
			d = Gamepad.new()
	var node: Node3D
	if key == "battery":
		node = d._battery_model(false)
	elif key == "phone_screen":
		node = d._build_screen_assembly(false)
	else:
		node = d.parts[key]["node"]
		node.get_parent().remove_child(node)
	d.free()
	var holder := Node3D.new()
	holder.add_child(node)
	node.transform = Transform3D.IDENTITY
	if key in ["battery", "laptop_fan", "ssd", "joystick", "console_fan", "disc_drive", "handheld_battery"]:
		node.rotation = Vector3(0, 0, PI)
	var dust := node.get_node_or_null("Dust")
	if dust:
		dust.visible = false
	return holder


func _small_button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.pressed.connect(func() -> void: _sfx("click"))
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
	for it in [["mouse", T("Selecionar")], ["E", T("Confirmar")], ["Esc", T("Fechar")]]:
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
	menu_buttons.add_child(_menu_button(T("Começar Jogo"), "play", true, func() -> void: _show_slots("new")))
	load_button = _menu_button(T("Carregar Jogo"), "folder", false, func() -> void: _show_slots("load"))
	menu_buttons.add_child(load_button)
	menu_buttons.add_child(_menu_button(T("Definições"), "gear", false, func() -> void: _show_menu_panel("settings")))
	menu_buttons.add_child(_menu_button(T("Créditos"), "info", false, func() -> void: _show_menu_panel("credits")))
	menu_buttons.add_child(_menu_button(T("Sair"), "power", false, func() -> void: get_tree().quit()))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fill)
	col.add_child(_label(T("%s  •  Compra, repara e revende") % VERSION, 14, Color(0.75, 0.82, 0.9, 0.7)))
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
	for line in [T("FIX & FLIP"), T("TECH")]:
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
		if line == T("TECH"):
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
	var pl := _label(T("Oficina de Eletrónica"), 24, Color("bfeaff"), font_xbold)
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
	b.pressed.connect(func() -> void: _sfx("click"))
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


func _rebuild_ui(in_game := false) -> void:
	if ui:
		ui.queue_free()
	ui = null
	hotbar_slots.clear()
	room.relabel()
	_build_ui()
	if not in_game:
		_show_menu()
		_show_menu_panel("settings")
		return
	menu_root.hide()
	hud.show()
	crosshair.show()
	reticle.hide()
	repair_panel.hide()
	hints_bar.hide()
	_hotbar_compact(false)
	_refresh_hotbar()
	_refresh_objective()
	_refresh_orders_badge()
	_pause()
	_pause_settings()


func _settings_controls(v: VBoxContainer, in_game: bool) -> void:
	v.add_child(_label(T("Qualidade gráfica"), 16, MUTED))
	var q := OptionButton.new()
	for t in [T("Baixa (PC fraco)"), T("Média"), T("Alta (SSIL, reflexos, nevoeiro)")]:
		q.add_item(t)
	q.selected = int(settings["quality"])
	q.item_selected.connect(func(i: int) -> void:
		settings["quality"] = i
		_apply_settings()
		_save_settings())
	v.add_child(q)
	v.add_child(_label(T("Idioma / Language"), 16, MUTED))
	var lang := OptionButton.new()
	lang.add_item("Português")
	lang.add_item("English")
	lang.selected = 1 if I18n.lang == "en" else 0
	lang.item_selected.connect(func(i: int) -> void:
		settings["lang"] = "en" if i == 1 else "pt"
		I18n.lang = settings["lang"]
		_save_settings()
		_rebuild_ui(in_game))
	v.add_child(lang)
	for vol in [["music", T("Volume da música")], ["sfx", T("Volume dos efeitos")]]:
		v.add_child(_label(vol[1], 16, MUTED))
		var vs := HSlider.new()
		vs.min_value = 0.0
		vs.max_value = 1.0
		vs.step = 0.05
		var key: String = vol[0]
		vs.value = float(settings.get(key, 0.6 if key == "music" else 0.8))
		vs.value_changed.connect(func(val: float) -> void:
			settings[key] = val
			audio.set_volumes(float(settings.get("music", 0.6)), float(settings.get("sfx", 0.8)))
			_save_settings())
		v.add_child(vs)
	v.add_child(_label(T("Sensibilidade do rato"), 16, MUTED))
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
	fs.text = T("Ecrã inteiro")
	fs.button_pressed = bool(settings["fullscreen"])
	fs.toggled.connect(func(on: bool) -> void:
		settings["fullscreen"] = on
		_apply_settings()
		_save_settings())
	v.add_child(fs)


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
		v.add_child(_label(T("Definições"), 24, YELLOW, font_xbold))
		_settings_controls(v, false)
	else:
		v.add_child(_label(T("Créditos"), 24, YELLOW, font_xbold))
		var t := _label(T("Fix & Flip Tech — protótipo de simulação de oficina.\n\nModelos 3D, materiais e animações gerados por código no Godot 4.\nTipo de letra: Nunito (SIL Open Font License).\n\nObrigado por jogares!"), 16, TEXT)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(316, 0)
		v.add_child(t)
	var close := _menu_button(T("Voltar"), "play", false, func() -> void:
		for c in menu_panel_host.get_children():
			c.queue_free())
	v.add_child(close)


## Save slot picker (3 slots): new game or load.
func _show_slots(purpose: String) -> void:
	for c in menu_panel_host.get_children():
		c.queue_free()
	var p := _panel(Color(0.04, 0.07, 0.12, 0.93), 14, Vector4(22, 18, 22, 18))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.custom_minimum_size = Vector2(420, 0)
	menu_panel_host.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(_label(T("Novo jogo — escolhe uma ranhura") if purpose == "new" else T("Carregar jogo"), 22, YELLOW, font_xbold))
	for i in range(1, 4):
		var info := _slot_info(i)
		var card := _panel(Color(0.07, 0.11, 0.17, 1.0), 12, Vector4(14, 10, 14, 10))
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(_label(T("Ranhura %d") % i, 18, TEXT, font_xbold))
		if info.is_empty():
			col.add_child(_label(T("Vazia"), 14, MUTED))
		else:
			var ch: int = clampi(int(info.get("story_chapter", 0)), 0, Story.CHAPTERS.size() - 1)
			col.add_child(_label("%s %d  •  %s  •  %d %s" % [T("Dia"), int(info.get("day", 1)), _eur(float(info.get("money", 0))), int(info.get("repaired", 0)), T("reparações")], 14, MUTED))
			col.add_child(_label(I18n.pick(Story.CHAPTERS[ch]["title"]), 13, Color("8fd8ff")))
		h.add_child(col)
		var slot := i
		if purpose == "new":
			var b := _small_button(T("Começar") if info.is_empty() else T("Substituir"), info.is_empty())
			b.pressed.connect(func() -> void:
				if _slot_exists(slot):
					_confirm_overwrite(slot)
				else:
					current_slot = slot
					_new_game())
			h.add_child(b)
		elif not info.is_empty():
			var b2 := _small_button(T("Continuar"), true)
			b2.pressed.connect(func() -> void:
				current_slot = slot
				_continue_game())
			h.add_child(b2)
			var del := _small_button(T("Apagar"), false)
			del.custom_minimum_size = Vector2(80, 36)
			del.pressed.connect(func() -> void:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH % slot))
				_show_slots(purpose)
				_update_load_button())
			h.add_child(del)
		v.add_child(card)
	v.add_child(_menu_button(T("Voltar"), "play", false, func() -> void:
		for c in menu_panel_host.get_children():
			c.queue_free()))


func _confirm_overwrite(slot: int) -> void:
	for c in menu_panel_host.get_children():
		c.queue_free()
	var p := _panel(Color(0.04, 0.07, 0.12, 0.95), 14, Vector4(22, 18, 22, 18))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.custom_minimum_size = Vector2(380, 0)
	menu_panel_host.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(_label(T("Substituir a ranhura %d?") % slot, 22, YELLOW, font_xbold))
	v.add_child(_label(T("O progresso guardado nesta ranhura vai ser apagado."), 15, MUTED))
	var yes := _menu_button(T("Sim, começar de novo"), "play", true, func() -> void:
		current_slot = slot
		_new_game())
	v.add_child(yes)
	v.add_child(_menu_button(T("Voltar"), "play", false, func() -> void: _show_slots("new")))


func _update_load_button() -> void:
	load_button.disabled = not _has_save()
	(load_button.get_meta("label") as Label).modulate.a = 1.0 if _has_save() else 0.45


func _show_menu() -> void:
	mode = "menu"
	audio.play_music("music_menu")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_root.show()
	hud.hide()
	pause_root.hide()
	wheel_root.hide()
	popup_root.hide()
	board_root.hide()
	hand.visible = false
	_update_load_button()
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
	story_chapter = 0
	story_deliveries = 0
	story_flags = {}
	rent_due_day = 0
	rent_amount = Story.RENT
	upgrades = {}
	stamina = 100.0
	hunger = 100.0
	staff_seq = 0
	staff_first = true
	stats = {}
	achievements = {}
	_staff_load([])
	_set_expansion(0)
	retail_stock = {}
	_stand_clear()
	_new_day_refresh()
	_clear_decor()
	room.clear_upgrades()
	_apply_upgrades()
	_reset_jobs()
	_clear_customers()
	_clear_world_items()
	orders.clear()
	_default_decor()
	_save_game()
	_start_game(true)


func _continue_game() -> void:
	if _load_game():
		_reset_jobs()
		_clear_customers()
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
		audio.play_playlist(["music_workshop", "music_workshop2", "music_workshop3", "music_workshop4", "music_evening"])
		_reset_walk_camera()
		_equip("none")
		crosshair.show()
		reticle.hide()
		objective_panel.show()
		repair_panel.hide()
		hints_bar.hide()
		_hotbar_compact(false)
		focus_job = ""
		next_order_at = _abs_minutes() + 60.0
		_refresh_objective()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if first:
			_story_begin()
		else:
			_morning_orders()
			_toast(T("Bem-vindo de volta! Os clientes esperam no balcão."), false, YELLOW))
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
	p.offset_left = -200
	p.offset_right = 200
	p.offset_top = -270
	p.offset_bottom = 270
	pause_root.add_child(p)
	pause_panel = p
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	pause_main = v
	pause_settings_box = VBoxContainer.new()
	pause_settings_box.add_theme_constant_override("separation", 10)
	p.add_child(pause_settings_box)
	pause_settings_box.hide()
	v.add_child(_label(T("Pausa"), 28, YELLOW, font_xbold))
	v.add_child(_menu_button(T("Continuar"), "play", true, _resume))
	v.add_child(_menu_button(T("Definições"), "gear", false, _pause_settings))
	v.add_child(_menu_button(T("Guardar Jogo"), "folder", false, func() -> void:
		_save_game()
		_toast(T("Jogo guardado na ranhura %d.") % current_slot, false, GREEN)))
	v.add_child(_menu_button(T("Menu Principal"), "info", false, func() -> void:
		_save_game()
		_show_menu()))
	v.add_child(_menu_button(T("Sair"), "power", false, func() -> void:
		_save_game()
		get_tree().quit()))
	pause_root.hide()


func _pause() -> void:
	mode = "pause"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_root.show()
	pause_main.show()
	pause_settings_box.hide()


func _pause_settings() -> void:
	for c in pause_settings_box.get_children():
		pause_settings_box.remove_child(c)
		c.queue_free()
	pause_settings_box.add_child(_label(T("Definições"), 26, YELLOW, font_xbold))
	_settings_controls(pause_settings_box, true)
	pause_settings_box.add_child(_menu_button(T("Voltar"), "play", false, func() -> void:
		pause_settings_box.hide()
		pause_main.show()))
	pause_main.hide()
	pause_settings_box.show()


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


# =============================================================================
# Shop expansion, staff, used-device market, daily goals and achievements
# =============================================================================
const DESK_POS := Vector3(0.35, 0.0, 0.8)
const UPGRADE_PLACE := {"screwdriver": "surface", "coffee": "surface", "speaker": "surface", "display": "floor", "neon": "wall"}


func _set_expansion(lvl: int) -> void:
	expansion = clampi(lvl, 0, Staff.EXPANSIONS.size())
	room.set_expansion(expansion)
	if annex_door_body:
		annex_door_body.collision_layer = 0 if expansion >= 1 else 4
	var n := 8 if expansion >= 2 else 4
	while shelf_items.size() > n:
		var it = shelf_items.pop_back()
		if it != null and is_instance_valid(it["node"]):
			(it["node"] as Node3D).queue_free()
	while shelf_items.size() < n:
		shelf_items.append(null)
	_build_shelf_targets()
	_stat_set("expansion", expansion)
	_refresh_station_labels()


func _buy_expansion() -> void:
	if expansion >= Staff.EXPANSIONS.size():
		return
	var ex: Dictionary = Staff.EXPANSIONS[expansion]
	var price := float(ex["price"])
	if money < price:
		_toast(T("Dinheiro insuficiente."), true)
		return
	money -= price
	day_profit -= price
	_set_expansion(expansion + 1)
	_sfx("cash")
	_toast(T("Obras concluídas: %s! Vai ver o anexo pela porta da direita.") % T(str(ex["name"])), false, GREEN)
	_save_game()
	_refresh_board()


func _free_shelf_slot() -> int:
	for i in range(shelf_items.size()):
		if shelf_items[i] == null:
			return i
	return -1


# --- staff helpers -------------------------------------------------------------
func _tech_count() -> int:
	var n := 0
	for e in staff:
		if e["role"] == "tech":
			n += 1
	return n


func _staff_by_id(id: int) -> Dictionary:
	for e in staff:
		if int(e["id"]) == id:
			return e
	return {}


func _first_name(e: Dictionary) -> String:
	return str(e["name"]).get_slice(" ", 0)


func _cat_of(device: String) -> String:
	for c in Staff.CATEGORIES.keys():
		if device in Staff.CATEGORIES[c]["devices"]:
			return c
	return "pc"


func _staff_speed(e: Dictionary, device: String) -> float:
	var sk: Dictionary = e.get("skills", {})
	return float(sk.get(_cat_of(device), 1.0)) * (1.0 + minf(float(e.get("repairs", 0)), 30.0) * 0.01) * (1.1 if upgrades.has("lamp") else 1.0)


func _on_shift(e: Dictionary) -> bool:
	var sh: Dictionary = Staff.SHIFTS[str(e["shift"])]
	var h := minutes / 60.0
	return h >= float(sh["start"]) and h < float(sh["end"])


func _shift_text(shift: String) -> String:
	var sh: Dictionary = Staff.SHIFTS[shift]
	return "%s  %02d:00–%02d:00" % [T(str(sh["name"])), int(sh["start"]), int(sh["end"])]


func _stations_available() -> int:
	return mini(room.staff_stations.size(), 2 * expansion)


func _free_station() -> int:
	for i in range(_stations_available()):
		var used := false
		for e in staff:
			if e["role"] == "tech" and int(e.get("station", -1)) == i:
				used = true
		if not used:
			return i
	return -1


func _gen_candidate(role: String) -> Dictionary:
	var ni := randi() % Staff.NAMES.size()
	for tries in range(10):
		var clash := false
		for e in staff + candidates:
			if int(e.get("ni", -1)) == ni:
				clash = true
		if not clash:
			break
		ni = randi() % Staff.NAMES.size()
	var stars := 1 + int(randf() < 0.55) + int(randf() < 0.25)
	var shift: String = ["morning", "afternoon", "full"][randi() % 3]
	var c := {"ni": ni, "name": Staff.NAMES[ni][0], "role": role, "stars": stars, "shift": shift, "seed": randi() % 100000, "repairs": 0}
	var wage := 0.0
	if role == "tech":
		var cats: Array = Staff.CATEGORIES.keys()
		var main: String = cats[randi() % cats.size()]
		var sk := {}
		for k in cats:
			sk[k] = snappedf(randf_range(0.65, 1.0) + 0.07 * stars, 0.05)
		sk[main] = snappedf(randf_range(1.45, 1.8) + 0.1 * stars, 0.05)
		c["skills"] = sk
		c["main"] = main
		wage = 28.0 + 14.0 * stars + (float(sk[main]) - 1.5) * 30.0
	else:
		wage = 24.0 + 9.0 * stars
	c["wage"] = maxf(15.0, snappedf(wage * float(Staff.SHIFTS[shift]["mult"]), 5.0))
	return c


func _hire(i: int) -> void:
	if i < 0 or i >= candidates.size():
		return
	var c: Dictionary = candidates[i]
	if c["role"] == "tech":
		var st := _free_station()
		if st < 0:
			_toast(T("Não há bancada livre para um técnico. Expande a loja primeiro."), true)
			return
		c["station"] = st
	else:
		for e in staff:
			if e["role"] == "desk":
				_toast(T("Já tens um balconista."), true)
				return
	staff_seq += 1
	c["id"] = staff_seq
	c["job"] = {}
	candidates.remove_at(i)
	staff.append(c)
	_stat_add("hired", 1)
	_stat_set("team_size", staff.size())
	_toast(T("%s foi contratado/a! Turno: %s.") % [c["name"], _shift_text(str(c["shift"]))], false, GREEN)
	_sfx("door_chime", 0.6)
	_staff_tick()
	_save_game()
	_refresh_board()


func _fire(id: int) -> void:
	var e := _staff_by_id(id)
	if e.is_empty():
		return
	var job: Dictionary = e.get("job", {})
	if not job.is_empty():
		var o: Dictionary = job["order"]
		if orders.has(o):
			o["status"] = "accepted"
			o.erase("staff")
			var part: String = FAULTS[o["fault"]]["part"]
			if part != "":
				inventory[part] = int(inventory.get(part, 0)) + 1
	_staff_clear_device(e)
	if staff_nodes.has(id) and is_instance_valid(staff_nodes[id]):
		(staff_nodes[id] as Node3D).queue_free()
	staff_nodes.erase(id)
	staff.erase(e)
	_toast(T("%s saiu da equipa.") % e["name"])
	_refresh_station_labels()
	_place_waiting_orders()
	_save_game()
	_refresh_board()


func _pay_wages() -> float:
	var total := 0.0
	for e in staff:
		total += float(e["wage"])
	if total > 0.0:
		money -= total
		day_profit -= total
	return total


func _staff_save() -> Array:
	var out: Array = []
	for e in staff:
		var d: Dictionary = {}
		for k in e.keys():
			if k in ["job", "dev_node", "timer", "warned"]:
				continue
			d[k] = e[k]
		out.append(d)
	return out


func _staff_load(arr) -> void:
	for e in staff:
		_staff_clear_device(e)
	for n in staff_nodes.values():
		if is_instance_valid(n):
			(n as Node3D).queue_free()
	staff_nodes.clear()
	staff = []
	if arr is Array:
		for d in arr:
			if not (d is Dictionary):
				continue
			var e: Dictionary = (d as Dictionary).duplicate(true)
			for k in ["id", "ni", "stars", "seed", "repairs", "station"]:
				if e.has(k):
					e[k] = int(e[k])
			if not Staff.SHIFTS.has(str(e.get("shift", ""))):
				e["shift"] = "full"
			e["job"] = {}
			staff.append(e)
	staff_last_min = -1.0
	_refresh_station_labels()


# --- staff simulation ------------------------------------------------------------
func _order_on_bench(o: Dictionary) -> bool:
	for id in jobs.keys():
		if jobs[id]["order"] == o:
			return true
	return false


func _staff_assign_all() -> void:
	for e in staff:
		if e["role"] == "tech" and (e.get("job", {}) as Dictionary).is_empty() and _on_shift(e):
			_staff_take_job(e)


func _staff_take_job(e: Dictionary) -> bool:
	var best: Dictionary = {}
	var best_speed := 0.0
	for o in orders:
		if o["status"] != "accepted" or _order_on_bench(o) or str(o.get("story", "")) != "":
			continue
		var part: String = FAULTS[o["fault"]]["part"]
		if part != "" and int(inventory.get(part, 0)) <= 0:
			continue
		var sp := _staff_speed(e, str(o["device"]))
		if sp > best_speed:
			best = o
			best_speed = sp
	if best.is_empty():
		return false
	var part2: String = FAULTS[best["fault"]]["part"]
	if part2 != "":
		inventory[part2] = int(inventory.get(part2, 0)) - 1
	best["status"] = "staff"
	best["staff"] = e["id"]
	var total := float((FAULTS[best["fault"]]["steps"] as Array).size()) * 3.5 / best_speed
	e["job"] = {"order": best, "left": total, "total": total}
	_staff_show_device(e)
	_refresh_orders_badge()
	_refresh_orders_panel()
	return true


func _staff_tick() -> void:
	var now := _abs_minutes()
	if staff_last_min < 0.0 or now < staff_last_min:
		staff_last_min = now
	var dm := minf(now - staff_last_min, 5.0)     # time jumps (sleeping, loading) don't finish jobs instantly
	staff_last_min = now
	for e in staff.duplicate():
		var on := _on_shift(e)
		_staff_place_node(e, on)
		if e["role"] == "tech":
			var job: Dictionary = e.get("job", {})
			if job.is_empty():
				if on:
					_staff_take_job(e)
			elif not orders.has(job["order"]):
				e["job"] = {}
				_staff_clear_device(e)
			elif job.has("ready"):
				_staff_finish(e)
			elif on:
				job["left"] = float(job["left"]) - dm
				if float(job["left"]) <= 0.0:
					_staff_finish(e)
		elif on:
			e["timer"] = float(e.get("timer", 0.0)) - dm
			if float(e["timer"]) <= 0.0:
				e["timer"] = 4.0
				_desk_serve(e)
		_staff_label(e, on)


func _staff_finish(e: Dictionary) -> void:
	var job: Dictionary = e["job"]
	var o: Dictionary = job["order"]
	var slot := _free_shelf_slot()
	if slot < 0:
		if not job.has("ready"):
			_toast(T("%s acabou um trabalho, mas a prateleira «Prontos a entregar» está cheia!") % _first_name(e), true)
		job["ready"] = true
		return
	e["job"] = {}
	_staff_clear_device(e)
	o["quality"] = 5 if randf() < 0.45 + 0.17 * int(e["stars"]) else 4
	e["repairs"] = int(e.get("repairs", 0)) + 1
	_stat_add("staff_repairs", 1)
	_put_on_shelf(o, slot)
	_toast(T("%s terminou o pedido #%d (%s). Está na prateleira #%d.") % [_first_name(e), int(o["number"]), _dev_name(str(o["device"])), slot + 1], false, GREEN)
	if int(e["repairs"]) % 5 == 0 and int(e["repairs"]) <= 30:
		get_tree().create_timer(2.5).timeout.connect(func() -> void: _toast(T("%s ganhou experiência e está mais rápido/a!") % _first_name(e), false, YELLOW))
	_refresh_objective()
	_refresh_orders_panel()


func _desk_serve(e: Dictionary) -> void:
	if mode == "dialog":
		return
	if not cash_items.is_empty():
		_collect_cash(cash_items[0])
		return
	for oid in counter_queue.duplicate():
		var c: Node3D = customers.get(oid)
		if c == null or not is_instance_valid(c) or c.walking or not c.look_enabled:
			continue
		var purpose := str(c.get_meta("purpose", "order"))
		var o: Dictionary = c.get_meta("order", {})
		if purpose == "story" or str(o.get("story", "")) != "":
			if not c.has_meta("desk_warned"):
				c.set_meta("desk_warned", true)
				_toast(T("%s: «Está aqui alguém que quer falar contigo!»") % _first_name(e), false, YELLOW)
			continue
		if purpose == "buy":
			_sell_product(o, true)
			_toast(T("%s vendeu %s (%s).") % [_first_name(e), T(str(Data.PRODUCTS[str(o["product"])]["name"])), _eur(float(o["pay"]))], false, GREEN)
			return
		if purpose == "browse":
			continue
		if purpose == "order" and o.get("status", "") == "new":
			_accept_order(o)
			_toast(T("%s aceitou o pedido de %s (%s).") % [_first_name(e), o["customer"], _dev_name(str(o["device"]))], false, GREEN)
			return
		if purpose == "pickup" and o.get("status", "") == "shelf":
			var i := int(o.get("shelf", 0)) - 1
			if i >= 0 and i < shelf_items.size() and shelf_items[i] != null and shelf_items[i]["order"] == o:
				(shelf_items[i]["node"] as Node3D).queue_free()
				shelf_items[i] = null
			var pay := _order_payment(o)
			var gain := float(o["pay"]) + float(pay["tip"])
			_finish_order(o, pay["tip"], pay["stars"], true)
			_toast(T("%s entregou o pedido #%d e guardou %s na caixa.") % [_first_name(e), int(o["number"]), _eur(gain)], false, GREEN)
			return


func _staff_node(e: Dictionary) -> Node3D:
	var id := int(e["id"])
	if staff_nodes.has(id) and is_instance_valid(staff_nodes[id]):
		return staff_nodes[id]
	var c: Node3D = CustomerScene.new()
	var look: Dictionary = (Staff.NAMES[int(e.get("ni", 0)) % Staff.NAMES.size()][1] as Dictionary).duplicate(true)
	var ex: Array = (look.get("extras", []) as Array).duplicate()
	ex.append("apron")
	look["extras"] = ex
	look["shirt"] = Color("2c3e50") if e["role"] == "tech" else Color("8e2b2b")
	c.setup(_first_name(e), int(e.get("seed", 1)), look)
	c.role = "staff"
	add_child(c)
	c.pick.collision_layer = 0
	c.name_tag.no_depth_test = false
	c.set_mood("happy")
	c.visible = false
	staff_nodes[id] = c
	return c


func _staff_place_node(e: Dictionary, on: bool) -> void:
	var c := _staff_node(e)
	if c.visible != on:
		c.visible = on
	if not on:
		return
	if e["role"] == "tech":
		var si := int(e.get("station", 0))
		if si >= room.staff_stations.size():
			return
		var st: Dictionary = room.staff_stations[si]
		if c.global_position.distance_to(st["stand"]) > 0.05:
			c.global_position = st["stand"]
			c.rotation.y = st["yaw"]
		var job: Dictionary = e.get("job", {})
		c.working = not job.is_empty() and not job.has("ready")
	else:
		if c.global_position.distance_to(DESK_POS) > 0.05:
			c.global_position = DESK_POS
			c.rotation.y = 0.0
		c.look_enabled = true
		var tgt := cam.global_position
		if not counter_queue.is_empty():
			var fc = customers.get(counter_queue[0])
			if fc != null and is_instance_valid(fc):
				tgt = (fc as Node3D).global_position + Vector3(0, 1.5, 0)
		c.look_target = tgt


func _staff_show_device(e: Dictionary) -> void:
	_staff_clear_device(e)
	var job: Dictionary = e.get("job", {})
	if job.is_empty():
		return
	var si := int(e.get("station", 0))
	if si >= room.staff_stations.size():
		return
	var st: Dictionary = room.staff_stations[si]
	var n := _device_standin(str(job["order"]["device"]))
	add_child(n)
	n.global_position = st["top"] + Vector3(0, 0.012, 0)
	n.rotation = Vector3(0, float(st["yaw"]) + PI, 0)
	e["dev_node"] = n


func _staff_clear_device(e: Dictionary) -> void:
	var n = e.get("dev_node")
	if n != null and is_instance_valid(n):
		(n as Node3D).queue_free()
	e.erase("dev_node")


func _set_label(l: Label3D, txt: String) -> void:
	if l and l.text != txt:
		l.text = txt


func _refresh_station_labels() -> void:
	if room == null:
		return
	for i in range(room.staff_stations.size()):
		var st: Dictionary = room.staff_stations[i]
		var taken := false
		for e in staff:
			if e["role"] == "tech" and int(e.get("station", -1)) == i:
				taken = true
		if not taken:
			_set_label(st["label"], T("Bancada livre") + "\n" + T("Contrata um técnico (F)"))


func _staff_label(e: Dictionary, on: bool) -> void:
	if e["role"] != "tech":
		return
	var si := int(e.get("station", 0))
	if si >= room.staff_stations.size():
		return
	var l: Label3D = room.staff_stations[si]["label"]
	var nm := _first_name(e)
	var txt := ""
	var job: Dictionary = e.get("job", {})
	if not on:
		var sh: Dictionary = Staff.SHIFTS[str(e["shift"])]
		if minutes / 60.0 < float(sh["start"]):
			txt = nm + "\n" + T("Entra às %02d:00") % int(sh["start"])
		else:
			txt = nm + "\n" + T("Turno terminado")
	elif job.is_empty():
		txt = T("À espera de trabalho")
	elif job.has("ready"):
		txt = T("Pronto! Prateleira cheia")
	else:
		var pct := int(100.0 * (1.0 - float(job["left"]) / maxf(0.01, float(job["total"]))))
		txt = "%s #%d  •  %d%%" % [_dev_name(str(job["order"]["device"])), int(job["order"]["number"]), clampi(pct, 0, 99)]
	_set_label(l, txt)


# --- used-device market (Fix & Flip) ------------------------------------------------
func _gen_flip() -> Dictionary:
	var keys: Array = []
	for k in FAULTS.keys():
		if FAULTS[k]["device"] == "gamepad" and not bool(story_flags.get("leo", false)):
			continue
		keys.append(k)
	var fk: String = keys[randi() % keys.size()]
	var f: Dictionary = FAULTS[fk]
	var base := float(f["pay"])
	var part: String = f["part"]
	var part_cost := float(Data.PARTS[part]["price"]) if part != "" else 0.0
	var buy := snappedf(base * randf_range(0.5, 0.9) + 10.0, 5.0)
	var sell := snappedf(buy + part_cost + base * randf_range(0.8, 1.45), 5.0)
	return {"fault": fk, "device": f["device"], "buy": buy, "sell": sell, "sold": false}


func _buy_flip(i: int) -> void:
	if i < 0 or i >= flip_offers.size():
		return
	var of: Dictionary = flip_offers[i]
	var buy := float(of["buy"])
	if bool(of.get("sold", false)):
		return
	if money < buy:
		_toast(T("Dinheiro insuficiente."), true)
		return
	money -= buy
	day_profit -= buy
	of["sold"] = true
	var cust: Array = Data.CUSTOMERS[randi() % Data.CUSTOMERS.size()]
	order_seq += 1
	var o := {"id": order_seq, "number": _next_order_number(), "customer": cust[0], "color": cust[1], "device": of["device"], "fault": of["fault"],
		"complaint": "Comprado no mercado de usados. Repara e revende com lucro!", "pay": float(of["sell"]), "story": "",
		"deadline": _abs_minutes() + 6000.0, "expires": 9e9, "status": "accepted", "flip": true}
	orders.append(o)
	_sfx("cash", 0.5)
	_toast(T("Compraste um %s avariado. Repara-o e põe-no na prateleira: aparece um comprador.") % _dev_name(str(of["device"])).to_lower(), false, GREEN)
	_place_waiting_orders()
	_refresh_board()
	_refresh_orders_badge()
	_refresh_objective()


# --- daily goals + achievements -----------------------------------------------------
func _new_day_refresh() -> void:
	for oid in customers.keys():
		var cn = customers[oid]
		if is_instance_valid(cn) and str(cn.get_meta("purpose", "")) in ["browse", "buy"]:
			_customer_leave(oid, "neutral", true)
	candidates.clear()
	for r in ["tech", "tech", "desk"]:
		candidates.append(_gen_candidate(r))
	if randf() < 0.5:
		candidates.append(_gen_candidate("tech"))
	flip_offers.clear()
	for i in range(3):
		flip_offers.append(_gen_flip())
	_gen_goals()
	_stat_set("day", day)


func _gen_goals() -> void:
	daily_goals.clear()
	var pool: Array = Staff.GOALS.duplicate()
	pool.shuffle()
	for g in pool:
		if daily_goals.size() >= 3:
			break
		var kind: String = g["kind"]
		if kind == "flip" and day < 2:
			continue
		var target := randi_range(int(g["min"]), int(g["max"]))
		var reward := float(g["reward"]) * target
		var dev := ""
		if kind == "earn":
			target = int(snappedf(randf_range(float(g["min"]), float(g["max"])) * (1.0 + 0.5 * expansion), 50.0))
			reward = snappedf(target * 0.15, 5.0)
		elif kind == "device":
			var devs: Array = []
			for k in Data.DEVICES.keys():
				if k == "gamepad" and not bool(story_flags.get("leo", false)):
					continue
				devs.append(k)
			dev = devs[randi() % devs.size()]
		daily_goals.append({"kind": kind, "text": g["text"], "target": target, "progress": 0, "reward": reward, "dev": dev, "done": false})


func _goal_text(g: Dictionary) -> String:
	if int(g["target"]) == 1 and str(g["kind"]) in ["repair", "ontime", "five", "parts", "sell"]:
		for gd in Staff.GOALS:
			if gd["kind"] == g["kind"]:
				return T(str(gd["one"]))
	match str(g["kind"]):
		"earn":
			return T(str(g["text"])) % _eur(float(g["target"]))
		"device":
			return T(str(g["text"])) % _dev_name(str(g["dev"]))
	return T(str(g["text"])) % int(g["target"])


func _goal_progress(kind: String, amount: float, dev := "") -> void:
	var changed := false
	for g in daily_goals:
		if bool(g.get("done", false)) or str(g["kind"]) != kind:
			continue
		if kind == "device" and str(g["dev"]) != dev:
			continue
		g["progress"] = minf(float(g["target"]), float(g["progress"]) + amount)
		changed = true
		if float(g["progress"]) >= float(g["target"]):
			g["done"] = true
			var r := float(g["reward"])
			money += r
			day_profit += r
			_gain_xp(20)
			_sfx("cash", 0.6)
			_toast(T("Meta do dia cumprida: %s  (+%s)") % [_goal_text(g), _eur(r)], false, YELLOW)
			var all_done := true
			for g2 in daily_goals:
				if not bool(g2.get("done", false)):
					all_done = false
			if all_done:
				_stat_add("perfect_days", 1)
	_check_achievements()
	if changed:
		_refresh_objective()


func _track_delivery(o: Dictionary, stars: int) -> void:
	var flip := bool(o.get("flip", false))
	_goal_progress("repair", 1)
	if stars >= 4 and not flip:
		_goal_progress("ontime", 1)
	if stars == 5:
		_goal_progress("five", 1)
		_stat_add("five_stars", 1)
	_goal_progress("device", 1, str(o["device"]))
	if flip:
		_goal_progress("flip", 1)
		_stat_add("flips", 1)
	if bool(o.get("vip", false)):
		_stat_add("vips", 1)
	var types: Array = stats.get("types", [])
	if not types.has(str(o["device"])):
		types.append(str(o["device"]))
	stats["types"] = types
	stats["device_types"] = types.size()
	_stat_add("repairs", 1)


func _stat_add(k: String, n: float) -> void:
	stats[k] = float(stats.get(k, 0.0)) + n
	_check_achievements()


func _stat_set(k: String, v: float) -> void:
	stats[k] = maxf(float(stats.get(k, 0.0)), v)
	_check_achievements()


func _stat_value(k: String) -> float:
	if k == "money":
		return money
	return float(stats.get(k, 0.0))


func _check_achievements() -> void:
	for id in Staff.ACHIEVEMENTS.keys():
		if achievements.has(id):
			continue
		var a: Dictionary = Staff.ACHIEVEMENTS[id]
		if _stat_value(str(a["stat"])) >= float(a["target"]):
			achievements[id] = day
			var r := float(a["reward"])
			money += r
			_gain_xp(30)
			_sfx("cash", 0.7)
			_toast(T("Conquista desbloqueada: %s!") % T(str(a["name"])) + ("  (+%s)" % _eur(r) if r > 0.0 else ""), false, YELLOW)


# --- boards -------------------------------------------------------------------------
func _card() -> PanelContainer:
	var card := _panel(Color(0.07, 0.11, 0.17, 1.0), 12, Vector4(14, 10, 14, 10))
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	return card


func _section(text: String) -> void:
	board_box.add_child(_label(text, 19, YELLOW, font_xbold))


func _skill_bar(value: float) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(90, 10)
	var v := clampf((value - 0.5) / 1.6, 0.05, 1.0)
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(0, 1, 90, 8), Color(0.15, 0.2, 0.28))
		bar.draw_rect(Rect2(0, 1, 90 * v, 8), GREEN if value >= 1.4 else (YELLOW if value >= 1.0 else Color("e67e22"))))
	return bar


func _person_card(e: Dictionary, hired: bool, idx: int) -> PanelContainer:
	var card := _card()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	card.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	h.add_child(info)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(_label(str(e["name"]), 18, TEXT, font_xbold))
	top.add_child(_label(T(str(Staff.ROLES[e["role"]]["name"])), 14, Color("8fd8ff"), font_xbold))
	top.add_child(_label("★".repeat(int(e["stars"])) + "☆".repeat(3 - int(e["stars"])), 15, YELLOW))
	info.add_child(top)
	info.add_child(_label(T("Horário: %s   •   Salário: %s/dia") % [_shift_text(str(e["shift"])), _eur(float(e["wage"]))], 14, MUTED))
	if e["role"] == "tech":
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 2)
		var sk: Dictionary = e.get("skills", {})
		for k in Staff.CATEGORIES.keys():
			grid.add_child(_label(T(str(Staff.CATEGORIES[k]["name"])), 13, Color("c7d3df")))
			var bb := CenterContainer.new()
			bb.add_child(_skill_bar(float(sk.get(k, 1.0))))
			grid.add_child(bb)
		info.add_child(grid)
	else:
		var dl := _label(T(str(Staff.ROLES["desk"]["desc"])), 13, Color("c7d3df"))
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(560, 0)
		info.add_child(dl)
	if hired:
		var status := ""
		var on := _on_shift(e)
		var job: Dictionary = e.get("job", {})
		if not on:
			status = T("Fora de horário")
		elif e["role"] == "desk":
			status = T("No balcão")
		elif job.is_empty():
			status = T("À espera de trabalho")
		else:
			status = T("A reparar: %s #%d") % [_dev_name(str(job["order"]["device"])), int(job["order"]["number"])]
		info.add_child(_label(T("Estado: %s   •   Reparações feitas: %d") % [status, int(e.get("repairs", 0))], 13, GREEN if on else MUTED))
		var fire := _small_button(T("Despedir"), false)
		fire.custom_minimum_size = Vector2(120, 36)
		fire.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var id := int(e["id"])
		fire.pressed.connect(func() -> void: _fire(id))
		h.add_child(fire)
	else:
		var hire := _small_button(T("Contratar"), true)
		hire.custom_minimum_size = Vector2(130, 36)
		var can := true
		if e["role"] == "tech":
			can = _free_station() >= 0
		else:
			for s2 in staff:
				if s2["role"] == "desk":
					can = false
		hire.disabled = not can
		hire.pressed.connect(func() -> void: _hire(idx))
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_child(hire)
		if not can:
			vb.add_child(_label(T("Sem bancada livre") if e["role"] == "tech" else T("Já tens um"), 12, MUTED))
		h.add_child(vb)
	return card


func _fill_team() -> void:
	# expansion
	_section(T("Expansão da loja"))
	if expansion < Staff.EXPANSIONS.size():
		var ex: Dictionary = Staff.EXPANSIONS[expansion]
		var card := _card()
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		card.add_child(h)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(T(str(ex["name"])) + "  (%d/%d)" % [expansion + 1, Staff.EXPANSIONS.size()], 18, TEXT, font_xbold))
		var dl := _label(T(str(ex["desc"])), 14, MUTED)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(600, 0)
		info.add_child(dl)
		h.add_child(info)
		var buy := _small_button("%s  %s" % [T("Comprar"), _eur(float(ex["price"]))], true)
		buy.custom_minimum_size = Vector2(170, 38)
		buy.disabled = money < float(ex["price"])
		buy.pressed.connect(_buy_expansion)
		h.add_child(buy)
		board_box.add_child(card)
	else:
		board_box.add_child(_label(T("A loja está totalmente ampliada: 4 bancadas no anexo e 8 lugares na prateleira."), 15, GREEN))
	var free := _stations_available() - _tech_count()
	board_box.add_child(_label(T("Bancadas para técnicos: %d (livres: %d)   •   Pedidos abertos ao mesmo tempo: até %d") % [_stations_available(), maxi(0, free), _max_open_orders()], 14, MUTED))
	var tg := CheckButton.new()
	tg.text = T("Dar os trabalhos novos primeiro à equipa (desliga para seres tu a reparar primeiro)")
	tg.button_pressed = staff_first
	tg.focus_mode = Control.FOCUS_NONE
	tg.add_theme_font_size_override("font_size", 14)
	tg.toggled.connect(func(on: bool) -> void:
		staff_first = on
		if on:
			_staff_assign_all())
	board_box.add_child(tg)
	# team
	_section(T("A tua equipa (%d)") % staff.size())
	if staff.is_empty():
		board_box.add_child(_label(T("Ainda trabalhas sozinho/a. Contrata um balconista para atender o balcão, ou compra o anexo para teres técnicos."), 15, MUTED))
	else:
		var wages := 0.0
		for e in staff:
			wages += float(e["wage"])
			board_box.add_child(_person_card(e, true, -1))
		board_box.add_child(_label(T("Salários: %s por dia (pagos ao fechar a loja)") % _eur(wages), 14, Color("ffb4a8")))
	# candidates
	_section(T("Candidatos de hoje"))
	board_box.add_child(_label(T("Cada técnico é mais rápido em certos equipamentos. Novos candidatos todas as manhãs."), 14, MUTED))
	if candidates.is_empty():
		board_box.add_child(_label(T("Não há mais candidatos hoje."), 15, MUTED))
	for i in range(candidates.size()):
		board_box.add_child(_person_card(candidates[i], false, i))


func _fill_used() -> void:
	_section(T("Loja online: produtos novos para o expositor"))
	board_box.add_child(_label(T("Encomenda caixas de %d unidades. Chegam pelo carteiro; ao abrir a caixa vão para o expositor (junto à montra). Os clientes compram e pagam no balcão.") % Data.PACK, 14, MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	board_box.add_child(grid)
	for key in Data.PRODUCTS.keys():
		var pr: Dictionary = Data.PRODUCTS[key]
		var card := _card()
		card.custom_minimum_size = Vector2(465, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		var sw := ColorRect.new()
		sw.color = pr["band"]
		sw.custom_minimum_size = Vector2(10, 46)
		h.add_child(sw)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(T(str(pr["name"])), 16, TEXT, font_xbold))
		var on_stand := 0
		for it in stand_items:
			if it != null and it["key"] == key:
				on_stand += int(it["qty"])
		info.add_child(_label(T("Custo %s  •  Venda %s  •  Expositor %d / Armazém %d") % [_eur(float(pr["buy"])), _eur(float(pr["sell"])), on_stand, int(retail_stock.get(key, 0))], 13, MUTED))
		h.add_child(info)
		var cost := float(pr["buy"]) * Data.PACK
		var b := _small_button("%d× %s" % [Data.PACK, _eur(cost)], true)
		b.custom_minimum_size = Vector2(120, 36)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = money < cost
		var kk: String = key
		b.pressed.connect(func() -> void: _buy_product(kk))
		h.add_child(b)
		grid.add_child(card)
	_section(T("Usados para reparar e revender"))
	board_box.add_child(_label(T("Fix & Flip: compra equipamentos avariados, repara-os e põe-nos na prateleira. Aparece um comprador e pagas-te com lucro."), 15, MUTED))
	for i in range(flip_offers.size()):
		var of: Dictionary = flip_offers[i]
		var f: Dictionary = FAULTS[of["fault"]]
		var card := _card()
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		card.add_child(h)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label("%s  •  %s" % [_dev_name(str(of["device"])), T(str(f["fault"]))], 18, TEXT, font_xbold))
		var part: String = f["part"]
		var part_txt := T("Não precisa de peças") if part == "" else T("Precisa de: %s (em stock: %d)") % [T(str(Data.PARTS[part]["name"])), int(inventory.get(part, 0))]
		info.add_child(_label(T("Compra: %s   •   Venda prevista: %s   •   %s") % [_eur(float(of["buy"])), _eur(float(of["sell"])), part_txt], 14, MUTED))
		var profit := float(of["sell"]) - float(of["buy"]) - (float(Data.PARTS[part]["price"]) if part != "" else 0.0)
		info.add_child(_label(T("Lucro estimado: %s") % _eur(profit), 14, GREEN))
		h.add_child(info)
		if bool(of.get("sold", false)):
			h.add_child(_label(T("Comprado ✓"), 16, GREEN, font_xbold))
		else:
			var buy := _small_button("%s  %s" % [T("Comprar"), _eur(float(of["buy"]))], true)
			buy.custom_minimum_size = Vector2(170, 38)
			buy.disabled = money < float(of["buy"]) or _open_orders() >= _max_open_orders() + 2
			var k := i
			buy.pressed.connect(func() -> void: _buy_flip(k))
			h.add_child(buy)
		board_box.add_child(card)
	board_box.add_child(_label(T("Novas ofertas todas as manhãs."), 14, MUTED))


func _fill_goals() -> void:
	_section(T("Metas do Dia %d") % day)
	for g in daily_goals:
		var card := _card()
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		card.add_child(h)
		var done := bool(g.get("done", false))
		h.add_child(_icon("box_active" if done else "box", 22))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(_goal_text(g), 17, GREEN if done else TEXT, font_xbold))
		var pb := ProgressBar.new()
		pb.max_value = float(g["target"])
		pb.value = float(g["progress"])
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(300, 8)
		info.add_child(pb)
		h.add_child(info)
		var prog := "%s / %s" % [_eur(float(g["progress"])), _eur(float(g["target"]))] if str(g["kind"]) == "earn" else "%d / %d" % [int(g["progress"]), int(g["target"])]
		h.add_child(_label(prog, 15, MUTED))
		h.add_child(_label("+" + _eur(float(g["reward"])), 16, YELLOW, font_xbold))
		board_box.add_child(card)
	_section(T("Conquistas (%d/%d)") % [achievements.size(), Staff.ACHIEVEMENTS.size()])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	board_box.add_child(grid)
	for id in Staff.ACHIEVEMENTS.keys():
		var a: Dictionary = Staff.ACHIEVEMENTS[id]
		var got := achievements.has(id)
		var card := _card()
		card.custom_minimum_size = Vector2(460, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		h.add_child(_icon("star" if got else "box", 24))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(T(str(a["name"])), 16, YELLOW if got else TEXT, font_xbold))
		var cur := minf(_stat_value(str(a["stat"])), float(a["target"]))
		var desc := T(str(a["desc"]))
		if not got:
			desc += "  (%d/%d)" % [int(cur), int(a["target"])]
		info.add_child(_label(desc, 13, MUTED))
		h.add_child(info)
		grid.add_child(card)


# --- handing work to a technician ------------------------------------------------
func _idle_techs() -> Array:
	var out: Array = []
	for e in staff:
		if e["role"] == "tech" and (e.get("job", {}) as Dictionary).is_empty() and _on_shift(e):
			out.append(e)
	return out


func _bench_id(o: Dictionary) -> String:
	for id in jobs.keys():
		if jobs[id]["order"] == o:
			return id
	return ""


func _delegate_best(o: Dictionary) -> void:
	var idle := _idle_techs()
	if idle.is_empty():
		_toast(T("Nenhum técnico livre agora (vê os turnos na Equipa, tecla F)."), true)
		return
	var best: Dictionary = idle[0]
	for e in idle:
		if _staff_speed(e, str(o["device"])) > _staff_speed(best, str(o["device"])):
			best = e
	_delegate_order(o, best)


func _delegate_order(o: Dictionary, e: Dictionary) -> void:
	if str(o.get("story", "")) != "":
		_toast(T("Este trabalho é especial: tens de ser tu a fazê-lo."), true)
		return
	if not (e.get("job", {}) as Dictionary).is_empty() or not _on_shift(e):
		_toast(T("%s não está disponível agora.") % _first_name(e), true)
		return
	var f: Dictionary = FAULTS[o["fault"]]
	var steps: Array = f["steps"]
	var part: String = f["part"]
	var remaining := steps.size()
	var need_part := part != ""
	var id := _bench_id(o)
	if id != "":
		if jobs[id]["done"]:
			_toast(T("Já está reparado: leva-o à prateleira."), true)
			return
		var st := int(jobs[id]["step"])
		remaining = maxi(1, steps.size() - st)
		if need_part:
			var install_i := -1
			for i in range(steps.size()):
				if str(steps[i].get("act", "")) in ["install_part", "install_screen"]:
					install_i = i
			var d: Node3D = devices[id]
			if st > install_i or (d.has_method("has_new_part") and d.has_new_part(part)):
				need_part = false
	if need_part and int(inventory.get(part, 0)) <= 0:
		_toast(T("Falta a peça: %s. Compra-a na Loja (L).") % T(Data.PARTS[part]["name"]), true)
		return
	if need_part:
		inventory[part] = int(inventory.get(part, 0)) - 1
	if id != "":
		if mode in ["inspect", "popup"] and active_device == id:
			_exit_inspect_forced()
		var dn: Node3D = devices[id]
		devices.erase(id)
		jobs.erase(id)
		dn.queue_free()
		if focus_job == id:
			focus_job = ""
	o["status"] = "staff"
	o["staff"] = e["id"]
	var total := float(remaining) * 3.5 / _staff_speed(e, str(o["device"]))
	e["job"] = {"order": o, "left": total, "total": total}
	_staff_show_device(e)
	_sfx("pickup")
	_toast(T("Passaste o pedido #%d (%s) a %s. Fica pronto daqui a ~%d min.") % [int(o["number"]), _dev_name(str(o["device"])), _first_name(e), int(ceil(total))], false, GREEN)
	_place_waiting_orders()
	_refresh_orders_panel()
	_refresh_objective()


## Things can be put anywhere inside the rooms the player can reach (not outside the walls).
func _place_ok(p: Vector3) -> bool:
	var in_shop := p.x > -2.6 and p.x < 2.6 and p.z > -1.75 and p.z < 2.6
	var in_back := p.x > -4.65 and p.x < -2.7 and p.z > -1.75 and p.z < 0.6
	var in_annex := expansion >= 1 and p.x > 2.6 and p.x < 5.8 and p.z > -1.75 and p.z < 1.5
	return in_shop or in_back or in_annex


# --- new products + display stand -------------------------------------------------
func _item_name(key: String) -> String:
	if key.begins_with("prod:"):
		return "%d× %s" % [Data.PACK, T(str(Data.PRODUCTS[key.substr(5)]["name"]))]
	return T(str(Data.PARTS[key]["name"]))


func _buy_product(key: String) -> void:
	var cost := float(Data.PRODUCTS[key]["buy"]) * Data.PACK
	if money < cost:
		_toast(T("Dinheiro insuficiente."), true)
		return
	money -= cost
	day_profit -= cost
	var eta := randf_range(15.0, 30.0)
	deliveries.append({"key": "prod:" + key, "arrive": _abs_minutes() + eta})
	_sfx("cash", 0.5)
	_toast(T("Encomenda feita: %s. Chega à receção dentro de ~%d min.") % [_item_name("prod:" + key), int(eta)], false, GREEN)
	_refresh_board()


func _open_product_parcel(item: Dictionary) -> void:
	var key := str(item["key"]).substr(5)
	var n: Node3D = item["node"]
	(item["body"] as StaticBody3D).collision_layer = 0
	var t := create_tween()
	t.tween_property(n, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
	t.tween_callback(n.queue_free)
	var placed := _stand_add(key, Data.PACK)
	if placed < Data.PACK:
		retail_stock[key] = int(retail_stock.get(key, 0)) + Data.PACK - placed
	_sfx("part", 0.7)
	_toast(T("%s: %d no expositor, %d no armazém.") % [T(str(Data.PRODUCTS[key]["name"])), placed, Data.PACK - placed], false, GREEN)
	_goal_progress("parts", 1)
	_refresh_objective()


func _stand_count() -> int:
	var n := 0
	for it in stand_items:
		if it != null:
			n += int(it["qty"])
	return n


func _stand_clear() -> void:
	for it in stand_items:
		if it != null and is_instance_valid(it["node"]):
			(it["node"] as Node3D).queue_free()
	stand_items = []
	for i in range(room.stand_slots.size()):
		stand_items.append(null)


func _stand_set(i: int, key: String, qty: int) -> void:
	var it = stand_items[i]
	if it != null and is_instance_valid(it["node"]):
		(it["node"] as Node3D).queue_free()
	if qty <= 0:
		stand_items[i] = null
		return
	var n := Node3D.new()
	add_child(n)
	n.global_position = room.stand_slots[i]
	n.rotation.y = PI
	var size: Vector3 = Data.PRODUCTS[key]["size"]
	for u in range(qty):
		var m := _product_model(key)
		m.scale = Vector3.ONE * 1.25
		m.position = Vector3((u % 2) * 0.04 - 0.02, 0, -float(u) * (size.z * 1.25 + 0.012) + 0.07)
		n.add_child(m)
	var tag := Label3D.new()
	tag.text = _eur(float(Data.PRODUCTS[key]["sell"]))
	tag.font_size = 30
	tag.pixel_size = 0.0008
	tag.modulate = Color("27ae60")
	tag.outline_size = 6
	tag.position = Vector3(0, 0.012, 0.15)
	tag.rotation_degrees = Vector3(-60, 0, 0)
	n.add_child(tag)
	stand_items[i] = {"key": key, "qty": qty, "node": n}


func _stand_add(key: String, qty: int) -> int:
	var placed := 0
	for i in range(stand_items.size()):
		var it = stand_items[i]
		if it != null and it["key"] == key and int(it["qty"]) < 3 and placed < qty:
			var add := mini(3 - int(it["qty"]), qty - placed)
			_stand_set(i, key, int(it["qty"]) + add)
			placed += add
	for i in range(stand_items.size()):
		if stand_items[i] == null and placed < qty:
			var add2 := mini(3, qty - placed)
			_stand_set(i, key, add2)
			placed += add2
	return placed


func _stand_restock() -> void:
	var moved := 0
	for k in retail_stock.keys():
		var n := int(retail_stock[k])
		if n <= 0:
			continue
		var placed := _stand_add(k, n)
		retail_stock[k] = n - placed
		moved += placed
	for k in retail_stock.keys().duplicate():
		if int(retail_stock[k]) <= 0:
			retail_stock.erase(k)
	if moved > 0:
		_sfx("part", 0.6)
		_toast(T("Puseste %d produtos no expositor.") % moved, false, GREEN)
		_save_game()
	else:
		_open_board("used")


func _stand_take_random() -> String:
	var opts: Array = []
	for i in range(stand_items.size()):
		if stand_items[i] != null and int(stand_items[i]["qty"]) > 0:
			opts.append(i)
	if opts.is_empty():
		return ""
	var i: int = opts[randi() % opts.size()]
	var key: String = stand_items[i]["key"]
	_stand_set(i, key, int(stand_items[i]["qty"]) - 1)
	return key


func _product_model(key: String) -> Node3D:
	var pr: Dictionary = Data.PRODUCTS[key]
	var size: Vector3 = pr["size"]
	var n := Node3D.new()
	Kit.slab(n, Vector3(size.x, size.z, size.y), 0.006, 0.002, Kit.plastic(pr["color"], 0.35), null, null, Vector3(0, size.y * 0.5, 0), Vector3(90, 0, 0))
	Kit.box(n, Vector3(size.x + 0.002, size.y * 0.22, size.z + 0.002), Kit.plastic(pr["band"], 0.4), Vector3(0, size.y * 0.25, 0))
	Kit.box(n, Vector3(size.x * 0.7, size.y * 0.38, 0.002), Kit.mat(Color("f5f6fa"), 0.5), Vector3(0, size.y * 0.66, size.z * 0.5 + 0.001))
	Kit.cyl(n, size.x * 0.17, 0.003, Kit.plastic(pr["band"], 0.3), Vector3(0, size.y * 0.66, size.z * 0.5 + 0.003), Vector3(90, 0, 0))
	return n


func _shopper_tick() -> void:
	var now := _abs_minutes()
	if now < shopper_next or minutes >= 19 * 60 or _stand_count() == 0:
		return
	var shoppers := 0
	for cn in customers.values():
		if is_instance_valid(cn) and str(cn.get_meta("purpose", "")) in ["browse", "buy"]:
			shoppers += 1
	shopper_next = now + randf_range(35.0, 90.0) / clampf(_reputation() / 4.0, 0.7, 1.3) / (1.25 if upgrades.has("display") else 1.0)
	if shoppers >= 2:
		return
	_spawn_shopper()


func _spawn_shopper() -> void:
	order_seq += 1
	var cust: Array = Data.CUSTOMERS[randi() % Data.CUSTOMERS.size()]
	var o := {"id": order_seq, "customer": cust[0], "color": cust[1]}
	var c: Node3D = CustomerScene.new()
	c.setup(str(cust[0]), randi() % 100000, {})
	c.order_id = order_seq
	c.set_meta("purpose", "browse")
	c.set_meta("order", o)
	add_child(c)
	c.global_position = DOOR_OUT
	customers[order_seq] = c
	room.open_door()
	_sfx("door_chime", 0.6)
	var oid: int = order_seq
	c.walk_path([DOOR_IN, Vector3(-0.55, 0, 2.08), Room.STAND_BROWSE], func() -> void:
		c.rotation.y = 0.0
		get_tree().create_timer(randf_range(3.0, 6.0)).timeout.connect(func() -> void:
			if not is_instance_valid(c) or not customers.has(oid):
				return
			var key := _stand_take_random()
			if key == "":
				_customer_leave(oid, "sad")
				return
			o["product"] = key
			o["pay"] = float(Data.PRODUCTS[key]["sell"])
			c.hold(_product_model(key))
			c.set_meta("purpose", "buy")
			c.set_mood("happy")
			counter_queue.append(oid)
			c.walk_path([Vector3(-0.55, 0, 2.08), _queue_spot(counter_queue.size() - 1)], func() -> void:
				c.rotation.y = PI
				c.look_enabled = true
				c.set_bubble("buy"))
			_toast(T("%s quer comprar %s. Vai ao balcão!") % [o["customer"], T(str(Data.PRODUCTS[key]["name"]))], false, YELLOW)))


func _sell_product(o: Dictionary, auto: bool) -> void:
	var oid := int(o["id"])
	var c: Node3D = customers.get(oid)
	var gain := float(o.get("pay", 0.0))
	if auto:
		money += gain
		day_profit += gain
		room.ring_register(_eur(gain))
		_sfx("cash", 0.8)
		_goal_progress("earn", gain)
	else:
		_spawn_cash(gain, c.global_position if c else Vector3(0.6, 0, 2.0))
	_goal_progress("sell", 1)
	_stat_add("sold", 1)
	_customer_leave(oid, "happy")
	_refresh_objective()


func _upgrades_pos_save() -> Dictionary:
	var out := {}
	for uid in room.upgrade_nodes.keys():
		var n = room.upgrade_nodes[uid]
		if is_instance_valid(n) and uid != "lamp":
			out[uid] = _xf_array((n as Node3D).global_transform)
	return out
