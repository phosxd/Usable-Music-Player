extends Control

signal closed

var library_buttons:Array[CheckBox] = []


func close() -> void:
	closed.emit()
	self.queue_free()


func _ready() -> void:
	for library:DBLibrary in LibraryManager.libraries:
		var button := CheckBox.new()
		button.theme_type_variation = 'AccentButton'
		button.flat = true
		button.text = library.name
		button.tooltip_text = library.name
		button.button_pressed = not library.hidden
		button.toggled.connect(_on_library_toggled.bind(library))
		button.gui_input.connect(_on_library_button_gui_input.bind(button))
		button.icon = library.get_icon()
		button.add_theme_constant_override('icon_max_width',16)
		# Add button.
		$VBox.add_child(button)
		$VBox.move_child(button, -3)
		library_buttons.append(button)


func _on_toggle_all_libraries_toggled(toggled_on:bool) -> void:
	for button:CheckBox in library_buttons:
		button.button_pressed = toggled_on


func _on_library_toggled(toggled_on:bool, library:DBLibrary) -> void:
	library.hidden = not toggled_on
	if library_buttons.size() > 1 && not toggled_on:
		%'Toggle All Libraries'.set_pressed_no_signal(false)
	SessionManager.main_scene.refresh_tab()


func _on_library_button_gui_input(event:InputEvent, button:CheckBox) -> void:
	if event.is_action_released('right_click'):
		button.button_pressed = true
		for button_2:CheckBox in library_buttons:
			if button_2 == button: continue
			button_2.button_pressed = false


func _on_console_pressed() -> void:
	DialogManager.popup_console()
	close()
