extends Node3D

const SAVE_PATH := "user://fix_flip_3d.json"
const TEAL := Color("67E0C5")
const WHITE := Color("E8F1F8")
const INK := Color("0D1824")
const WOOD := Color("A66F48")
const METAL := Color("536879")
const BLACK := Color("1B2632")
const ERROR := Color("ED6D60")
const GOLD := Color("E9B86E")
const SOFT_BLUE := Color("27485F")
const WARM := Color("FFE2B1")

var mode := "menu"
# 0 screws, 1 cover, 2 clean, 3 battery out, 4 install new battery, 5 test power, 6 repaired
var current_step := 0
var screws_left := 4
var dust_left := 8
var balance := 250
var profit := 0
var fixed_count := 0
var inventory_cost := 52
var part_cost := 25
var captured := false
var mouse_sensitivity := 0.0025
var walk_yaw := 0.0
var walk_pitch := -0.14
var drag_rotating := false
var workbench_pos := Vector3(0, 1.0, -1.0)
var scene_camera: Camera3D
var inspection_pivot: Node3D
var laptop_root: Node3D
var cover_node: Node3D
var battery_node: Node3D
var dust_node: Node3D
var test_point_node: Node3D
var screws: Array = []
var removed_screw_ids: Array[int] = []
var instruction_text := ""
var click_hold_id := -1
var info_label: Label
var task_label: Label
var stats_label: Label
var hint_label: Label
var cursor_label: Label
var steps_label: Label
var style_hint_label: Label
var brush_active := false
var selected_tool := "none"
var tool_order := ["screwdriver", "brush", "tester"]
var tool_index := 0
var screwdriver_prop: StaticBody3D
var brush_prop: StaticBody3D
var tester_prop: StaticBody3D
var new_battery_prop: StaticBody3D
var packing_prop: StaticBody3D
var hand_root: Node3D
var menu_root: Control
var intro_root: Control
var pause_root: Control
var game_hud: Control
var hover_label: Label
var tool_label: Label
var brush_accumulator := 0.0
var dynamic_root: Node3D
var tool_selector_root: Control
var style_board_root: Control
var tool_cards: Dictionary = {}
var selector_help: Label
var screw_markers: Array = []
var cover_marker: MeshInstance3D
var battery_marker: MeshInstance3D
var dust_marker: MeshInstance3D
var test_marker: MeshInstance3D
var new_battery_marker: MeshInstance3D
var sell_marker: MeshInstance3D

func _ready() -> void:
    _load_progress()
    _build_environment()
    _build_workshop()
    _build_laptop()
    _build_ui()
    _update_ui()
    _show_main_menu()

func _process(delta: float) -> void:
    if mode == "walk":
        var direction := Vector3.ZERO
        if Input.is_key_pressed(KEY_W): direction.z -= 1.0
        if Input.is_key_pressed(KEY_S): direction.z += 1.0
        if Input.is_key_pressed(KEY_A): direction.x -= 1.0
        if Input.is_key_pressed(KEY_D): direction.x += 1.0
        if direction.length() > 0.0:
            direction = direction.normalized().rotated(Vector3.UP, walk_yaw)
            scene_camera.position += direction * delta * 3.0
            scene_camera.position.x = clampf(scene_camera.position.x, -3.6, 3.6)
            scene_camera.position.z = clampf(scene_camera.position.z, -3.2, 3.8)
            if scene_camera.position.z < 1.02 and abs(scene_camera.position.x) < 2.15:
                scene_camera.position.z = 1.02
            scene_camera.position.y = 1.7
        if Input.is_key_pressed(KEY_E) and scene_camera.position.distance_to(Vector3(0, 1.7, 0.0)) < 4.8:
            _enter_inspect()
    elif mode == "inspect" and selected_tool == "brush" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        brush_accumulator += delta
        if brush_accumulator >= 0.22:
            brush_accumulator = 0.0
            _brush_at_mouse()

    if mode == "inspect":
        _update_hover()
        _update_hand(delta)

func _unhandled_input(event: InputEvent) -> void:
    if mode in ["menu", "intro", "pause"]:
        if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and mode == "pause":
            _resume_game()
        return

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            if tool_selector_root.visible:
                _toggle_tool_selector(false)
            elif style_board_root.visible:
                style_board_root.hide()
                _set_interaction_capture_for_mode()
            elif mode == "inspect":
                _enter_walk()
            else:
                _pause_game()
        elif event.keycode == KEY_Q and mode == "inspect":
            _equip_tool("none")
        elif event.keycode == KEY_R and mode == "inspect":
            inspection_pivot.rotation = Vector3.ZERO
            info_label.text = "Rotação reposta."
        elif event.keycode == KEY_E and mode == "walk":
            _enter_inspect()
        elif event.keycode == KEY_TAB and mode == "inspect":
            _toggle_tool_selector(not tool_selector_root.visible)
        elif event.keycode == KEY_1 and mode == "inspect":
            _equip_tool("screwdriver")
        elif event.keycode == KEY_2 and mode == "inspect":
            _equip_tool("brush")
        elif event.keycode == KEY_3 and mode == "inspect":
            _equip_tool("tester")
        elif event.keycode == KEY_F1:
            style_board_root.visible = not style_board_root.visible
            _set_interaction_capture_for_mode()

    if event is InputEventMouseMotion:
        if mode == "walk" and captured:
            walk_yaw -= event.relative.x * mouse_sensitivity
            walk_pitch = clampf(walk_pitch - event.relative.y * mouse_sensitivity, -1.25, 1.15)
            _point_camera()
        elif mode == "inspect" and drag_rotating and not tool_selector_root.visible:
            inspection_pivot.rotation.y += event.relative.x * 0.009
            inspection_pivot.rotation.x = clampf(inspection_pivot.rotation.x + event.relative.y * 0.007, -0.7, 0.7)
    if event is InputEventMouseButton and mode == "inspect" and not tool_selector_root.visible:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            drag_rotating = event.pressed
        elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not tool_selector_root.visible:
            if selected_tool == "brush" and current_step == 2:
                brush_accumulator = 0.0
                _brush_at_mouse()
            else:
                _click_part()

func _set_interaction_capture_for_mode() -> void:
    if mode == "walk":
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        captured = true
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        captured = false

func _point_camera() -> void:
    scene_camera.rotation = Vector3(walk_pitch, walk_yaw, 0)

