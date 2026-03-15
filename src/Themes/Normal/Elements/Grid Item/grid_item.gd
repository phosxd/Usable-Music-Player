@tool
extends Control

signal pressed
## Emitted when button is right clicked.
signal alt_pressed


@export var item_size := Vector2(175,175):
	set(value):
		item_size = value
		%Shadow.custom_minimum_size = value
		%Image.custom_minimum_size = value
		%'Grid Image'.custom_minimum_size = value-Vector2(8,8)
		%Button.custom_minimum_size = value

@export var images:Array = []:
	set(value):
		var image_count:int = value.size()
		if image_count == 0:
			%'Grid Image'.hide()
			%Image.hide()
		elif image_count == 1 && value[0] is Texture2D:
			%'Grid Image'.hide()
			%Image.show()
			%Image.texture = value[0]
		elif image_count > 1:
			for texture in value:
				if texture is not Texture2D: return
			%'Grid Image'.show()
			%Image.hide()
			%'Grid Image'.from_array(value)

@export var primary_text:String = '':
	set(value):
		primary_text = value
		%'Label 1'.text = value
		%'Label 1'.tooltip_text = value

@export var secondary_text:String = '':
	set(value):
		secondary_text = value
		%'Label 2'.text = value
		%'Label 2'.tooltip_text = value


func _on_button_pressed() -> void:
	pressed.emit()


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_released('right_click'):
		alt_pressed.emit()


func _on_button_mouse_entered() -> void:
	%'Label 1'.add_theme_constant_override('outline_size', 2)
	%'Label 1'.add_theme_color_override('font_outline_color', Color.WHITE)


func _on_button_mouse_exited() -> void:
	%'Label 1'.remove_theme_constant_override('outline_size')
	%'Label 1'.remove_theme_color_override('font_outline_color')
