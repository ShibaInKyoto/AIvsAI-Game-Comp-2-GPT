class_name MidnightInterface
extends CanvasLayer
## One scalable 1280x720 canvas. Menus pause the simulation without blocking UI input.

signal play_requested(daily: bool)
signal resume_requested
signal quit_requested
signal setting_changed(key: String, value: float)
var root: Control
var hud: Control
var menu: Control
var heading: Label
var subtitle: Label
var bank_label: Label
var timer_label: Label
var room_label: Label
var status_label: Label
var prompt_label: Label
var notice_label: Label
var manifest_label: Label
var threat_label: Label
var inventory_labels: Array[Label] = []
var progress: Meter
var stamina: Meter
var danger: ColorRect
var title_font := preload("res://assets/fonts/display.ttf")
var body_font := preload("res://assets/fonts/body.ttf")
var gold := Color("d8b77e")
var pale := Color("efe4cf")
var menu_buttons: VBoxContainer
var settings_box: VBoxContainer
var mode := "title"
var best := 0

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	danger = rect(root, Vector2.ZERO, Vector2(1280, 720), Color(0.6, 0.05, 0.07, 0))
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := rect(hud, Vector2(26, 22), Vector2(1228, 78), Color(0.025, 0.045, 0.065, 0.94))
	rect(top, Vector2.ZERO, Vector2(1228, 2), gold)
	room_label = label(top, Vector2(20, 13), "00 / THE EXCHANGE", 24, true)
	bank_label = label(top, Vector2(460, 14), "", 22)
	timer_label = label(top, Vector2(1040, 12), "", 32, true)
	status_label = label(top, Vector2(21, 48), "", 12)
	progress = bar(top, Vector2(460, 51), Vector2(380, 5), gold)
	threat_label = label(hud, Vector2(34, 118), "", 16)
	threat_label.modulate = Color("efab91")
	var crosshair := label(hud, Vector2(634, 347), "·", 24)
	crosshair.modulate.a = 0.8
	var bottom := rect(hud, Vector2(26, 546), Vector2(1228, 148), Color(0.025, 0.045, 0.065, 0.94))
	rect(bottom, Vector2.ZERO, Vector2(1228, 1), gold * Color(1, 1, 1, 0.5))
	prompt_label = label(bottom, Vector2(18, 10), "", 18)
	manifest_label = label(bottom, Vector2(18, 42), "MANIFEST", 12)
	for i in range(5):
		var slot := label(bottom, Vector2(18 + i * 244, 64), "", 14)
		slot.size = Vector2(233, 55)
		inventory_labels.append(slot)
	label(bottom, Vector2(18, 122), "WASD  WALK     SHIFT  RUN     CTRL  SNEAK     E  INTERACT     F  FOLD HOME     X  DROP     T  TIMETABLE     ESC  PAUSE", 11)
	stamina = bar(hud, Vector2(1050, 520), Vector2(200, 4), Color("9fcac2"))
	notice_label = label(hud, Vector2(160, 450), "", 21, true)
	notice_label.size.x = 960
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu = Control.new()
	root.add_child(menu)
	rect(menu, Vector2.ZERO, Vector2(1280, 720), Color(0.018, 0.032, 0.05, 0.91))
	rect(menu, Vector2(62, 55), Vector2(2, 610), gold)
	label(menu, Vector2(92, 56), "NIGHT SERVICE  /  EST. 1893", 14).modulate = gold
	heading = label(menu, Vector2(90, 103), "THE MIDNIGHT\nEXCHANGE", 60, true)
	heading.add_theme_color_override("font_color", pale)
	subtitle = label(menu, Vector2(94, 270), "", 17)
	subtitle.size = Vector2(590, 190)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_buttons = VBoxContainer.new()
	menu_buttons.position = Vector2(94, 465)
	menu_buttons.size = Vector2(440, 180)
	menu_buttons.add_theme_constant_override("separation", 10)
	menu.add_child(menu_buttons)
	var rules := rect(menu, Vector2(780, 94), Vector2(410, 526), Color(0.06, 0.1, 0.13, 0.96))
	rect(rules, Vector2(0, 0), Vector2(410, 2), gold)
	label(rules, Vector2(28, 24), "A PORTER'S FIELD GUIDE", 22, true)
	var guide := "01   TAKE WHAT SHOULD NOT EXIST\nExplore seven carriages. Carry three relics.\nDeeper freight pays more. E to collect.\n\n02   MAKE IT BACK TO THE COUNTER\nBank £600 before dawn to buy your freedom.\nUnbanked freight is lost when time runs out.\n\n03   PACK WITH INTENTION\nHours buy time. Bells multiply a delivery.\nDoorways fold you home. Aurora calms you.\n\n04   THE CONDUCTOR IS LISTENING\nRun when safe. Sneak off the central aisle\nto pass him. Bells carry farther than footsteps.\nCaught? Lose freight and 15s, not your savings.\n\n05   YOUR FIRST TWO DELIVERIES\nEarn a free upgrade at the exchange.\nT brings the last car to the front for 10s.\nEscape early with Q once your debt is paid."
	label(rules, Vector2(28, 70), guide, 14)
	settings_box = VBoxContainer.new()
	settings_box.position = Vector2(94, 465)
	settings_box.size = Vector2(530, 170)
	menu.add_child(settings_box)
	show_title(0)

