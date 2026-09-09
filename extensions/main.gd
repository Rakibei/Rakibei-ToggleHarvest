extends "res://main.gd"

var config = ModLoaderConfig.get_current_config("Rakibei-HarvestToggle")
var modsfx: bool = config.data.get("harvestsfx", false)

func setup_harvest_signals(button: TextureButton):
	button.pressed.connect(_on_harvest_button_pressed.bind(button))
	button.mouse_entered.connect(_on_harvest_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_harvest_button_mouse_exited.bind(button))


func _is_harvest_toggled(button: TextureButton) -> bool:
	return bool(button.get_meta("harvest_toggled", false))


func _set_harvest_toggled(button: TextureButton, toggled: bool) -> void:
	button.set_meta("harvest_toggled", toggled)


func _start_harvest(button: TextureButton) -> void:
	var type = get_resource_type_from_button(button)
	if type == "":
		return

	var now = Time.get_ticks_msec()
	var cooldown = globals.get_player_click_cooldown_ms()

	_get_panel_by_type()
	var panel = panel_by_type.get(type)
	if panel and globals.inspiration_unlocked:
		_show_inspiration_glow(panel, globals.inspiration_time)

	harvest_held[button] = true

	ModLoaderLog.debug(str(modsfx), "HarvestToggle")
	if modsfx == true:
		match type:
			"wood": sfx.start_woodcut_sfx()
			"stone": sfx.start_stone_sfx()
			"fishing": sfx.start_fishing_sfx()
			"farm": sfx.start_farm_sfx()
			"hunting": sfx.start_hunting_sfx()
			"iron": sfx.start_iron_sfx()
			"gold": sfx.start_gold_sfx()
			"magic": sfx.start_magic_swamp_sfx()
		currently_playing_sound = type

	if now - last_harvest_time.get(button, 0) >= cooldown:
		perform_harvest(type, button)
	else:
		harvest_pending[button] = true


func _stop_harvest(button: TextureButton) -> void:
	var type = get_resource_type_from_button(button)
	harvest_held[button] = false
	harvest_pending[button] = false

	if type == "" or currently_playing_sound != type:
		return

	match type:
		"wood": sfx.stop_woodcut_sfx()
		"stone": sfx.stop_stone_sfx()
		"fishing": sfx.stop_fishing_sfx()
		"farm": sfx.stop_farm_sfx()
		"hunting": sfx.stop_hunting_sfx()
		"iron": sfx.stop_iron_sfx()
		"gold": sfx.stop_gold_sfx()
		"magic": sfx.stop_magic_swamp_sfx()
	currently_playing_sound = ""


func _on_harvest_button_pressed(button: TextureButton) -> void:
	# Clicking always controls the persistent toggle, even when hover-to-click
	# is enabled.
	if _is_harvest_toggled(button):
		_set_harvest_toggled(button, false)

		# If hover-to-click is enabled and the cursor is still over the button,
		# harvesting continues because the hover itself is still active. It will
		# stop when the cursor leaves.
		if not signal_manager.hover_to_click_enabled or not button.is_hovered():
			_stop_harvest(button)
		return

	# Only one resource can be persistently/actively harvested at a time.
	# Clicking another resource switches the toggle to that resource.
	for other_button in harvest_held.keys():
		if other_button == button:
			continue
		if harvest_held.get(other_button, false):
			_set_harvest_toggled(other_button, false)
			_stop_harvest(other_button)

	_set_harvest_toggled(button, true)

	# With hover enabled, mouse_entered may already have started harvesting.
	if not harvest_held.get(button, false):
		_start_harvest(button)


func _on_harvest_button_mouse_entered(button: TextureButton):
	if not signal_manager.hover_to_click_enabled:
		return

	if not button.has_focus():
		button.grab_focus()

	# If another resource has been explicitly toggled on, merely hovering over
	# a different resource should not interrupt or duplicate that harvesting.
	# Clicking this button will still switch the toggle to it.
	for other_button in harvest_held.keys():
		if other_button == button:
			continue
		if harvest_held.get(other_button, false) and _is_harvest_toggled(other_button):
			return

	# Clean up any other temporary hover harvest before starting this one.
	for other_button in harvest_held.keys():
		if other_button == button:
			continue
		if harvest_held.get(other_button, false) and not _is_harvest_toggled(other_button):
			_stop_harvest(other_button)

	if not harvest_held.get(button, false):
		_start_harvest(button)


func _on_harvest_button_mouse_exited(button: TextureButton):
	# Hover harvesting stops when the mouse leaves, but a clicked/toggled
	# harvest remains active until the button is clicked again (or another
	# resource is toggled on).
	if (
		signal_manager.hover_to_click_enabled
		and harvest_held.get(button, false)
		and not _is_harvest_toggled(button)
	):
		_stop_harvest(button)

	if button.has_focus():
		button.release_focus()
