class_name MidnightInterface
extends CanvasLayer
## One scalable 1280x720 canvas. Menus pause the simulation without blocking UI input.

signal play_requested(daily: bool)
signal resume_requested
signal quit_requested
signal exit_requested
signal setting_changed(key: String, value: float)
signal endless_requested
signal next_service_requested
signal shunt_requested(first: int, second: int)
var root: Control
var hud: Control
var menu: Control
var menu_shade: ColorRect
var title_shade: TextureRect
var guide_panel: Control
var guide_body: Label
var guide_heading: Label
var guide_text := ""
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
var inventory_icons: Array[TextureRect] = []
var inventory_panels: Array[ColorRect] = []
const ICONS := [preload("res://assets/icons/hour.svg"), preload("res://assets/icons/bell.svg"), preload("res://assets/icons/door.svg"), preload("res://assets/icons/aurora.svg")]
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
var route_buttons: Control
var best := 0
var best_long := 0

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
		var panel := rect(bottom, Vector2(12 + i * 244, 60), Vector2(236, 55), Color(0.055, 0.09, 0.11, 0.75))
		inventory_panels.append(panel)
		var icon := TextureRect.new()
		icon.position = Vector2(20 + i * 244, 67)
		icon.size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom.add_child(icon)
		inventory_icons.append(icon)
		var slot := label(bottom, Vector2(60 + i * 244, 64), "", 14)
		slot.size = Vector2(186, 55)
		inventory_labels.append(slot)
	label(bottom, Vector2(18, 122), "WASD  WALK     SHIFT  RUN     CTRL  SNEAK     E  INTERACT     F  FOLD HOME     TAB  ROUTE     X  DROP     T  TIMETABLE     ESC  PAUSE", 11)
	stamina = bar(hud, Vector2(1050, 520), Vector2(200, 4), Color("9fcac2"))
	notice_label = label(hud, Vector2(160, 438), "", 21, true)
	notice_label.size = Vector2(960, 84)
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu = Control.new()
	root.add_child(menu)
	menu_shade = rect(menu, Vector2.ZERO, Vector2(1280, 720), Color(0.018, 0.032, 0.05, 0.91))
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0, 0.43, 0.70, 1])
	gradient.colors = PackedColorArray([Color(0.018, 0.032, 0.05, 0.98), Color(0.018, 0.032, 0.05, 0.94), Color(0.018, 0.032, 0.05, 0.1), Color(0.018, 0.032, 0.05, 0)])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 1280
	gradient_texture.height = 1
	title_shade = TextureRect.new()
	title_shade.texture = gradient_texture
	title_shade.size = Vector2(1280, 720)
	title_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(title_shade)
	rect(menu, Vector2(62, 55), Vector2(2, 620), gold)
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
	guide_panel = rules
	rect(rules, Vector2(0, 0), Vector2(410, 2), gold)
	guide_heading = label(rules, Vector2(28, 24), "A PORTER'S FIELD GUIDE", 22, true)
	var guide := "01   TAKE WHAT SHOULD NOT EXIST\nExplore seven carriages. Carry three relics.\nDeeper freight pays more. E to collect.\n\n02   MAKE IT BACK TO THE COUNTER\nBank £600 before dawn to buy your freedom.\nUnbanked freight is lost when time runs out.\n\n03   PACK WITH INTENTION\nHours buy time. Bells multiply a delivery.\nDoorways fold you home. Aurora calms you.\n\n04   THE CONDUCTOR IS LISTENING\nRun when safe. Sneak off the central aisle\nto pass him. Bells carry farther than footsteps.\nCaught? Freight resets; lose 15s, not savings.\n\n05   YOUR FIRST TWO DELIVERIES\nEarn a free upgrade at the exchange.\nT turns the train for 2 pressure and 10s.\nTab swaps neighbors for 1 pressure and 6s.\nEscape early with Q once your debt is paid."
	guide_text = guide
	guide_body = label(rules, Vector2(28, 70), guide, 14)
	guide_body.size = Vector2(354, 430)
	guide_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_buttons = Control.new()
	menu.add_child(route_buttons)
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
	if is_instance_valid(route_buttons):
		for child in route_buttons.get_children():
			route_buttons.remove_child(child)
			child.queue_free()
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

