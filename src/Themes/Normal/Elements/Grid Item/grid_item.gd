@tool
extends Control

## Emitted when the button or primary text is pressed.
signal pressed
## Emitted when the secondary text is pressed.
signal secondary_pressed
## Emitted when button is right clicked.
signal alt_pressed


@export var item_size := Vector2(175,175):
	set(value):
		item_size = value
		%Panel.custom_minimum_size = value
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
				if texture is not Texture2D && texture != null: return
			%'Grid Image'.show()
			%Image.hide()
			%'Grid Image'.from_array(value)

@export var primary_text:String = '':
	set(value):
		primary_text = value
		%'Label 1'.text = value
		%'Label 1'.button_tooltip_text = value
		%'Label 1'.enabled = not primary_text.is_empty()

@export var secondary_text:String = '':
	set(value):
		secondary_text = value
		%'Label 2'.text = value
		%'Label 2'.button_tooltip_text = value
		%'Label 2'.enabled = not secondary_text.is_empty()


func _ready() -> void:
	item_size = Vector2.ONE*SessionManager.grid_item_size


func _on_button_pressed() -> void:
	pressed.emit()


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_released('right_click'):
		alt_pressed.emit()


func _on_button_mouse_entered() -> void:
	if not %'Label 1': return
	%'Label 1'._on_button_mouse_entered()


func _on_button_mouse_exited() -> void:
	if not %'Label 1': return
	%'Label 1'._on_button_mouse_exited()


func _on_label_1_pressed() -> void:
	pressed.emit()


func _on_label_2_pressed() -> void:
	secondary_pressed.emit()
