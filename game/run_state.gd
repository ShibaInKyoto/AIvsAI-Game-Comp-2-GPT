class_name MidnightRun
extends RefCounted
## Simulation state is independent of rendering, physics and platform input.

const TARGET := 600
const DURATION := 270.0
const CAPACITY := 3
var seed_value := 0
var remaining := DURATION
var banked := 0
var inventory: Array[Dictionary] = []
var capacity := CAPACITY
var deliveries := 0
var recovered := 0
var folds := 0
var upgrades := 0
var upgrade_tokens := 0
var stride := 1.0
var ward := 0
var composure := 100.0
var finished := false
var won := false
var selected := 0
var collected_ids: Dictionary = {}
var pending_fares := 0
var commissions: Dictionary = {}

func begin(ticket: int) -> void:
	seed_value = ticket

func take(kind: int, value: int, serial: int) -> bool:
	if finished or inventory.size() >= capacity or collected_ids.has(serial):
		return false
	inventory.append({"kind": kind, "value": value, "serial": serial})
	collected_ids[serial] = true
	selected = inventory.size() - 1
	return true

func count_kind(kind: int) -> int:
	var count := 0
	for item in inventory:
		if item.kind == kind:
			count += 1
	return count

func held_value() -> int:
	var total := 0
	for item in inventory:
		total += int(item.value)
	return roundi(total * (1.0 + 0.25 * count_kind(1))) + pending_fares

func bank() -> int:
	if finished or (inventory.is_empty() and pending_fares == 0):
		return 0
	var earned := held_value()
	remaining = minf(remaining + count_kind(0) * 18.0, DURATION + 60)
	if count_kind(3) > 0:
		composure = 100
	pending_fares = 0
	banked += earned
	deliveries += 1
	if deliveries <= 2:
		upgrade_tokens += 1
	inventory.clear()
	selected = 0
	return earned

func fold() -> bool:
	if finished:
		return false
	for index in range(inventory.size()):
		if inventory[index].kind == 2:
			inventory.remove_at(index)
			folds += 1
			selected = mini(selected, maxi(0, inventory.size() - 1))
			return true
	return false

func upgrade(choice: int) -> bool:
	if finished or upgrade_tokens <= 0 or choice < 0 or choice > 2:
		return false
	upgrade_tokens -= 1
	upgrades += 1
	match choice:
		0: capacity += 1
		1: stride += 0.2
		2: ward += 1
	return true

func caught() -> void:
	if finished:
		return
	inventory.clear()
	selected = 0
	recovered += 1
	remaining = maxf(0, remaining - 15)
	composure = 100

func tick(delta: float) -> void:
	if finished:
		return
	remaining = maxf(0, remaining - delta)
	if remaining <= 0:
		finish()

func finish() -> void:
	finished = true
	won = banked >= TARGET

func trade(required_kind: int, fare: int, identity: int) -> bool:
	if finished or commissions.has(identity):
		return false
	for index in range(inventory.size()):
		if inventory[index].kind == required_kind:
			inventory.remove_at(index)
			selected = mini(selected, maxi(0, inventory.size() - 1))
			pending_fares += fare
			commissions[identity] = true
			return true
	return false