func _material(c: Color, roughness := 0.65, metallic := 0.0, glow := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = roughness
    m.metallic = metallic
    if glow:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 1.1
    return m

func _pbr_material(name: String, roughness_value: float, metallic_value: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.albedo_texture = load("res://assets/%s.png" % name)
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    mat.roughness = roughness_value
    mat.metallic = metallic_value
    mat.uv1_triplanar = true
    mat.uv1_world_triplanar = false
    mat.normal_enabled = true
    mat.normal_scale = 0.42
    mat.normal_texture = load("res://assets/%s_normal.png" % name)
    mat.roughness_texture = load("res://assets/%s_rough.png" % name)
    mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
    return mat

func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color, roughness := 0.7, metallic := 0.0, glow := false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    var mat := _material(color, roughness, metallic, glow)
    if name.contains("Workbench") or name.contains("Shelf plank") or name.contains("Front fascia") or name.contains("Desk edge"):
        mat = _pbr_material("walnut_pbr", 0.63, 0.02)
        mat.uv1_scale = Vector3(0.9, 0.9, 0.9)
    elif name.contains("floor"):
        mat = _pbr_material("concrete_pbr", 0.88, 0.0)
        mat.uv1_scale = Vector3(1.4, 1.4, 1.4)
    elif name.contains("wall") or name.contains("wall"):
        mat = _pbr_material("wall_pbr", 0.79, 0.0)
        mat.uv1_scale = Vector3(1.5, 1.5, 1.5)
    elif name.contains("Desk mat"):
        mat = _pbr_material("mat_pbr", 0.90, 0.0)
        mat.uv1_scale = Vector3(1, 1, 1)
    elif name.contains("Laptop lower chassis") or name.contains("Palmrest") or name.contains("Laptop hinge") or name.contains("Desk leg") or name.contains("Steel"):
        mat = _pbr_material("aluminium_pbr", 0.33, 0.73)
        mat.uv1_scale = Vector3(1.8, 1.8, 1.8)
    elif name.contains("Screen housing") or name.contains("Keyboard frame") or name.contains("Rubber foot") or name.contains("Tool handle"):
        mat = _pbr_material("polymer_pbr", 0.77, 0.05)
    node.material_override = mat
    parent.add_child(node)
    return node

func _cylinder(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, color: Color, glow := false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    n.mesh = mesh
    n.position = pos
    n.material_override = _material(color, 0.4, 0.5, glow)
    parent.add_child(n)
    return n

func _sphere(parent: Node3D, name: String, pos: Vector3, radius: float, color: Color, glow := false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    n.mesh = mesh
    n.position = pos
    n.material_override = _material(color, 0.45, 0.15, glow)
    parent.add_child(n)
    return n

func _marker_disc(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
    var marker := MeshInstance3D.new()
    marker.name = "Marker"
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = 0.008
    marker.mesh = mesh
    marker.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 1.2
    mat.roughness = 0.2
    marker.material_override = mat
    parent.add_child(marker)
    return marker

func _clickable(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color, kind: String) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = name
    body.position = pos
    body.set_meta("part_kind", kind)
    parent.add_child(body)
    _box(body, "Visual", Vector3.ZERO, size, color, 0.35, 0.35)
    var shape := CollisionShape3D.new()
    var boxshape := BoxShape3D.new()
    boxshape.size = size
    shape.shape = boxshape
    body.add_child(shape)
    return body

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color("0A1623")
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color("9FC2E4")
    world.environment.ambient_light_energy = 0.32
    world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment.glow_enabled = true
    world.environment.glow_bloom = 0.10
    world.environment.ssao_enabled = false
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-43, 32, 0)
    sun.light_energy = 1.55
    sun.shadow_enabled = true
    sun.light_color = WARM
    add_child(sun)

    var warm_lamp := OmniLight3D.new()
    warm_lamp.position = Vector3(0.2, 2.35, -1.0)
    warm_lamp.light_color = Color("FFD89D")
    warm_lamp.light_energy = 1.8
    warm_lamp.shadow_enabled = true
    warm_lamp.omni_range = 7.5
    add_child(warm_lamp)

    var teal_fill := OmniLight3D.new()
    teal_fill.position = Vector3(-2.8, 2.3, -3.8)
    teal_fill.light_color = Color("57E6E4")
    teal_fill.light_energy = 0.9
    teal_fill.omni_range = 10.0
    add_child(teal_fill)

    scene_camera = Camera3D.new()
    scene_camera.current = true
    scene_camera.fov = 66.0
    add_child(scene_camera)

func _build_workshop() -> void:
    _box(self, "Concrete floor", Vector3(0, -0.12, 0), Vector3(9, 0.24, 10), Color("3C505F"))
    _box(self, "Rear wall", Vector3(0, 2, -5), Vector3(9, 4.2, 0.18), Color("233646"))
    _box(self, "Left wall", Vector3(-4.5, 2, 0), Vector3(0.18, 4.2, 10), Color("2D4353"))
    _box(self, "Right wall", Vector3(4.5, 2, 0), Vector3(0.18, 4.2, 10), Color("2D4353"))
    _box(self, "Ceiling", Vector3(0, 4.1, 0), Vector3(9, 0.18, 10), Color("22313E"))

    # window and sunlight ambience
    _box(self, "Window frame", Vector3(2.65, 2.35, -4.80), Vector3(2.2, 1.7, 0.08), Color("1A2632"))
    _box(self, "Window glow", Vector3(2.65, 2.35, -4.75), Vector3(1.95, 1.45, 0.01), Color("6B9BBA"), 0.4, 0.0, false)
    for x in [-0.64, 0.0, 0.64]:
        _box(self, "Window mullion", Vector3(2.65 + x, 2.35, -4.73), Vector3(0.05, 1.45, 0.02), Color("263847"))
    for y in [-0.48, 0.0, 0.48]:
        _box(self, "Window cross", Vector3(2.65, 2.35 + y, -4.73), Vector3(1.95, 0.05, 0.02), Color("263847"))

    # big warm wood bench like concept art
    _box(self, "Workbench tabletop", Vector3(0, 0.86, -1.0), Vector3(3.65, 0.14, 1.95), Color("B98257"), 0.82)
    for x in [-1.56, 1.56]:
        for z in [-1.72, -0.28]:
            _box(self, "Steel desk leg", Vector3(x, 0.39, z), Vector3(0.10, 0.78, 0.10), METAL, 0.35, 0.75)
    _box(self, "Desk mat", Vector3(0, 0.948, -1.10), Vector3(2.42, 0.012, 1.28), Color("274E57"))
    _box(self, "Front fascia", Vector3(0, 0.76, -0.03), Vector3(3.55, 0.07, 0.1), Color("91603C"), 0.8)

    # wall storage and shelves
    _box(self, "Pegboard", Vector3(0.15, 2.08, -4.84), Vector3(3.55, 1.55, 0.10), Color("435B68"))
    for row in range(5):
        for col in range(11):
            _sphere(self, "Peg hole", Vector3(-1.42 + col * 0.29, 1.49 + row * 0.28, -4.78), 0.018, Color("18232C"))

    _box(self, "Shelf plank L1", Vector3(-2.95, 2.55, -3.95), Vector3(1.85, 0.09, 0.45), WOOD)
    _box(self, "Shelf plank L2", Vector3(-2.95, 1.90, -3.95), Vector3(1.85, 0.09, 0.45), WOOD)
    _box(self, "Shelf plank L3", Vector3(-2.95, 1.25, -3.95), Vector3(1.85, 0.09, 0.45), WOOD)
    _box(self, "Shelf upright L", Vector3(-3.8, 1.9, -3.95), Vector3(0.09, 1.9, 0.4), METAL)
    _box(self, "Shelf upright R", Vector3(-2.1, 1.9, -3.95), Vector3(0.09, 1.9, 0.4), METAL)

    # props on shelves
    for p in [Vector3(-3.35,2.67,-3.95), Vector3(-2.75,2.67,-3.95), Vector3(-2.55,2.02,-3.95), Vector3(-3.35,1.37,-3.95)]:
        _box(self, "Storage box", p, Vector3(0.42,0.28,0.32), Color("738B97"), 0.55)
    _box(self, "Mini drawers", Vector3(-2.75,2.03,-3.95), Vector3(0.58,0.38,0.30), Color("526672"))
    for i in range(2):
        for j in range(3):
            _box(self, "Drawer face", Vector3(-2.90 + j*0.19, 1.95 + i*0.12, -3.79), Vector3(0.12,0.08,0.02), Color("7A919C"))

    # lamp arm
    _cylinder(self, "Lamp base", Vector3(-1.26, 0.96, -1.72), 0.11, 0.04, Color("222E38"))
    _cylinder(self, "Lamp lower arm", Vector3(-1.10, 1.31, -1.60), 0.03, 0.78, Color("273542"))
    _cylinder(self, "Lamp upper arm", Vector3(-0.78, 1.72, -1.42), 0.025, 0.55, Color("273542"))
    _sphere(self, "Lamp joint1", Vector3(-1.10, 1.63, -1.60), 0.05, Color("2D3F4E"))
    _sphere(self, "Lamp joint2", Vector3(-0.78, 1.97, -1.42), 0.05, Color("2D3F4E"))
    var shade := _cylinder(self, "Lamp shade", Vector3(-0.50, 1.95, -1.24), 0.17, 0.34, Color("1F2A33"))
    shade.rotation_degrees.z = 42

    # sign
    _box(self, "Logo plaque", Vector3(-0.15, 3.35, -4.72), Vector3(3.1, 0.52, 0.05), Color("11202C"))
    var sign := Label3D.new()
    sign.text = "FIX & FLIP\nTECH"
    sign.font_size = 64
    sign.modulate = TEAL
    sign.position = Vector3(-1.1, 3.10, -4.60)
    sign.outline_size = 6
    sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
    add_child(sign)
    var sub := Label3D.new()
    sub.text = "Oficina de Eletrónica"
    sub.font_size = 30
    sub.modulate = WHITE
    sub.position = Vector3(-0.88, 2.82, -4.60)
    add_child(sub)
    for i in range(3):
        _box(self, "LED strip", Vector3(-0.9 + i * 0.85, 3.42, -4.64), Vector3(0.58, 0.035, 0.015), TEAL, 0.2, 0.0, true)

    # decor props on desk
    _cylinder(self, "Mug body", Vector3(0.85, 1.04, -1.58), 0.12, 0.18, Color("EFE7DF"))
    _sphere(self, "Mug handle", Vector3(0.99, 1.05, -1.58), 0.06, Color("EFE7DF"))
    _box(self, "Steam", Vector3(0.82, 1.23, -1.58), Vector3(0.02,0.16,0.02), Color("DCE8F2"), 0.1, 0.0, true)
    _box(self, "Parts tray", Vector3(-0.95, 0.98, -1.52), Vector3(0.62,0.06,0.42), Color("4C5968"))
    for i in range(4):
        _sphere(self, "Loose screw", Vector3(-1.12 + i*0.09,1.02,-1.50 + (i%2)*0.08), 0.02, Color("D7DADF"))
    _box(self, "PCB prop", Vector3(1.35, 0.98, -1.75), Vector3(0.78,0.04,0.28), Color("2E765C"))
    for i in range(4):
        _box(self, "PCB chip", Vector3(1.12 + i*0.14,1.01,-1.75), Vector3(0.08,0.04,0.08), BLACK)

    # stool
    _cylinder(self, "Stool seat", Vector3(-1.05, 0.56, 0.22), 0.28, 0.08, Color("242F37"))
    _cylinder(self, "Stool stem", Vector3(-1.05, 0.32, 0.22), 0.04, 0.40, Color("5B6B76"))
    _cylinder(self, "Stool base", Vector3(-1.05, 0.10, 0.22), 0.22, 0.04, Color("364652"))

    # plants
    _cylinder(self, "Plant pot", Vector3(1.85, 1.00, -2.0), 0.10, 0.18, Color("D19062"))
    for offset in [Vector3(0.0,0.18,0.0), Vector3(0.08,0.22,0.03), Vector3(-0.08,0.20,-0.02), Vector3(0.03,0.28,-0.05)]:
        _sphere(self, "Plant leaf", Vector3(1.85,1.04,-2.0)+offset, 0.08, Color("71B467"))

    # tool props on workbench
    screwdriver_prop = _clickable(self, "Pegar chave de fendas", Vector3(1.05, 1.025, -1.00), Vector3(0.18, 0.10, 0.48), Color("D99C34"), "tool_screwdriver")
    _cylinder(screwdriver_prop, "Pega de borracha", Vector3(0, 0.025, 0.03), 0.070, 0.30, Color("E9A83B"))
    _cylinder(screwdriver_prop, "Haste", Vector3(0, 0.025, -0.22), 0.018, 0.24, Color("CFD9E2"))

    brush_prop = _clickable(self, "Pegar pincel", Vector3(-1.02, 1.02, -1.00), Vector3(0.18, 0.12, 0.48), Color("BE8554"), "tool_brush")
    _box(brush_prop, "Cerdas", Vector3(0, 0.05, -0.20), Vector3(0.16, 0.12, 0.14), Color("F1D9A7"))

    tester_prop = _clickable(self, "Pegar testador", Vector3(1.32, 1.03, -1.43), Vector3(0.18, 0.07, 0.34), Color("F0C640"), "tool_tester")
    _box(tester_prop, "Tester screen", Vector3(0, 0.02, 0.02), Vector3(0.12,0.02,0.11), Color("163A4A"), 0.1)
    _box(tester_prop, "Tester probe", Vector3(0, 0.02, -0.15), Vector3(0.03,0.03,0.10), Color("DCE7EE"), 0.3, 0.2)

    new_battery_prop = _clickable(self, "Bateria nova", Vector3(1.36, 1.065, -1.67), Vector3(0.45, 0.13, 0.29), Color("65C8B4"), "new_battery")
    new_battery_marker = _marker_disc(self, Vector3(1.36, 1.15, -1.67), 0.14, GOLD)
    packing_prop = _clickable(self, "Caixa para venda", Vector3(-1.33, 1.10, -1.67), Vector3(0.55, 0.26, 0.42), Color("D5A26A"), "sell_box")
    sell_marker = _marker_disc(self, Vector3(-1.33, 1.25, -1.67), 0.16, GOLD)
    _dress_workshop()
    _sync_tools()


# -----------------------------------------------------------------------------
# ART PASS — details for a more lived-in, warm, stylized 3D repair workshop.
# Every object is actual world geometry; nothing here is a photographic backdrop.
# -----------------------------------------------------------------------------
func _dress_workshop() -> void:
    # Low, warm ceiling light strips that read like commercial game props.
    for x in [-2.8, 2.8]:
        _box(self, "Ceiling light fixture", Vector3(x, 3.93, -1.7), Vector3(0.23, 0.12, 2.5), Color("182B37"))
        _box(self, "Warm light diffuser", Vector3(x, 3.86, -1.7), Vector3(0.18, 0.018, 2.24), Color("FFE4AB"), 0.1, 0.0, true)
    # Hero desk gets a metal edge and a practical grid cutting mat.
    _box(self, "Desk edge inlay", Vector3(0, 0.916, -0.03), Vector3(3.55, 0.016, 0.027), Color("DBA778"), 0.35, 0.12)
    for k in range(14):
        var xx := -1.1 + k * 0.16
        _box(self, "Ruler mark", Vector3(xx, 0.956, -0.45), Vector3(0.004, 0.001, 0.03), Color("7AC2B3"), 0.95)
    # Neon under-shelf light.
    _box(self, "LED diffuser", Vector3(-2.95, 2.48, -3.7), Vector3(1.65, 0.016, 0.025), Color("38DAD9"), 0.08, 0.0, true)
    # Tool organizers, stacked boxes, radio, old PC and colorful book spines.
    for i in range(5):
        var xx := -3.6 + float(i) * 0.21
        _box(self, "Repair book", Vector3(xx, 2.76, -3.95), Vector3(0.16, 0.34 + float(i % 3) * 0.05, 0.28), Color.from_hsv(0.52 + 0.08 * i, 0.44, 0.65), 0.78)
    _box(self, "Bench oscilloscope", Vector3(-2.95, 1.43, -3.96), Vector3(0.68, 0.35, 0.42), Color("687782"))
    _box(self, "Scope glass", Vector3(-3.10, 1.46, -3.73), Vector3(0.31, 0.21, 0.015), Color("236A71"), 0.09)
    for i in range(3):
        _cylinder(self, "Scope knob", Vector3(-2.75 + 0.13 * i, 1.44, -3.73), 0.033, 0.06, GOLD)
    # Actual rounded plant leaf geometry, and desk storage.
    for i in range(5):
        var pos := Vector3(1.84 + sin(float(i) * 2.2) * 0.12, 1.23 + float(i) * 0.043, -2.02 + cos(float(i) * 2.2) * 0.08)
        var leaf := _sphere(self, "Plant broad leaf", pos, 0.11, Color("4B9B6A"))
        leaf.scale = Vector3(1.65, 0.46, 0.78)
    # Multiple monitors and repair boxes: all real 3D meshes.
    _box(self, "Parts cabinet", Vector3(3.50, 0.9, -3.95), Vector3(1.13, 1.35, 0.72), Color("334756"))
    for row in range(4):
        for col in range(3):
            var xx := 3.11 + col * 0.36
            var yy := 0.39 + row * 0.27
            _box(self, "Parts drawer", Vector3(xx, yy, -3.52), Vector3(0.31, 0.23, 0.025), Color("5A707C"))
            _box(self, "Drawer label", Vector3(xx, yy, -3.501), Vector3(0.18, 0.05, 0.005), Color("E9D2A7"))
    # Visible lamp glass with practical emissive accents.
    var bulb := _sphere(self, "Lamp bulb", Vector3(-0.49, 1.76, -1.24), 0.095, Color("FFDC95"), true)
    bulb.scale = Vector3(1.0, 0.5, 1.0)
    # A tiny red tool trolley reads well in the back of the workshop.
    _box(self, "Tool trolley", Vector3(-3.67, 0.48, -2.2), Vector3(0.78, 0.88, 0.49), Color("A6473D"), 0.45, 0.17)
    for i in range(3):
        _box(self, "Trolley drawer", Vector3(-3.67, 0.28 + i * 0.21, -1.94), Vector3(0.7, 0.15, 0.018), Color("CB6854"), 0.38, 0.16)
        _box(self, "Drawer grip", Vector3(-3.67, 0.28 + i * 0.21, -1.924), Vector3(0.25, 0.018, 0.018), Color("C5D0D8"), 0.2, 0.75)
    for x in [-3.95, -3.4]:
        for z in [-2.36,-2.04]:
            _cylinder(self, "Trolley castor", Vector3(x, 0.055, z), 0.062, 0.07, Color("17222C"))
    # Vents, bolt detailing, and screen housing pieces.
    for i in range(8):
        _box(self, "Pegboard hanging tool", Vector3(-1.24 + 0.30 * i, 2.3, -4.70), Vector3(0.035, 0.25 + 0.02 * (i % 3), 0.035), Color("B7C3CD"), 0.35, 0.65)
        _sphere(self, "Tool handle", Vector3(-1.24 + 0.30 * i, 2.15, -4.69), 0.045, Color("E4A83A"))

func _build_laptop() -> void:
    if laptop_root != null and is_instance_valid(laptop_root):
        laptop_root.queue_free()
    laptop_root = Node3D.new()
    laptop_root.name = "Interactive Laptop"
    laptop_root.position = workbench_pos
    add_child(laptop_root)
    inspection_pivot = Node3D.new()
    laptop_root.add_child(inspection_pivot)
    dynamic_root = Node3D.new()
    inspection_pivot.add_child(dynamic_root)

    _box(dynamic_root, "Laptop lower chassis", Vector3(0, 0.06, 0), Vector3(1.80, 0.11, 1.10), Color("C7CFD7"), 0.32, 0.4)
    _box(dynamic_root, "Palmrest", Vector3(0, 0.122, 0.10), Vector3(1.58, 0.01, 0.87), Color("D7DDE5"), 0.28, 0.35)
    _box(dynamic_root, "Keyboard frame", Vector3(0, 0.128, -0.08), Vector3(1.50, 0.012, 0.62), Color("243543"), 0.5, 0.3)
    for row in range(4):
        for col in range(12):
            _box(dynamic_root, "Keyboard key", Vector3(-0.65 + col * 0.119, 0.137, -0.31 + row * 0.16), Vector3(0.083, 0.01, 0.11), Color("111C28"))
    _box(dynamic_root, "Trackpad", Vector3(0, 0.137, 0.38), Vector3(0.49, 0.008, 0.20), Color("8AA0B1"))

    var hinge := Node3D.new()
    hinge.position = Vector3(0, 0.10, -0.51)
    hinge.rotation_degrees.x = -16
    dynamic_root.add_child(hinge)
    _box(hinge, "Screen housing", Vector3(0, 0.57, -0.03), Vector3(1.78, 1.16, 0.07), BLACK)
    _box(hinge, "Screen panel", Vector3(0, 0.58, 0.018), Vector3(1.62, 0.98, 0.018), Color("1D5367"), 0.17)
    _box(hinge, "Screen glow", Vector3(0, 0.58, 0.024), Vector3(1.52, 0.96, 0.003), Color("2AB2C1"), 0.10, 0.0, true)
    _box(hinge, "Logo bar", Vector3(0, 0.99, 0.03), Vector3(0.52, 0.03, 0.005), TEAL, 0.1, 0.0, true)

    cover_node = Node3D.new()
    cover_node.position = Vector3(0, 0.16, 0)
    dynamic_root.add_child(cover_node)
    _clickable(cover_node, "Removable cover", Vector3(0, 0.0, 0.07), Vector3(1.68, 0.025, 0.95), Color("394F60"), "cover")
    cover_marker = _marker_disc(cover_node, Vector3(0, 0.018, 0.07), 0.16, TEAL)

    screws.clear()
    screw_markers.clear()
    removed_screw_ids.clear()
    for x in [-0.72, 0.72]:
        for z in [-0.31, 0.44]:
            var screw := _clickable(dynamic_root, "Screw", Vector3(x, 0.192, z), Vector3(0.11, 0.03, 0.11), GOLD, "screw")
            screws.append(screw)
            screw_markers.append(_marker_disc(dynamic_root, Vector3(x, 0.206, z), 0.09, GOLD))

    battery_node = Node3D.new()
    battery_node.position = Vector3(-0.38, 0.14, 0.04)
    dynamic_root.add_child(battery_node)
    _clickable(battery_node, "Battery", Vector3.ZERO, Vector3(0.61, 0.09, 0.42), Color("637D89"), "battery")
    battery_marker = _marker_disc(battery_node, Vector3(0, 0.058, 0), 0.17, GOLD)

    dust_node = Node3D.new()
    dust_node.position = Vector3(0.45, 0.16, 0.02)
    dynamic_root.add_child(dust_node)
    _clickable(dust_node, "Dust patch", Vector3.ZERO, Vector3(0.54, 0.05, 0.53), Color("A79B79"), "dust")
    dust_marker = _marker_disc(dust_node, Vector3(0, 0.032, 0), 0.20, TEAL)
    _cylinder(dynamic_root, "Cooling fan", Vector3(0.45, 0.15, 0.02), 0.22, 0.06, Color("293D4E"))
    _box(dynamic_root, "Motherboard", Vector3(0.12, 0.13, 0.02), Vector3(0.78, 0.04, 0.62), Color("26694B"), 0.4)

    # Visible physical details: black rubber feet, hinge cylinders and ventilation.
    for xx in [-0.68,0.68]:
        for zz in [-0.4,0.42]:
            _box(dynamic_root, "Rubber foot", Vector3(xx, -0.004, zz), Vector3(0.16, 0.016, 0.08), Color("121E28"), 0.96)
    for xx in [-0.70,0.70]:
        _cylinder(dynamic_root, "Laptop hinge cap", Vector3(xx, 0.12, -0.51), 0.043, 0.10, Color("596B76"))
    for i in range(16):
        _box(dynamic_root, "Laptop ventilation slit", Vector3(-0.32 + i * 0.043, 0.154, -0.41), Vector3(0.024,0.006,0.09), Color("1F2C38"))
    # Decorative motherboard traces and small components.
    for i in range(6):
        _box(dynamic_root, "PCB chip", Vector3(-0.15 + (i % 3) * 0.18, 0.163, 0.05 + int(i / 3) * 0.21), Vector3(0.11,0.02,0.10), Color("162D32"), 0.4)
    for i in range(10):
        _box(dynamic_root, "PCB copper line", Vector3(-0.24 + 0.065 * i, 0.161, -0.22), Vector3(0.01,0.002,0.30), Color("C3A76C"), 0.36, 0.3)

    test_point_node = Node3D.new()
    test_point_node.position = Vector3(0.05, 0.18, -0.12)
    dynamic_root.add_child(test_point_node)
    _clickable(test_point_node, "Test point", Vector3.ZERO, Vector3(0.16, 0.06, 0.16), TEAL, "test_point")
    test_marker = _marker_disc(test_point_node, Vector3(0, 0.04, 0), 0.11, GOLD)

    _sync_device()

func _sync_device() -> void:
    if cover_node == null:
        return
    cover_node.visible = current_step <= 1 or current_step >= 6
    var cover_body: StaticBody3D = cover_node.get_child(0)
    cover_body.collision_layer = 1 if current_step == 1 else 0
    if current_step >= 6:
        cover_body.get_child(0).material_override = _material(TEAL, 0.45, 0.25, true)

    for index in range(screws.size()):
        var screw: StaticBody3D = screws[index]
        screw.visible = not removed_screw_ids.has(index) and current_step == 0
        screw.collision_layer = 1 if screw.visible else 0

    battery_node.visible = current_step >= 2 and current_step <= 5
    var battery_body: StaticBody3D = battery_node.get_child(0)
    battery_body.collision_layer = 1 if current_step == 3 else 0
    battery_body.visible = current_step != 4

    dust_node.visible = current_step == 2
    var dust_body: StaticBody3D = dust_node.get_child(0)
    dust_body.collision_layer = 1 if current_step == 2 else 0

    test_point_node.visible = current_step == 5
    var test_body: StaticBody3D = test_point_node.get_child(0)
    test_body.collision_layer = 1 if current_step == 5 else 0

    if cover_marker != null:
        cover_marker.visible = current_step == 1
    for i in range(screw_markers.size()):
        var marker: MeshInstance3D = screw_markers[i]
        marker.visible = current_step == 0 and not removed_screw_ids.has(i)
    if battery_marker != null:
        battery_marker.visible = current_step == 3
    if dust_marker != null:
        dust_marker.visible = current_step == 2
    if test_marker != null:
        test_marker.visible = current_step == 5
    if new_battery_marker != null:
        new_battery_marker.visible = current_step == 4
    if sell_marker != null:
        sell_marker.visible = current_step == 6

    _sync_tools()

func _enter_walk() -> void:
    mode = "walk"
    scene_camera.position = Vector3(0, 1.7, 2.75)
    walk_yaw = 0.0
    walk_pitch = -0.18
    _point_camera()
    drag_rotating = false
    brush_active = false
    selected_tool = "none"
    _sync_tools()
    if hand_root != null:
        hand_root.hide()
    scene_camera.fov = 70.0
    tool_selector_root.hide()
    style_board_root.hide()
    _set_interaction_capture_for_mode()
    _update_ui()

func _enter_inspect() -> void:
    mode = "inspect"
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    captured = false
    scene_camera.position = Vector3(0, 2.16, 1.03)
    scene_camera.look_at(workbench_pos + Vector3(0, 0.30, 0), Vector3.UP)
    scene_camera.fov = 58.0
    if hand_root != null:
        hand_root.show()
    selected_tool = "none"
    _sync_tools()
    tool_selector_root.hide()
    style_board_root.hide()
    _update_ui()

func _ray_part() -> Dictionary:
    var mouse_pos := get_viewport().get_mouse_position()
    var start := scene_camera.project_ray_origin(mouse_pos)
    var end := start + scene_camera.project_ray_normal(mouse_pos) * 10.0
    var query := PhysicsRayQueryParameters3D.create(start, end)
    return get_world_3d().direct_space_state.intersect_ray(query)

func _click_part() -> void:
    var hit := _ray_part()
    if hit.is_empty():
        return
    var collider: Object = hit.get("collider")
    if collider == null or not collider.has_meta("part_kind"):
        return
    var kind := str(collider.get_meta("part_kind"))
    _animate_hand_action()

    if kind == "tool_screwdriver":
        _equip_tool("screwdriver")
        return
    if kind == "tool_brush":
        _equip_tool("brush")
        return
    if kind == "tool_tester":
        _equip_tool("tester")
        return
    if kind == "new_battery" and current_step == 4:
        _install_new_battery()
        return
    if kind == "sell_box" and current_step == 6:
        _sell_and_restart()
        return

    if kind == "screw" and current_step == 0:
        if selected_tool != "screwdriver":
            info_label.text = "Usa TAB ou clica na chave de fendas para a equipar."
            return
        var screw_index: int = screws.find(collider)
        if screw_index < 0 or removed_screw_ids.has(screw_index):
            return
        removed_screw_ids.append(screw_index)
        collider.visible = false
        collider.collision_layer = 0
        screws_left = maxi(0, 4 - removed_screw_ids.size())
        info_label.text = "Parafuso removido. Restam %d." % screws_left
        if screws_left == 0:
            current_step = 1
            info_label.text = "Tudo desaparafusado. Larga a ferramenta e clica na tampa."
    elif kind == "cover" and current_step == 1:
        if selected_tool != "none":
            info_label.text = "Larga a ferramenta antes de remover a tampa."
            return
        current_step = 2
        info_label.text = "Tampa removida. Usa o pincel para limpar o pó."
    elif kind == "battery" and current_step == 3:
        if selected_tool != "none":
            info_label.text = "Larga o pincel e retira a bateria com a mão."
            return
        current_step = 4
        info_label.text = "Bateria retirada. Clica na bateria verde nova."
    elif kind == "test_point" and current_step == 5:
        if selected_tool != "tester":
            info_label.text = "Equipa o testador com TAB ou clicando no aparelho amarelo."
            return
        current_step = 6
        info_label.text = "Teste elétrico concluído com sucesso. Pronto para venda!"

    _sync_device()
    _update_ui()

func _brush_at_mouse() -> void:
    if current_step != 2 or selected_tool != "brush":
        return
    var hit := _ray_part()
    if hit.is_empty():
        return
    var collider: Object = hit.get("collider")
    if collider == null or not collider.has_meta("part_kind"):
        return
    if str(collider.get_meta("part_kind")) != "dust":
        return
    _animate_hand_action()
    dust_left -= 1
    if dust_left <= 0:
        current_step = 3
        brush_active = false
        selected_tool = "none"
        info_label.text = "Limpeza concluída. Agora retira a bateria avariada."
        _sync_device()
        _update_hand(0.0)
        _update_ui()
    else:
        info_label.text = "A limpar... %d passagens restantes" % dust_left
        _update_ui()

func _install_new_battery() -> void:
    if current_step != 4:
        return
    if balance < part_cost:
        info_label.text = "Saldo insuficiente para comprar a bateria."
        return
    balance -= part_cost
    current_step = 5
    selected_tool = "none"
    info_label.text = "Bateria nova instalada. Agora testa o portátil com o testador."
    _sync_device()
    _update_ui()
    _save_progress()

func _sell_and_restart() -> void:
    if current_step != 6:
        return
    var sale_price := 135
    var net := sale_price - inventory_cost - part_cost
    balance += sale_price
    profit += net
    fixed_count += 1
    balance -= inventory_cost
    current_step = 0
    screws_left = 4
    removed_screw_ids.clear()
    dust_left = 8
    brush_active = false
    selected_tool = "none"
    info_label.text = "Venda concluída: +%d € de margem. Chegou outro portátil!" % net
    _build_laptop()
    _update_ui()
    _save_progress()

func _load_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    if not (data is Dictionary):
        return
    balance = int(data.get("balance", 250))
    profit = int(data.get("profit", 0))
    fixed_count = int(data.get("fixed", 0))

func _save_progress() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({"balance": balance, "profit": profit, "fixed": fixed_count}))
    file.close()

func _text(text_value: String, font_size := 17, color := WHITE) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label

func _button(text_value: String, action: Callable, highlight := false) -> Button:
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(290, 52)
    b.add_theme_font_size_override("font_size", 20)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("E9B34A") if highlight else Color("172839")
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    b.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate() as StyleBoxFlat
    hover.bg_color = Color("F8D17C") if highlight else Color("294B5C")
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", hover)
    b.add_theme_color_override("font_color", INK if highlight else WHITE)
    b.add_theme_color_override("font_hover_color", INK if highlight else WHITE)
    b.pressed.connect(action)
    return b

func _ui_card(color: Color = Color(0.03, 0.07, 0.12, 0.78)) -> PanelContainer:
    var panel := PanelContainer.new()
    var bg := StyleBoxFlat.new()
    bg.bg_color = color
    bg.corner_radius_top_left = 16
    bg.corner_radius_top_right = 16
    bg.corner_radius_bottom_left = 16
    bg.corner_radius_bottom_right = 16
    bg.content_margin_left = 16
    bg.content_margin_right = 16
    bg.content_margin_top = 12
    bg.content_margin_bottom = 12
    panel.add_theme_stylebox_override("panel", bg)
    return panel

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    game_hud = Control.new()
    game_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    game_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(game_hud)

    var top_left := _ui_card(Color(0.03,0.07,0.12,0.72))
    top_left.anchor_left = 0.02
    top_left.anchor_right = 0.28
    top_left.anchor_top = 0.02
    top_left.anchor_bottom = 0.11
    top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_hud.add_child(top_left)
    var tlv := VBoxContainer.new()
    top_left.add_child(tlv)
    tlv.add_child(_text("FIX & FLIP TECH", 22, TEAL))
    style_hint_label = _text("TAB  •  FERRAMENTAS", 12, GOLD)
    tlv.add_child(style_hint_label)

    var top_right := _ui_card(Color(0.03,0.07,0.12,0.72))
    top_right.anchor_left = 0.61
    top_right.anchor_right = 0.98
    top_right.anchor_top = 0.02
    top_right.anchor_bottom = 0.10
    top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_hud.add_child(top_right)
    stats_label = _text("", 16)
    stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    top_right.add_child(stats_label)

    var objective := _ui_card(Color(0.03,0.07,0.12,0.70))
    objective.anchor_left = 0.66
    objective.anchor_right = 0.98
    objective.anchor_top = 0.12
    objective.anchor_bottom = 0.31
    objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_hud.add_child(objective)
    var objective_col := VBoxContainer.new()
    objective_col.add_theme_constant_override("separation", 8)
    objective.add_child(objective_col)
    objective_col.add_child(_text("OBJETIVO ATUAL", 19, GOLD))
    task_label = _text("", 18, TEAL)
    task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    objective_col.add_child(task_label)
    info_label = _text("", 14)
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    objective_col.add_child(info_label)

    var bottom_left := _ui_card(Color(0.03,0.07,0.12,0.68))
    bottom_left.anchor_left = 0.02
    bottom_left.anchor_right = 0.27
    bottom_left.anchor_top = 0.81
    bottom_left.anchor_bottom = 0.96
    bottom_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_hud.add_child(bottom_left)
    var blv := VBoxContainer.new()
    bottom_left.add_child(blv)
    blv.add_child(_text("CONTROLOS", 17, GOLD))
    hint_label = _text("", 13)
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    blv.add_child(hint_label)

    var bottom_right := _ui_card(Color(0.03,0.07,0.12,0.68))
    bottom_right.anchor_left = 0.65
    bottom_right.anchor_right = 0.98
    bottom_right.anchor_top = 0.80
    bottom_right.anchor_bottom = 0.96
    bottom_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_hud.add_child(bottom_right)
    var brv := VBoxContainer.new()
    bottom_right.add_child(brv)
    brv.add_child(_text("PASSOS DA REPARAÇÃO", 17, GOLD))
    steps_label = _text("", 14)
    steps_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    brv.add_child(steps_label)

    hover_label = _text("", 15, TEAL)
    hover_label.anchor_left = 0.28
    hover_label.anchor_right = 0.72
    hover_label.anchor_top = 0.72
    hover_label.anchor_bottom = 0.78
    hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_hud.add_child(hover_label)

    cursor_label = _text("+", 25, TEAL)
    cursor_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    cursor_label.position = Vector2(-7, -15)
    game_hud.add_child(cursor_label)

    tool_label = _text("MÃO LIVRE", 15, GOLD)
    tool_label.anchor_left = 0.40
    tool_label.anchor_right = 0.60
    tool_label.anchor_top = 0.92
    tool_label.anchor_bottom = 0.97
    tool_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_hud.add_child(tool_label)

    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(menu_root)
    var backdrop := TextureRect.new()
    backdrop.texture = load("res://assets/menu_workshop.png")
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_root.add_child(backdrop)
    var shade := ColorRect.new()
    shade.color = Color(0.015, 0.04, 0.07, 0.22)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_root.add_child(shade)
    var menu_margin := MarginContainer.new()
    menu_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_margin.add_theme_constant_override("margin_left", 58)
    menu_margin.add_theme_constant_override("margin_top", 105)
    menu_root.add_child(menu_margin)
    var menu_col := VBoxContainer.new()
    menu_col.add_theme_constant_override("separation", 12)
    menu_margin.add_child(menu_col)
    menu_col.add_child(_text("FIX & FLIP", 64, TEAL))
    menu_col.add_child(_text("TECH", 64, WHITE))
    menu_col.add_child(_text("Oficina de eletrónica", 24, WHITE))
    menu_col.add_child(_text("Compra  •  Repara  •  Revende", 18, GOLD))
    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(1, 34)
    menu_col.add_child(spacer)
    menu_col.add_child(_button("▶  COMEÇAR JOGO", _new_game, true))
    menu_col.add_child(_button("↻  CONTINUAR", _continue_game))
    menu_col.add_child(_button("?  COMO JOGAR", _show_guide))
    menu_col.add_child(_button("✕  SAIR", func(): get_tree().quit()))
    menu_col.add_child(_text("Demo 0.6  •  oficina em desenvolvimento", 14, Color("C3D5E1")))

    intro_root = _overlay_modal(canvas, "PRIMEIRO TRABALHO", "Herdaste uma oficina promissora, mas quase vazia. O objetivo é reparar um portátil: desaparafusar, abrir, limpar, trocar a bateria, testar a corrente e vender com lucro.\n\nDica: em inspeção, usa TAB para abrir o seletor de ferramentas.", "ENTRAR NA OFICINA", _start_workshop)
    pause_root = _overlay_modal(canvas, "PAUSA", "O teu progresso de vendas é guardado automaticamente.", "CONTINUAR JOGO", _resume_game)
    var pause_content := pause_root.get_meta("modal_box") as VBoxContainer
    pause_content.add_child(_button("MENU INICIAL", _return_menu))

    _build_tool_selector(canvas)
    _build_style_board(canvas)
    _build_hand()

func _build_style_board(canvas: CanvasLayer) -> void:
    style_board_root = Control.new()
    style_board_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(style_board_root)
    var dark := ColorRect.new()
    dark.color = Color(0.01, 0.02, 0.04, 0.82)
    dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    style_board_root.add_child(dark)
    var tex := TextureRect.new()
    tex.texture = load("res://assets/style_board.png")
    tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tex.anchor_left = 0.06
    tex.anchor_right = 0.94
    tex.anchor_top = 0.08
    tex.anchor_bottom = 0.92
    style_board_root.add_child(tex)
    var close_info := _text("F1 ou ESC para fechar este painel de referência visual", 16, GOLD)
    close_info.anchor_left = 0.25
    close_info.anchor_right = 0.75
    close_info.anchor_top = 0.02
    close_info.anchor_bottom = 0.07
    close_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    style_board_root.add_child(close_info)
    style_board_root.hide()

func _build_tool_selector(canvas: CanvasLayer) -> void:
    tool_selector_root = Control.new()
    tool_selector_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(tool_selector_root)
    var dim := ColorRect.new()
    dim.color = Color(0.01, 0.03, 0.06, 0.45)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tool_selector_root.add_child(dim)

    var wheel := Control.new()
    wheel.anchor_left = 0.5
    wheel.anchor_right = 0.5
    wheel.anchor_top = 0.5
    wheel.anchor_bottom = 0.5
    wheel.offset_left = -210
    wheel.offset_top = -210
    wheel.offset_right = 210
    wheel.offset_bottom = 210
    tool_selector_root.add_child(wheel)

    var ring := PanelContainer.new()
    ring.anchor_left = 0.0
    ring.anchor_right = 1.0
    ring.anchor_top = 0.0
    ring.anchor_bottom = 1.0
    var ring_style := StyleBoxFlat.new()
    ring_style.bg_color = Color(0.06, 0.10, 0.16, 0.88)
    ring_style.corner_radius_top_left = 210
    ring_style.corner_radius_top_right = 210
    ring_style.corner_radius_bottom_left = 210
    ring_style.corner_radius_bottom_right = 210
    ring_style.border_width_left = 6
    ring_style.border_width_top = 6
    ring_style.border_width_right = 6
    ring_style.border_width_bottom = 6
    ring_style.border_color = Color(0.21, 0.30, 0.40, 0.95)
    ring.add_theme_stylebox_override("panel", ring_style)
    wheel.add_child(ring)

    var center := PanelContainer.new()
    center.anchor_left = 0.5
    center.anchor_right = 0.5
    center.anchor_top = 0.5
    center.anchor_bottom = 0.5
    center.offset_left = -88
    center.offset_top = -70
    center.offset_right = 88
    center.offset_bottom = 70
    var center_style := StyleBoxFlat.new()
    center_style.bg_color = Color(0.09, 0.13, 0.20, 0.96)
    center_style.corner_radius_top_left = 90
    center_style.corner_radius_top_right = 90
    center_style.corner_radius_bottom_left = 90
    center_style.corner_radius_bottom_right = 90
    center_style.border_width_left = 3
    center_style.border_width_top = 3
    center_style.border_width_right = 3
    center_style.border_width_bottom = 3
    center_style.border_color = Color(0.84, 0.66, 0.22, 0.95)
    center.add_theme_stylebox_override("panel", center_style)
    wheel.add_child(center)

    var center_box := VBoxContainer.new()
    center_box.alignment = BoxContainer.ALIGNMENT_CENTER
    center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    center.add_child(center_box)
    center_box.add_child(_text("Ferramenta", 16, GOLD))
    center_box.add_child(_text("TAB", 28, WHITE))
    selector_help = _text("1 / 2 / 3 ou clicar", 13, Color("C7D8E3"))
    center_box.add_child(selector_help)

    _wheel_tool_button(wheel, "screwdriver", "🪛", "1", Vector2(155, 35), "Desaparafusar")
    _wheel_tool_button(wheel, "brush", "🖌", "2", Vector2(28, 250), "Limpar")
    _wheel_tool_button(wheel, "tester", "⚡", "3", Vector2(282, 250), "Testar")
    tool_selector_root.hide()

func _tool_card(parent: HBoxContainer, kind: String, hotkey: String, title_text: String, desc_text: String) -> void:
    var panel := _ui_card(Color(0.10,0.17,0.25,0.95))
    panel.custom_minimum_size = Vector2(0, 120)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(panel)
    tool_cards[kind] = panel
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 8)
    panel.add_child(vb)
    vb.add_child(_text(hotkey, 24, GOLD))
    vb.add_child(_text(title_text, 18, WHITE))
    vb.add_child(_text(desc_text, 13, Color("C7D8E3")))
    var btn := Button.new()
    btn.text = "Equipar"
    btn.custom_minimum_size = Vector2(0, 34)
    btn.pressed.connect(func(): _equip_tool(kind))
    vb.add_child(btn)

func _wheel_tool_button(parent: Control, kind: String, symbol: String, hotkey: String, pos: Vector2, caption: String) -> void:
    var holder := Control.new()
    holder.position = pos
    holder.size = Vector2(110, 110)
    parent.add_child(holder)

    var btn := Button.new()
    btn.anchor_right = 1.0
    btn.anchor_bottom = 1.0
    btn.text = "%s\n%s" % [symbol, hotkey]
    btn.add_theme_font_size_override("font_size", 28)
    btn.add_theme_color_override("font_color", WHITE)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.10, 0.16, 0.24, 0.95)
    style.corner_radius_top_left = 55
    style.corner_radius_top_right = 55
    style.corner_radius_bottom_left = 55
    style.corner_radius_bottom_right = 55
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.border_color = Color(0.23, 0.33, 0.45, 0.95)
    btn.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate() as StyleBoxFlat
    hover.bg_color = Color(0.16, 0.24, 0.35, 0.98)
    btn.add_theme_stylebox_override("hover", hover)
    btn.add_theme_stylebox_override("pressed", hover)
    btn.pressed.connect(func(): _equip_tool(kind))
    holder.add_child(btn)
    tool_cards[kind] = btn

    var label := _text(caption, 13, WHITE)
    label.anchor_left = 0.5
    label.anchor_right = 0.5
    label.anchor_top = 1.0
    label.anchor_bottom = 1.0
    label.offset_left = -60
    label.offset_top = 8
    label.offset_right = 60
    label.offset_bottom = 28
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    holder.add_child(label)

func _overlay_modal(canvas: CanvasLayer, title_text: String, body_text: String, button_text: String, action: Callable) -> Control:
    var layer := Control.new()
    layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(layer)
    var dark := ColorRect.new()
    dark.color = Color(0.01, 0.03, 0.06, 0.83)
    dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(dark)
    var card := _ui_card(Color("12283A"))
    card.anchor_left = 0.28
    card.anchor_right = 0.72
    card.anchor_top = 0.26
    card.anchor_bottom = 0.76
    layer.add_child(card)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 20)
    card.add_child(v)
    v.add_child(_text(title_text, 31, TEAL))
    var body := _text(body_text, 19)
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    v.add_child(body)
    v.add_child(_button(button_text, action, true))
    layer.set_meta("modal_box", v)
    layer.hide()
    return layer

