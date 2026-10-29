class_name MidnightInterface
extends CanvasLayer
## One scalable 1280x720 canvas. Menus pause the simulation without blocking UI input.

signal play_requested(daily: bool)
signal ticket_requested(number: int)
signal resume_requested
signal quit_requested
signal exit_requested
signal setting_changed(key: String, value: float)
signal endless_requested
signal next_service_requested
signal shunt_requested(first: int, second: int)
signal route_page_requested
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
var feedback: ColorRect
var feedback_tween: Tween
var title_font := preload("res://assets/fonts/display.ttf")
var body_font := preload("res://assets/fonts/body.ttf")
var gold := Color("d8b77e")
var pale := Color("efe4cf")
var menu_buttons: VBoxContainer
var settings_box: VBoxContainer
var mode := "title"
var route_buttons: Control
var route_rows: Control
var route_commissions := false
var best := 0
var best_long := 0
var remembered := 0
var ticket_entry: LineEdit
var ticket_confirm: Button
var ticket_hint: Label

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	danger = rect(root, Vector2.ZERO, Vector2(1280, 720), Color(0.6, 0.05, 0.07, 0))
	feedback = rect(root, Vector2.ZERO, Vector2(1280, 720), Color(0, 0, 0, 0))
	feedback.hide()
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
	notice_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.85))
	notice_label.add_theme_constant_override("outline_size", 2)
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
	var guide := "01   TAKE WHAT SHOULD NOT EXIST\nExplore seven carriages. Carry three relics.\nDeeper freight pays more. E to collect.\n\n02   MAKE IT BACK TO THE COUNTER\nBank £600 before dawn to buy your freedom.\nUnbanked freight is lost when time runs out.\n\n03   PACK WITH INTENTION\nHours buy time. Bells boost carried freight.\nDoorways fold you home. Aurora calms you.\n\n04   THE CONDUCTOR IS LISTENING\nRun when safe. Sneak off the central aisle\nto pass him. Bells carry farther than footsteps.\nCaught? Freight resets; lose 15s, not savings.\n\n05   YOUR FIRST TWO DELIVERIES\nEarn a free upgrade at the exchange.\nT turns the train for 2 pressure and 10s.\nTab swaps neighbors for 1 pressure and 6s.\nEscape early with Q once your debt is paid."
	guide_text = guide
	guide_body = label(rules, Vector2(28, 70), guide, 14)
	guide_body.size = Vector2(354, 430)
	guide_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_rows = Control.new()
	route_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(route_rows)
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
	if is_instance_valid(route_rows):
		for child in route_rows.get_children():
			route_rows.remove_child(child)
			child.queue_free()
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

func button(text: String, action: Callable, target: Control = null) -> Button:
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
	item.add_theme_stylebox_override("pressed", hover)
	item.pressed.connect(action)
	(target if target != null else menu_buttons).add_child(item)
	return item

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
	subtitle.text = "The last train carries things the world forgot.\nYou owe the conductor £600. Dawn is four and a half minutes away. Bring back something worth your freedom.\n\nBest exchange: £%d  /  Best voyage: £%d\nTravelers remembered: %d / 4" % [best, best_long, memory_count()]
	button("BOARD A NEW NIGHT   →", func(): play_requested.emit(false))
	button("DAILY TICKET   /   SAME TRAIN FOR EVERYONE", func(): play_requested.emit(true))
	button("THE LONG WAY HOME   /   ENDLESS SERVICES", func(): endless_requested.emit())
	button("PORTER'S NOTEBOOK   /   GUIDE & MEMORIES", show_guide)
	button("SETTINGS", show_settings)
	button("QUIT", func(): exit_requested.emit())
	menu_buttons.position.y = 423
	menu_buttons.add_theme_constant_override("separation", 7)
	for item in menu_buttons.get_children():
		item.custom_minimum_size.y = 38
		item.add_theme_font_size_override("font_size", 15)
	var ticket := button("STAMP A TICKET NUMBER   →", show_ticket, route_buttons)
	ticket.position = Vector2(780, 626)
	ticket.custom_minimum_size = Vector2(410, 44)
	ticket.size = Vector2(410, 44)