func rect(parent: Node, pos: Vector2, dimensions: Vector2, color: Color) -> ColorRect:
	var item := ColorRect.new()
	item.position = pos
	item.size = dimensions
	item.color = color
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func label(parent: Node, pos: Vector2, text: String, font_size: int, display := false) -> Label:
	var item := Label.new()
	item.position = pos
	item.text = text
	item.add_theme_font_override("font", title_font if display else body_font)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", pale)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

class Meter:
	extends Control
	var tint := Color.WHITE
	var value := 0.0:
		set(next):
			value = clampf(next, 0, 100)
			queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("263b47"))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * value / 100, size.y)), tint)

func bar(parent: Node, pos: Vector2, dimensions: Vector2, color: Color) -> Meter:
	var item := Meter.new()
	item.position = pos
	item.size = dimensions
	item.tint = color
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func clear_buttons() -> void:
	for child in menu_buttons.get_children():
		menu_buttons.remove_child(child)
		child.queue_free()
	for child in settings_box.get_children():
		settings_box.remove_child(child)
		child.queue_free()
	settings_box.hide()
	menu_buttons.show()

func button(text: String, action: Callable) -> void:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(440, 44)
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.add_theme_font_override("font", body_font)
	item.add_theme_font_size_override("font_size", 17)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15333d")
	style.border_color = gold
	style.border_width_left = 3
	style.content_margin_left = 18
	item.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("285360")
	item.add_theme_stylebox_override("hover", hover)
	item.add_theme_stylebox_override("focus", hover)
	item.pressed.connect(action)
	menu_buttons.add_child(item)

func show_title(record: int) -> void:
	mode = "title"
	best = record
	menu.show()
	hud.hide()
	clear_buttons()
	heading.text = "THE MIDNIGHT\nEXCHANGE"
	subtitle.text = "The last train carries things the world forgot.\nYou owe the conductor £600. Dawn is four and a half minutes away. Bring back something worth your freedom.\n\nBest exchange: £%d" % best
	button("BOARD A NEW NIGHT   →", func(): play_requested.emit(false))
	button("DAILY TICKET   /   SAME TRAIN FOR EVERYONE", func(): play_requested.emit(true))
	button("SETTINGS & CONTROLS", show_settings)

func show_pause() -> void:
	mode = "pause"
	menu.show()
	hud.hide()
	clear_buttons()
	heading.text = "A MOMENT\nBETWEEN STATIONS"
	subtitle.text = "The clock is stopped. Your freight is safe.\n\nWASD walk · Mouse look · Shift run · Ctrl sneak\nE collect / bank · F fold home · X drop selected\n1–5 select freight / choose an upgrade at the counter"
	button("RETURN TO THE NIGHT   →", func(): resume_requested.emit())
	button("SETTINGS", show_settings)
	button("ABANDON THIS TICKET", func(): quit_requested.emit())