func _show_main_menu() -> void:
    mode = "menu"
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    captured = false
    menu_root.show()
    intro_root.hide()
    pause_root.hide()
    tool_selector_root.hide()
    style_board_root.hide()
    game_hud.hide()
    _sync_tools()

func _new_game() -> void:
    balance = 250
    profit = 0
    fixed_count = 0
    current_step = 0
    screws_left = 4
    removed_screw_ids.clear()
    dust_left = 8
    selected_tool = "none"
    _build_laptop()
    _save_progress()
    _show_intro()

func _continue_game() -> void:
    _show_intro()

func _show_guide() -> void:
    _show_intro()

func _show_intro() -> void:
    mode = "intro"
    menu_root.hide()
    game_hud.hide()
    intro_root.show()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _start_workshop() -> void:
    intro_root.hide()
    game_hud.show()
    _enter_walk()
    info_label.text = "Carrega E para entrar na bancada. Dentro dela, usa TAB para escolher ferramenta."

func _pause_game() -> void:
    mode = "pause"
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    captured = false
    pause_root.show()
    game_hud.hide()

func _resume_game() -> void:
    pause_root.hide()
    game_hud.show()
    _enter_walk()

func _return_menu() -> void:
    _save_progress()
    _show_main_menu()

func _toggle_tool_selector(show_value: bool) -> void:
    tool_selector_root.visible = show_value
    if show_value:
        style_board_root.hide()
    _update_tool_cards()