func show_title(record: int, voyage_record := 0) -> void:
	reset_guide()
	guide_panel.hide()
	title_shade.show()
	menu_shade.color.a = 0.12
	subtitle.add_theme_font_size_override("font_size", 17)
	mode = "title"
	best = record
	best_long = voyage_record
	menu.show()
	hud.hide()
	clear_buttons()
	heading.text = "THE MIDNIGHT\nEXCHANGE"
	subtitle.text = "The last train carries things the world forgot.\nYou owe the conductor £600. Dawn is four and a half minutes away. Bring back something worth your freedom.\n\nBest exchange: £%d  /  Best voyage: £%d" % [best, best_long]
	button("BOARD A NEW NIGHT   →", func(): play_requested.emit(false))
	button("DAILY TICKET   /   SAME TRAIN FOR EVERYONE", func(): play_requested.emit(true))
	button("THE LONG WAY HOME   /   ENDLESS SERVICES", func(): endless_requested.emit())
	button("HOW TO PLAY   /   PORTER'S FIELD GUIDE", show_guide)
	button("SETTINGS", show_settings)
	button("QUIT", func(): exit_requested.emit())
	menu_buttons.position.y = 423
	menu_buttons.add_theme_constant_override("separation", 7)
	for item in menu_buttons.get_children():
		item.custom_minimum_size.y = 38
		item.add_theme_font_size_override("font_size", 15)

func show_guide() -> void:
	reset_guide()
	clear_buttons()
	heading.text = "A PORTER'S\nFIELD GUIDE"
	subtitle.text = "WASD walk · Mouse look · Shift run · Ctrl sneak\nE collect / bank · F fold home · X drop selected\n1–5 select a slot · L toggle lantern\nTab route / switchboard · Escape pause\n\nThe clock starts when you board. You can pause at any time to read the route, settings or field guide."
	button("BACK TO THE PLATFORM   →", func(): show_title(best, best_long))

func show_pause() -> void:
	reset_guide()
	subtitle.add_theme_font_size_override("font_size", 17)
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
	reset_guide()
	subtitle.add_theme_font_size_override("font_size", 17)
	clear_buttons()
	menu_buttons.hide()
	settings_box.show()
	heading.text = "MAKE YOURSELF\nCOMFORTABLE"
	subtitle.text = "Mouse sensitivity, sound level and optional camera motion.\nThese settings are saved locally. Back returns to the menu. Escape resumes a paused journey.\n\nHeadphones help you hear the conductor approaching.\nCargo names and text cues carry every color-coded effect."
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
		else: show_title(best, best_long))
	settings_box.add_child(back)

func show_result(run: MidnightRun, record: int, service := 0, total := 0, voyage_record := 0) -> void:
	reset_guide()
	subtitle.add_theme_font_override("font", body_font)
	subtitle.add_theme_font_size_override("font_size", 17)
	menu_shade.color.a = 0.65 if run.won else 0.91
	guide_heading.text = "THE FIRST MORNING" if run.won else "ANOTHER NIGHT"
	guide_body.add_theme_font_size_override("font_size", 16)
	var epilogue := "The train stops at a platform that was not on the timetable. The air smells of rain on warm stone.\n\n" if run.won else "The conductor closes his ledger. The fare you paid was not enough to buy back your name.\n\nHe offers you another ticket. You know the carriages now. You know what the bells cost.\n\nYou know there is a way home.\n\n"
	for identity in run.commissions:
		epilogue += "%s\n%s\n\n" % [MidnightPassenger.NAMES[identity].trim_prefix("THE "), MidnightPassenger.THANKS[identity]]
	if run.won and run.commissions.is_empty():
		epilogue += "You step onto the platform alone. Behind the windows, the passengers watch you go.\n\nPerhaps, on another night, there will be time for them too."
	guide_body.text = epilogue
	mode = "result"
	menu.show()
	hud.hide()
	clear_buttons()
	heading.text = "A DEBT PAID.\nA DAWN EARNED." if run.won else "SOME DEBTS\nOUTLIVE THE NIGHT."
	subtitle.text = "£%d exchanged  /  £%d required\n%d deliveries · %d folds · %d encounters · %d helped\nBest exchange: £%d\n\n%s\nTicket %d" % [run.banked, MidnightRun.TARGET, run.deliveries, run.folds, run.recovered, run.commissions.size(), record, "You step off the train with your name intact." if run.won else "Each ticket starts fresh. Try another route, or pack differently.", run.seed_value]
	if service > 0:
		subtitle.add_theme_font_size_override("font_size", 15)
		subtitle.text += "\nService %d • Voyage £%d • Best £%d" % [service, total, voyage_record]
		if run.won:
			button("NEXT SERVICE   /   THE LONG WAY HOME   →", func(): next_service_requested.emit())
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
	status_label.text = "TICKET %d  /  COMPOSURE %d%%%s" % [run.seed_value, int(run.composure), "  /  SNEAKING" if is_sneaking else ""]
	progress.value = 100.0 * run.banked / MidnightRun.TARGET
	stamina.value = energy
	manifest_label.text = "MANIFEST  %d/%d    •    BELLS MULTIPLY THE WHOLE DELIVERY    •    SELECT 1–5 / DROP X" % [run.inventory.size(), run.capacity]
	for index in range(inventory_labels.size()):
		var slot := inventory_labels[index]
		inventory_icons[index].hide()
		inventory_panels[index].visible = index < run.capacity
		inventory_panels[index].color = Color(0.055, 0.09, 0.11, 0.75)
		if index >= run.capacity:
			slot.text = ""
		elif index >= run.inventory.size():
			slot.text = "%d  ─ EMPTY" % (index + 1)
			slot.modulate = Color("71848b")
		else:
			var cargo: Dictionary = run.inventory[index]
			inventory_icons[index].texture = ICONS[cargo.kind]
			inventory_icons[index].show()
			if index == run.selected:
				inventory_panels[index].color = Color(0.10, 0.19, 0.21, 0.9)
			slot.text = "%s%d  %s\n     £%d" % ["› " if index == run.selected else "", index + 1, MidnightFreight.TYPES[cargo.kind], cargo.value]
			slot.modulate = MidnightFreight.COLORS[cargo.kind]
	prompt_label.text = message
	threat_label.text = "THE CONDUCTOR IS CLOSE  /  leave the aisle, hold Ctrl, keep quiet" if threat > 0.35 else ""
	danger.color.a = threat * 0.16