func show_ticket() -> void:
	reset_guide()
	clear_buttons()
	mode = "ticket"
	heading.text = "ONE NUMBER.\nANOTHER NIGHT."
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.text = "Keep a favorite timetable, or pass its number to another porter. A stamped ticket starts a fresh run on the same train.\n\nThe clock starts when you board."
	guide_heading.text = "THE TICKET COUNTER"
	guide_body.text = "THE SAME NIGHT, ON PAPER\nA ticket fixes the starting carriage order and freight. Its number appears on the HUD and result screen.\n\nRETURN TO A FAVORITE NIGHT\nWrite the number down, then stamp it here to return to that starting train.\n\nPASS THE CHALLENGE ON\nTwo porters with the same ticket begin with the same opportunities. Your choices still change the journey.\n\nThe daily ticket uses today's UTC date. Stamped tickets use the ordinary £600 goal and clock."
	label(route_buttons, Vector2(94, 405), "TICKET NUMBER  /  1–999999999", 14).modulate = gold
	ticket_entry = LineEdit.new()
	ticket_entry.position = Vector2(94, 440)
	ticket_entry.size = Vector2(440, 54)
	ticket_entry.max_length = 12
	ticket_entry.placeholder_text = "Enter a ticket number"
	ticket_entry.add_theme_font_override("font", preload("res://assets/fonts/mono.ttf"))
	ticket_entry.add_theme_font_size_override("font_size", 26)
	ticket_entry.add_theme_color_override("font_color", pale)
	ticket_entry.add_theme_color_override("caret_color", gold)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15333d")
	style.border_color = gold
	style.set_border_width_all(1)
	style.content_margin_left = 16
	style.content_margin_right = 16
	ticket_entry.add_theme_stylebox_override("normal", style)
	var focus := style.duplicate() as StyleBoxFlat
	focus.set_border_width_all(2)
	ticket_entry.add_theme_stylebox_override("focus", focus)
	route_buttons.add_child(ticket_entry)
	ticket_hint = label(route_buttons, Vector2(94, 502), "", 13)
	ticket_confirm = button("STAMP AND BOARD   →", stamp_ticket)
	button("BACK TO THE PLATFORM", func(): show_title(best, best_long))
	menu_buttons.position.y = 548
	var previous_ticket := int(get_meta("last_ticket", 0))
	ticket_entry.text = str(previous_ticket) if previous_ticket > 0 else ""
	ticket_entry.text_changed.connect(update_ticket_form)
	ticket_entry.text_submitted.connect(func(_text: String): stamp_ticket())
	update_ticket_form(ticket_entry.text)
	call_deferred("focus_ticket_entry")

func focus_ticket_entry() -> void:
	if is_instance_valid(ticket_entry) and ticket_entry.is_visible_in_tree():
		ticket_entry.grab_focus()

func valid_ticket(text: String) -> bool:
	var value := text.strip_edges()
	return value.is_valid_int() and value.to_int() >= 1 and value.to_int() <= 999999999

func update_ticket_form(text: String) -> void:
	ticket_confirm.disabled = not valid_ticket(text)
	ticket_hint.text = "Ticket %d / ready to stamp." % text.to_int() if not ticket_confirm.disabled else "Use a whole number from 1 to 999999999."

func stamp_ticket() -> void:
	if is_instance_valid(ticket_entry) and valid_ticket(ticket_entry.text):
		ticket_requested.emit(ticket_entry.text.strip_edges().to_int())

func show_guide() -> void:
	reset_guide()
	clear_buttons()
	heading.text = "A PORTER'S\nFIELD GUIDE"
	subtitle.text = "WASD walk · Mouse look · Shift run · Ctrl sneak\nE collect / bank · F fold home · X drop selected\n1–5 select a slot · L toggle lantern\nTab route / switchboard · Escape pause\n\nThe clock starts when you board. You can pause at any time to read the route, settings or field guide."
	button("BACK TO THE PLATFORM   →", func(): show_title(best, best_long))
	var notebook := button("TRAVELERS REMEMBERED  %d/4   →" % memory_count(), func(): show_memories(-1), route_buttons)
	notebook.position = Vector2(780, 626)
	notebook.custom_minimum_size = Vector2(410, 44)
	notebook.size = Vector2(410, 44)

func memory_count() -> int:
	var count := 0
	for identity in range(MidnightPassenger.NAMES.size()):
		if (remembered & (1 << identity)) != 0:
			count += 1
	return count