func _update_tool_cards() -> void:
    for kind in tool_cards.keys():
        var b: Button = tool_cards[kind]
        var style := StyleBoxFlat.new()
        style.bg_color = Color("E9B34A") if kind == selected_tool else Color(0.10, 0.16, 0.24, 0.95)
        style.corner_radius_top_left = 55
        style.corner_radius_top_right = 55
        style.corner_radius_bottom_left = 55
        style.corner_radius_bottom_right = 55
        style.border_width_left = 3
        style.border_width_top = 3
        style.border_width_right = 3
        style.border_width_bottom = 3
        style.border_color = Color("F8D17C") if kind == selected_tool else Color(0.23, 0.33, 0.45, 0.95)
        b.add_theme_stylebox_override("normal", style)
        var hover := style.duplicate() as StyleBoxFlat
        hover.bg_color = Color("F1C55C") if kind == selected_tool else Color(0.16, 0.24, 0.35, 0.98)
        b.add_theme_stylebox_override("hover", hover)
        b.add_theme_stylebox_override("pressed", hover)
        b.add_theme_color_override("font_color", INK if kind == selected_tool else WHITE)

func _equip_tool(kind: String) -> void:
    selected_tool = "none" if selected_tool == kind else kind
    brush_active = selected_tool == "brush"
    if selected_tool == "screwdriver":
        info_label.text = "Chave na mão. Clica exatamente nos parafusos."
    elif selected_tool == "brush":
        info_label.text = "Pincel na mão. Esfrega sobre a zona de pó."
    elif selected_tool == "tester":
        info_label.text = "Testador equipado. Usa-o no ponto de teste quando chegares a essa etapa."
    else:
        info_label.text = "Mãos livres. Podes pegar numa peça, tampa ou ferramenta."
    _sync_tools()
    _update_hand(0.0)
    _update_tool_cards()
    _update_ui()

