extends Label

signal button_down
signal button_up
signal pressed

@export var enabled:bool = true:
	set(value):
		enabled = value
		$Button.disabled = not enabled
		$Button.mouse_default_cursor_shape = CURSOR_POINTING_HAND if enabled else CURSOR_ARROW

@export var button_tooltip_text:String = '':
	set(value):
		button_tooltip_text = value
		$Button.tooltip_text = value
@export var hover_theme_type_variation:String = ''

@onready var _original_theme_type_variation:String = self.theme_type_variation


func _on_button_mouse_entered() -> void:
	if not enabled: return
	self.theme_type_variation = hover_theme_type_variation


func _on_button_mouse_exited() -> void:
	if not enabled: return
	self.theme_type_variation = _original_theme_type_variation


func _on_button_button_down() -> void:
	button_down.emit()


func _on_button_button_up() -> void:
	button_up.emit()


func _on_button_pressed() -> void:
	pressed.emit()