func show_memories(selected: int = -1) -> void:
	if selected < 0:
		selected = 0
		for identity in range(MidnightPassenger.NAMES.size()):
			if (remembered & (1 << identity)) != 0:
				selected = identity
				break
	selected = clampi(selected, 0, MidnightPassenger.NAMES.size() - 1)
	reset_guide()
	clear_buttons()
	heading.text = "THE PEOPLE\nWE REMEMBER"
	subtitle.text = "Win a night after helping a traveler to remember their first morning. These memories stay in your notebook across tickets.\n\n%d / 4 travelers remembered.\nYou can help someone different on each journey." % memory_count()
	subtitle.add_theme_font_size_override("font_size", 17)
	guide_heading.text = MidnightPassenger.NAMES[selected]
	guide_body.add_theme_font_size_override("font_size", 16)
	var unlocked := (remembered & (1 << selected)) != 0
	if unlocked:
		guide_body.text = "REMEMBERED AT DAWN\n\n" + MidnightPassenger.MEMORIES[selected]
	else:
		guide_body.text = "STILL ABOARD THE TRAIN\n\n“%s”\n\nREQUESTED: %s\n\nHelp this traveler, bank £600 and reach dawn. Their first morning will be recorded here.\n\nThe paused route ledger shows their current carriage and offer." % [MidnightPassenger.REQUESTS[selected], MidnightFreight.TYPES[MidnightPassenger.NEEDS[selected]]]
	for identity in range(MidnightPassenger.NAMES.size()):
		var known := (remembered & (1 << identity)) != 0
		var chosen := identity
		var entry := button("%s%s   /   %s" % ["› " if identity == selected else "", MidnightPassenger.NAMES[identity].trim_prefix("THE "), "REMEMBERED" if known else "STILL ABOARD"], func(): show_memories(chosen))
		if identity == selected:
			entry.modulate = Color("b7d8ce")
	button("BACK TO THE FIELD GUIDE   →", show_guide)
	menu_buttons.position.y = 423
	menu_buttons.add_theme_constant_override("separation", 7)
	for entry in menu_buttons.get_children():
		entry.custom_minimum_size.y = 38
		entry.add_theme_font_size_override("font_size", 15)

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
	button("CREDITS & LICENSES", show_credits, settings_box)
	button("BACK", settings_back, settings_box)

func settings_back() -> void:
	if mode == "pause":
		show_pause()
	else:
		show_title(best, best_long)

func show_credits() -> void:
	# Keep the originating title/pause mode for consistent Back and Escape behavior.
	reset_guide()
	clear_buttons()
	heading.text = "THE MIDNIGHT\nWORKSHOP"
	subtitle.text = "The Midnight Exchange / version 1.0.0.\nCreated by Codex for the AIvsAI competition.\n\nModels, textures, icons, music and sound effects\nwere made for The Midnight Exchange.\n\nBuilt with Godot Engine 4.6.3 and DejaVu fonts."
	guide_heading.text = "ACKNOWLEDGMENTS"
	guide_body.text = "GODOT ENGINE\nMIT license. Copyright 2014–present Godot Engine contributors; 2007–2014 Juan Linietsky and Ariel Manzur.\n\nGODOT_LICENSE.txt contains the engine license. GODOT_THIRD_PARTY.txt contains its third-party notices.\n\nDEJAVU FONTS\nThe complete font notice is in FONT_LICENSE.txt.\n\nThese notices are included beside the executable in the game download."
	button("BACK TO SETTINGS   →", show_settings)