func _sync_tools() -> void:
    if screwdriver_prop != null and is_instance_valid(screwdriver_prop):
        screwdriver_prop.visible = selected_tool != "screwdriver"
        screwdriver_prop.collision_layer = 1 if screwdriver_prop.visible else 0
    if brush_prop != null and is_instance_valid(brush_prop):
        brush_prop.visible = selected_tool != "brush"
        brush_prop.collision_layer = 1 if brush_prop.visible else 0
    if tester_prop != null and is_instance_valid(tester_prop):
        tester_prop.visible = selected_tool != "tester"
        tester_prop.collision_layer = 1 if tester_prop.visible else 0
    if new_battery_prop != null and is_instance_valid(new_battery_prop):
        new_battery_prop.visible = current_step == 4
        new_battery_prop.collision_layer = 1 if new_battery_prop.visible else 0
    if packing_prop != null and is_instance_valid(packing_prop):
        packing_prop.visible = current_step == 6
        packing_prop.collision_layer = 1 if packing_prop.visible else 0

func _build_hand() -> void:
    hand_root = Node3D.new()
    hand_root.position = Vector3(0.67, -0.62, -1.02)
    scene_camera.add_child(hand_root)
    var wrist := Node3D.new()
    wrist.name = "Wrist"
    hand_root.add_child(wrist)
    _box(wrist, "Sleeve", Vector3(0.16, -0.17, 0.09), Vector3(0.25, 0.50, 0.24), Color("233E53"))
    var palm := _sphere(wrist, "Gloved palm", Vector3(0.08, 0.16, -0.07), 0.16, Color("25333E"))
    palm.scale = Vector3(1.0, 1.25, 0.65)
    for i in range(4):
        var finger := _sphere(wrist, "Glove finger", Vector3(-0.035 + float(i) * 0.07, 0.30, -0.13), 0.060, Color("34434D"))
        finger.scale = Vector3(0.45, 1.35, 0.75)
    var thumb := _sphere(wrist, "Glove thumb", Vector3(-0.045, 0.17, -0.18), 0.066, Color("34434D"))
    thumb.scale = Vector3(0.8, 1.25, 0.7)
    _box(wrist, "Glove trim", Vector3(0.16, -0.02, 0.09), Vector3(0.25,0.04,0.24), Color("DA9A38"))

    var screwdriver := Node3D.new()
    screwdriver.name = "ScrewdriverInHand"
    screwdriver.rotation_degrees = Vector3(38, 0, -18)
    wrist.add_child(screwdriver)
    _cylinder(screwdriver, "Handle", Vector3(0, 0.31, -0.04), 0.075, 0.39, Color("E5A838"))
    _cylinder(screwdriver, "Shaft", Vector3(0, 0.60, -0.04), 0.024, 0.27, Color("C8DBE5"))

    var brush := Node3D.new()
    brush.name = "BrushInHand"
    brush.rotation_degrees = Vector3(38, 0, -18)
    wrist.add_child(brush)
    _cylinder(brush, "Handle", Vector3(0, 0.35, -0.04), 0.045, 0.54, WOOD)
    _box(brush, "Bristles", Vector3(0, 0.66, -0.04), Vector3(0.2, 0.15, 0.12), Color("F2DDB5"))

    var tester := Node3D.new()
    tester.name = "TesterInHand"
    tester.rotation_degrees = Vector3(18, -8, -18)
    wrist.add_child(tester)
    _box(tester, "Body", Vector3(0.02, 0.36, -0.04), Vector3(0.16, 0.06, 0.28), Color("F0C640"), 0.3)
    _box(tester, "Screen", Vector3(0.02, 0.39, 0.00), Vector3(0.10, 0.01, 0.09), Color("16404D"), 0.1)
    _cylinder(tester, "Probe", Vector3(0.02, 0.48, -0.14), 0.015, 0.14, Color("D6E4EB"))
    hand_root.hide()

