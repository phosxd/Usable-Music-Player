class_name ContextMenu extends Node

signal id_pressed(id:int)
signal index_pressed(index:int)
signal closed()

var popup_menu := PopupMenu.new()


func _init(items:Array[Dictionary]) -> void:
	popup_menu.id_pressed.connect(_on_id_pressed)
	popup_menu.index_pressed.connect(_on_index_pressed)
	popup_menu.visibility_changed.connect(_on_visibility_changed)
	add_child(popup_menu)
	SessionManager.add_child(self)

	for item:Dictionary in items:
		var type = item.get('type')
		if type is not String: continue
		match type:
			'button':
				var text = item.get('text')
				var icon = item.get('icon')
				var checkable = item.get('checkable', false)
				if text is not String: continue
				if icon is Texture2D:
					if checkable: popup_menu.add_icon_check_item(icon, text)
					else: popup_menu.add_icon_item(icon, text)
				else:
					if checkable: popup_menu.add_check_item(text)
					else: popup_menu.add_item(text)


func show() -> void:
	var mouse_position:Vector2i = SessionManager.main_scene.get_global_mouse_position()
	popup_menu.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	popup_menu.popup(Rect2(
		mouse_position.x-50,
		mouse_position.y+10,
		0,
		0,
	))


func _process(_delta:float) -> void:
	if Input.is_action_just_pressed('right_click'):
		popup_menu.hide()


func _on_id_pressed(id:int) -> void:
	id_pressed.emit(id)


func _on_index_pressed(index:int) -> void:
	index_pressed.emit(index)


func _on_visibility_changed() -> void:
	if popup_menu.visible == false: closed.emit()