func show_result(run: MidnightRun, record: int, service := 0, total := 0, voyage_record := 0) -> void:
	reset_guide()
	subtitle.add_theme_font_override("font", body_font)
	subtitle.add_theme_font_size_override("font_size", 17)
	menu_shade.color.a = 0.65 if run.won else 0.91
	guide_heading.text = "THE FIRST MORNING" if run.won else "ANOTHER NIGHT"
	guide_body.add_theme_font_size_override("font_size", 16)
	var epilogue := "The train stops at a platform that was not on the timetable. The air smells of rain on warm stone.\n\n" if run.won else "The conductor closes his ledger. The fare you paid was not enough to buy back your name.\n\nHe offers you another ticket. You know the carriages now. You know what the bells cost.\n\nYou know there is a way home.\n\n"
	if not run.won and not run.commissions.is_empty():
		epilogue = "The conductor closes his ledger. The fare you paid was not enough to buy back your name.\n\n"
	for identity in run.commissions:
		epilogue += "%s\n%s\n\n" % [MidnightPassenger.NAMES[identity].trim_prefix("THE "), MidnightPassenger.THANKS[identity]]
	if run.won and run.commissions.is_empty():
		epilogue += "You step onto the platform alone. Behind the windows, the passengers watch you go.\n\nPerhaps, on another night, there will be time for them too."
	guide_body.text = epilogue.strip_edges()
	mode = "result"
	menu.show()
	hud.hide()
	clear_buttons()
	heading.text = "A DEBT PAID.\nA DAWN EARNED." if run.won else "SOME DEBTS\nOUTLIVE THE NIGHT."
	heading.add_theme_font_size_override("font_size", 60 if run.won else 56)
	subtitle.text = "£%d exchanged  /  £%d required\n%d deliveries · %d folds · %d encounters · %d helped\nBest exchange: £%d\n\n%s\nTicket %d" % [run.banked, MidnightRun.TARGET, run.deliveries, run.folds, run.recovered, run.commissions.size(), record, "You step off the train with your name intact." if run.won else "Each ticket starts fresh. Try another route, or pack differently.", run.seed_value]
	if run.won and not run.commissions.is_empty():
		subtitle.text += "\nTheir mornings await in the porter's notebook."
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