func _update_hand(delta: float) -> void:
    if hand_root == null:
        return
    hand_root.visible = mode == "inspect"
    if not hand_root.visible:
        return
    hand_root.get_node("Wrist/ScrewdriverInHand").visible = selected_tool == "screwdriver"
    hand_root.get_node("Wrist/BrushInHand").visible = selected_tool == "brush"
    hand_root.get_node("Wrist/TesterInHand").visible = selected_tool == "tester"
    var mouse_offset := get_viewport().get_mouse_position() / get_viewport().get_visible_rect().size - Vector2(0.5, 0.5)
    var target := Vector3(0.67 + mouse_offset.x * 0.18, -0.62 - mouse_offset.y * 0.12, -1.02)
    hand_root.position = hand_root.position.lerp(target, minf(1.0, delta * 10.0))

func _animate_hand_action() -> void:
    if hand_root == null or mode != "inspect":
        return
    var initial := hand_root.position
    var tween := create_tween()
    tween.tween_property(hand_root, "position", initial + Vector3(-0.13, 0.12, -0.20), 0.09)
    tween.tween_property(hand_root, "position", initial, 0.18)

func _update_hover() -> void:
    if mode != "inspect":
        return
    var hit := _ray_part()
    if hit.is_empty():
        hover_label.text = ""
        return
    var collider: Object = hit.get("collider")
    if collider == null or not collider.has_meta("part_kind"):
        hover_label.text = ""
        return
    var kind := str(collider.get_meta("part_kind"))
    var prompts := {
        "tool_screwdriver": "[CLICAR] Pegar chave de fendas",
        "tool_brush": "[CLICAR] Pegar pincel",
        "tool_tester": "[CLICAR] Pegar testador",
        "screw": "[CLICAR] Desaparafusar",
        "cover": "[CLICAR] Levantar a tampa",
        "dust": "[CLICAR E ESFREGAR] Limpar com pincel",
        "battery": "[CLICAR] Retirar bateria avariada",
        "new_battery": "[CLICAR] Instalar bateria nova — 25 €",
        "test_point": "[CLICAR] Testar corrente no portátil",
        "sell_box": "[CLICAR] Embalar e vender portátil"
    }
    hover_label.text = str(prompts.get(kind, ""))