func show_settings() -> void:
	clear_buttons()
	menu_buttons.hide()
	settings_box.show()
	heading.text = "MAKE YOURSELF\nCOMFORTABLE"
	subtitle.text = "Mouse sensitivity, sound level and optional camera motion.\nThese settings are saved locally. Escape returns to the game.\n\nHeadphones help you hear the conductor approaching.\nCargo names and text cues carry every color-coded effect."
	for entry in [["sensitivity", "Mouse sensitivity", 0.3, 2.0, 1.0], ["volume", "Sound volume", 0.0, 1.0, 0.65], ["motion", "Camera motion", 0.0, 1.0, 0.35]]:
		var row := HBoxContainer.new()
		settings_box.add_child(row)
		var text := Label.new()
		text.text = entry[1]
		text.custom_minimum_size.x = 220
		text.add_theme_font_override("font", body_font)
		row.add_child(text)
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(260, 30)
		slider.min_value = entry[2]
		slider.max_value = entry[3]
		slider.step = 0.05
		slider.value = float(get_meta(entry[0], entry[4]))
		var key: String = entry[0]
		slider.value_changed.connect(func(value: float):
			set_meta(key, value)
			setting_changed.emit(key, value))
		row.add_child(slider)
	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size.y = 40
	back.pressed.connect(func():
		if mode == "pause": show_pause()
		else: show_title(best))
	settings_box.add_child(back)

func show_result(run: MidnightRun, record: int) -> void:
	mode = "result"
	menu.show()
	hud.hide()
	clear_buttons()
	heading.text = "A DEBT PAID.\nA DAWN EARNED." if run.won else "SOME DEBTS\nOUTLIVE THE NIGHT."
	subtitle.text = "£%d exchanged  /  £%d required\n%d deliveries · %d folds · %d conductor encounters\nBest exchange: £%d\n\n%s\nTicket %d" % [run.banked, MidnightRun.TARGET, run.deliveries, run.folds, run.recovered, record, "You step off the train with your name intact." if run.won else "The conductor offers you another night. Pack differently.", run.seed_value]
	button("ANOTHER NIGHT   →", func(): play_requested.emit(false))
	button("REPLAY THIS TICKET", func(): play_requested.emit(true))
	button("RETURN TO TITLE", func(): quit_requested.emit())

func enter_game() -> void:
	menu.hide()
	hud.show()

func update(run: MidnightRun, car: int, energy: float, threat: float, message: String, is_sneaking: bool) -> void:
	room_label.text = "%02d / %s" % [car, MidnightTrain.NAMES[car]]
	bank_label.text = "£%d / £%d   •   held £%d" % [run.banked, MidnightRun.TARGET, run.held_value()]
	timer_label.text = "%d:%02d" % [int(ceil(run.remaining)) / 60, int(ceil(run.remaining)) % 60]
	timer_label.modulate = Color("f3a48e") if run.remaining < 40 else pale
	status_label.text = "TICKET %d   /   %s   /   COMPOSURE %d%%" % [run.seed_value, "MOVE QUIETLY" if is_sneaking else "NIGHT FREIGHT SERVICE", int(run.composure)]
	progress.value = 100.0 * run.banked / MidnightRun.TARGET
	stamina.value = energy
	manifest_label.text = "MANIFEST  %d/%d    •    BELLS MULTIPLY THE WHOLE DELIVERY    •    SELECT 1–5 / DROP X" % [run.inventory.size(), run.capacity]
	for index in range(inventory_labels.size()):
		var slot := inventory_labels[index]
		if index >= run.capacity:
			slot.text = ""
		elif index >= run.inventory.size():
			slot.text = "%d  ─ EMPTY" % (index + 1)
			slot.modulate = Color("71848b")
		else:
			var cargo: Dictionary = run.inventory[index]
			slot.text = "%s%d  %s\n     £%d" % ["› " if index == run.selected else "", index + 1, MidnightFreight.TYPES[cargo.kind], cargo.value]
			slot.modulate = MidnightFreight.COLORS[cargo.kind]
	prompt_label.text = message
	threat_label.text = "THE CONDUCTOR IS CLOSE  /  leave the aisle, hold Ctrl, keep quiet" if threat > 0.35 else ""
	danger.color.a = threat * 0.16
