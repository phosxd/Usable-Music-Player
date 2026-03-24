extends Label

signal button_down
signal button_up
signal pressed

@export var enabled:bool = true:
	set(value):
		_original_label_settings = label_settings
		_on_button_mouse_exited()
		$Button.mouse_default_cursor_shape = CursorShape.CURSOR_ARROW
		enabled = value
@export var button_tooltip_text:String = '':
	set(value):
		button_tooltip_text = value
		$Button.tooltip_text = value

@export_category('On Hover')
## Font color to set when hovering.
@export var hover_font_color := Color.WHITE
## Outline color to set when hovering.
@export var hover_outline_color := Color.WHITE
## Outline size to [i]add[/i] when hovering.
@export var hover_outline_size:int = 1

var _original_label_settings: LabelSettings


func _on_button_mouse_entered() -> void:
	if not enabled: return
	_original_label_settings = label_settings
	var ls:LabelSettings = label_settings.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	ls.font_color = hover_font_color
	ls.outline_color = hover_outline_color
	ls.outline_size += hover_outline_size
	self.label_settings = ls


func _on_button_mouse_exited() -> void:
	if not enabled: return
	self.label_settings = _original_label_settings


func _on_button_button_down() -> void:
	button_down.emit()


func _on_button_button_up() -> void:
	button_up.emit()


func _on_button_pressed() -> void:
	pressed.emit()