func _update_ui() -> void:
    if stats_label == null:
        return
    stats_label.text = "€ %d   •   Lucro %d   •   Reparados %d" % [balance, profit, fixed_count]
    if mode == "walk":
        task_label.text = "Entrar na bancada"
        info_label.text = "Aproxima-te da mesa principal e carrega E."
        hint_label.text = "WASD andar  •  rato olhar  •  E bancada  •  ESC pausa"
        steps_label.text = "1. Aproxima-te do portátil\n2. Entra em modo bancada\n3. Repara o equipamento"
    else:
        var tasks := [
            "Retirar os 4 parafusos",
            "Abrir a tampa inferior",
            "Limpar a poeira",
            "Retirar a bateria avariada",
            "Instalar bateria nova",
            "Testar corrente",
            "Pronto para vender"
        ]
        task_label.text = tasks[current_step]
        hint_label.text = "TAB ferramentas  •  1-2-3 equipar  •  botão direito + arrastar rodar  •  Q largar  •  ESC sair"
        if current_step == 0:
            steps_label.text = "Equipa a chave de fendas.\nParafusos restantes: %d/4" % screws_left
        elif current_step == 1:
            steps_label.text = "Larga a ferramenta e clica na tampa inferior."
        elif current_step == 2:
            steps_label.text = "Usa o pincel e limpa a área com pó.\nPassagens restantes: %d" % dust_left
        elif current_step == 3:
            steps_label.text = "Com mãos livres, clica na bateria avariada."
        elif current_step == 4:
            steps_label.text = "Clica na bateria nova, à direita da bancada."
        elif current_step == 5:
            steps_label.text = "Equipa o testador e clica no ponto de teste."
        else:
            steps_label.text = "Clica na caixa de venda à esquerda.\nVenda 135 € • Lucro 58 €"
    tool_label.text = "Ferramenta: %s" % {"none": "mão livre", "screwdriver": "chave de fendas", "brush": "pincel", "tester": "testador"}.get(selected_tool, selected_tool)
    cursor_label.visible = mode == "walk" and captured