func show_route(train: MidnightTrain, freight: Array[MidnightFreight], run: MidnightRun, can_shunt := false, porter_slot := 0) -> void:
	reset_guide()
	mode = "route"
	menu.show()
	hud.hide()
	clear_buttons()
	heading.text = "THE TRAIN\nREMEMBERS"
	subtitle.add_theme_font_override("font", preload("res://assets/fonts/mono.ttf"))
	subtitle.add_theme_font_size_override("font_size", 15)
	var lines := "PRESSURE %d/6  /  SWAP 1 + 6s  /  %d:%02d\n\n" % [run.pressure, int(ceil(run.remaining)) / 60, int(ceil(run.remaining)) % 60]
	for slot in range(MidnightTrain.COUNT):
		var remaining := 0
		for cargo in freight:
			if not cargo.taken and clampi(roundi(-cargo.position.z / MidnightTrain.LENGTH), 0, 6) == slot:
				remaining += 1
		lines += "%02d   %-23s   %s%s\n" % [slot, train.car_name(slot).trim_prefix("THE "), "SANCTUARY" if slot == 0 else str(remaining) + " relics", " [YOU]" if slot == porter_slot else ""]
	subtitle.text = lines
	guide_heading.text = "RESONANCE COUPLINGS"
	guide_body.add_theme_font_size_override("font_size", 15)
	guide_body.text = "Some rooms remember each other. Place these carriages next to one another to awaken a resonance.\n\nOBSERVATORY + WINTER GARDEN\n%s\nBanking bottled aurora also grants 12 seconds per bottle.\n\nARCHIVE + CHOIR\n%s\nBells are muffled while you are inside either of these carriages.\n\nDINING ROOM + LAST CARRIAGE\n%s\nPassenger commissions offer 25%% larger sealed fares.\n\n%s" % ["AWAKE" if train.paired(1, 2) else "DORMANT", "AWAKE" if train.paired(4, 5) else "DORMANT", "AWAKE" if train.paired(3, 6) else "DORMANT", "Pressure: +1 for each £150 banked.\nT uses 2; each arrow uses 1." if can_shunt else "Return to the brass counter to operate the switchboard."]
	if can_shunt:
		for slot in range(1, MidnightTrain.COUNT):
			for direction in [-1, 1]:
				var neighbor: int = slot + direction
				if neighbor < 1 or neighbor >= MidnightTrain.COUNT:
					continue
				var item := Button.new()
				item.text = "↑" if direction < 0 else "↓"
				item.position = Vector2(525 if direction < 0 else 567, 308 + slot * 20)
				item.size = Vector2(36, 20)
				item.disabled = run.remaining <= 11 or run.pressure < 1
				item.tooltip_text = "Move carriage toward the exchange (6s)" if direction < 0 else "Move carriage away from the exchange (6s)"
				var normal := StyleBoxFlat.new()
				normal.bg_color = Color("15333d")
				normal.border_color = gold
				normal.set_border_width_all(1)
				item.add_theme_stylebox_override("normal", normal)
				var hover := normal.duplicate() as StyleBoxFlat
				hover.bg_color = Color("285360")
				item.add_theme_stylebox_override("hover", hover)
				item.add_theme_font_override("font", body_font)
				item.add_theme_font_size_override("font_size", 13)
				var chosen := slot
				var target := neighbor
				item.pressed.connect(func(): shunt_requested.emit(chosen, target))
				route_buttons.add_child(item)
	button("RETURN TO THE NIGHT   /   TAB OR ESC   →", func(): resume_requested.emit())

func reset_guide() -> void:
	if is_instance_valid(guide_body):
		guide_panel.show()
		title_shade.hide()
		menu_buttons.position.y = 465
		menu_buttons.add_theme_constant_override("separation", 10)
		subtitle.add_theme_font_override("font", body_font)
		guide_body.text = guide_text
		guide_body.add_theme_font_size_override("font_size", 14)
		guide_heading.text = "A PORTER'S FIELD GUIDE"
		menu_shade.color.a = 0.91
