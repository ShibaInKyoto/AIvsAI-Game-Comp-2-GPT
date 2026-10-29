extends SceneTree
## Measure actual wrapped text, including the longest four-traveler endings.

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("check_results")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func check_results() -> void:
	var interface := MidnightInterface.new()
	root.add_child(interface)
	for won in [false, true]:
		for service in [0, 2]:
			for helped_mask in range(16):
				var run := MidnightRun.new()
				run.begin(90210)
				run.banked = 740 if won else 370
				for identity in range(4):
					if helped_mask & (1 << identity):
						run.commissions[identity] = true
				run.finish()
				interface.show_result(run, 740, service, 1360, 1800)
				# Container layout and font shaping complete on subsequent frames.
				await process_frame
				await process_frame
				var context := "won=%s service=%d helped=%d" % [won, service, helped_mask]
				expect(interface.guide_body.position.y + interface.guide_body.get_minimum_size().y <= interface.guide_panel.size.y - 18,
					"Result epilogue overflows its panel: " + context)
				expect(interface.subtitle.position.y + interface.subtitle.get_minimum_size().y <= interface.menu_buttons.position.y - 8,
					"Result summary overlaps its buttons: " + context)
				expect(interface.heading.position.x + interface.heading.get_minimum_size().x <= interface.guide_panel.position.x - 24,
					"Result heading crowds the epilogue panel: " + context)
	interface.queue_free()
	await process_frame
	print("INTERFACE %s: %d checks across all traveler combinations, win/loss and endless results" % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)