func flash(tint: Color, strength: float) -> void:
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()
	feedback.color = Color(tint, strength)
	feedback.show()
	feedback_tween = create_tween()
	feedback_tween.tween_property(feedback, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	feedback_tween.tween_callback(feedback.hide)

func update(run: MidnightRun, car: int, energy: float, threat: float, message: String, is_sneaking: bool) -> void:
	room_label.text = "%02d / %s" % [car, MidnightTrain.NAMES[car]]
	bank_label.text = "£%d / £%d   •   held £%d" % [run.banked, MidnightRun.TARGET, run.held_value()]
	timer_label.text = "%d:%02d" % [int(ceil(run.remaining)) / 60, int(ceil(run.remaining)) % 60]
	timer_label.modulate = Color("f3a48e") if run.remaining < 40 else pale
	status_label.text = "TICKET %d  /  COMPOSURE %d%%%s" % [run.seed_value, int(run.composure), "  /  SNEAKING" if is_sneaking else ""]
	progress.value = 100.0 * run.banked / MidnightRun.TARGET
	stamina.value = energy
	manifest_label.text = "MANIFEST  %d/%d    •    BELLS MULTIPLY CARRIED FREIGHT    •    SELECT 1–5 / DROP X" % [run.inventory.size(), run.capacity]
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

func show_route(train: MidnightTrain, freight: Array[MidnightFreight], run: MidnightRun, can_shunt := false, porter_slot := 0, commission_notes := "") -> void:
	reset_guide()
	mode = "route"
	menu.show()
	hud.hide()
	clear_buttons()
	heading.text = "THE TRAIN\nREMEMBERS"
	subtitle.add_theme_font_override("font", preload("res://assets/fonts/mono.ttf"))
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.text = "PRESSURE %d/6  /  SWAP 1 + 6s  /  %d:%02d\nPlanning pauses the clock. Swapping still costs six seconds." % [run.pressure, int(ceil(run.remaining)) / 60, int(ceil(run.remaining)) % 60]
	for slot in range(MidnightTrain.COUNT):
		var remaining := 0
		for cargo in freight:
			if not cargo.taken and clampi(roundi(-cargo.position.z / MidnightTrain.LENGTH), 0, 6) == slot:
				remaining += 1
		var row_y := 316 + slot * 40
		var here := slot == porter_slot
		var row := rect(route_rows, Vector2(94, row_y), Vector2(610, 38), Color("17373e") if here else Color("0d1e29"))
		if here:
			rect(row, Vector2.ZERO, Vector2(3, 38), gold)
		label(row, Vector2(12, 8), "%02d" % slot, 16).modulate = gold
		label(row, Vector2(53, 8), train.car_name(slot).trim_prefix("THE "), 16)
		label(row, Vector2(342, 10), "SANCTUARY" if slot == 0 else str(remaining) + " relics", 12).modulate = Color("9fcac2")
		if here:
			label(row, Vector2(438, 10), "YOU", 12).modulate = gold
	guide_heading.text = "RESONANCE COUPLINGS"
	guide_body.add_theme_font_size_override("font_size", 15)
	guide_body.text = "Some rooms remember each other. Place these carriages next to one another to awaken a resonance.\n\nOBSERVATORY + WINTER GARDEN\n%s\nBanking bottled aurora also grants 12 seconds per bottle.\n\nARCHIVE + CHOIR\n%s\nBells are muffled while you are inside either of these carriages.\n\nDINING ROOM + LAST CARRIAGE\n%s\nPassenger commissions offer 25%% larger sealed fares.\n\n%s" % ["AWAKE" if train.paired(1, 2) else "DORMANT", "AWAKE" if train.paired(4, 5) else "DORMANT", "AWAKE" if train.paired(3, 6) else "DORMANT", "Pressure: +1 for each £150 banked.\nT uses 2; each arrow uses 1." if can_shunt else "Return to the brass counter to operate the switchboard."]
	if route_commissions:
		guide_heading.text = "PASSENGER COMMISSIONS"
		guide_body.add_theme_font_size_override("font_size", 14)
		guide_body.text = commission_notes
	if can_shunt:
		for slot in range(1, MidnightTrain.COUNT):
			for direction in [-1, 1]:
				var neighbor: int = slot + direction
				if neighbor < 1 or neighbor >= MidnightTrain.COUNT:
					continue
				var item := Button.new()
				item.text = "↑" if direction < 0 else "↓"
				item.position = Vector2(584 if direction < 0 else 640, 318 + slot * 40)
				item.size = Vector2(48, 34)
				item.disabled = run.remaining <= 11 or run.pressure < 1
				item.tooltip_text = "Move carriage %s the exchange (1 pressure + 6s)" % ("toward" if direction < 0 else "away from")
				var normal := StyleBoxFlat.new()
				normal.bg_color = Color("15333d")
				normal.border_color = gold
				normal.set_border_width_all(1)
				item.add_theme_stylebox_override("normal", normal)
				var hover := normal.duplicate() as StyleBoxFlat
				hover.bg_color = Color("285360")
				item.add_theme_stylebox_override("hover", hover)
				item.add_theme_stylebox_override("focus", hover)
				item.add_theme_stylebox_override("pressed", hover)
				var disabled := normal.duplicate() as StyleBoxFlat
				disabled.bg_color = Color("101e27")
				disabled.border_color = Color("3b4c50")
				item.add_theme_stylebox_override("disabled", disabled)
				item.add_theme_color_override("font_color", pale)
				item.add_theme_color_override("font_disabled_color", Color("63777d"))
				item.add_theme_font_override("font", body_font)
				item.add_theme_font_size_override("font_size", 21)
				var chosen := slot
				var target := neighbor
				item.pressed.connect(func(): shunt_requested.emit(chosen, target))
				route_buttons.add_child(item)
	button("RETURN TO THE NIGHT   /   TAB OR ESC   →", func(): resume_requested.emit())
	menu_buttons.position.y = 626
	var ledger_toggle := button("RESONANCE COUPLINGS   →" if route_commissions else "PASSENGER COMMISSIONS   →", toggle_route_page, route_buttons)
	ledger_toggle.position = Vector2(780, 626)
	ledger_toggle.custom_minimum_size = Vector2(410, 44)
	ledger_toggle.size = Vector2(410, 44)

func toggle_route_page() -> void:
	route_commissions = not route_commissions
	route_page_requested.emit()

func reset_guide() -> void:
	if is_instance_valid(guide_body):
		guide_panel.show()
		heading.add_theme_font_size_override("font_size", 60)
		title_shade.hide()
		menu_buttons.position.y = 465
		menu_buttons.add_theme_constant_override("separation", 10)
		subtitle.add_theme_font_override("font", body_font)
		guide_body.text = guide_text
		guide_body.add_theme_font_size_override("font_size", 14)
		guide_heading.text = "A PORTER'S FIELD GUIDE"
		menu_shade.color.a = 0.91
