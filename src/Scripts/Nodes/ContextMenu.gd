class_name ContextMenu extends Node

signal id_pressed(id:String)
signal index_pressed(index:int)
signal closed()

var popup_menu := PopupMenu.new()
var current_instance_id:String = ''


func _init(items:Array[Dictionary]) -> void:
	popup_menu.visibility_changed.connect(_on_visibility_changed)
	add_child(popup_menu)
	SessionManager.add_child(self)
	_build(items, popup_menu, _on_index_pressed)


## Show the context menu with an instance ID.
func show(id:String) -> void:
	current_instance_id = id
	var mouse_position:Vector2i = SessionManager.main_scene.get_global_mouse_position()
	popup_menu.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	popup_menu.theme = ThemeManager.theme
	popup_menu.popup(Rect2(
		mouse_position.x-50,
		mouse_position.y+10,
		0,
		0,
	))


static func _build(items:Array, popup_menu_node:PopupMenu, index_pressed_callback=null) -> void:
	var id_map:Dictionary = {}
	for item in items:
		if item is not Dictionary: continue
		var type = item.get('type')
		if type is not String: continue
		var id = item.get('id')
		match type:
			'button':
				var text = item.get('text')
				var icon = item.get('icon')
				var checkable = item.get('checkable', false)
				if text is not String: continue
				if icon is Texture2D:
					if checkable: popup_menu_node.add_icon_check_item(icon, text)
					else: popup_menu_node.add_icon_item(icon, text)
				else:
					if checkable: popup_menu_node.add_check_item(text)
					else: popup_menu_node.add_item(text)
			'submenu':
				var text = item.get('text')
				var icon = item.get('icon')
				var subitems = item.get('items')
				if text is not String or subitems is not Array: continue
				var submenu := PopupMenu.new()
				ContextMenu._build(subitems, submenu, func(_sub_index:int, sub_id:String) -> void:
					if index_pressed_callback is not Callable: return
					index_pressed_callback.call(-1, sub_id)
				)
				popup_menu_node.add_submenu_node_item(text, submenu)
				if icon is Texture2D:
					popup_menu_node.set_item_icon(-1, icon)

		if id is String:
			id_map.set(popup_menu_node.item_count-1, id)

	popup_menu_node.index_pressed.connect(func(index:int) -> void:
		if index_pressed_callback is not Callable: return
		index_pressed_callback.call(index, id_map.get(index))
	)


func _process(_delta:float) -> void:
	if not popup_menu.visible: return
	if Input.is_action_just_pressed('right_click') or Input.is_action_just_pressed('left_click'):
		popup_menu.hide()


func _on_index_pressed(index:int, id:String) -> void:
	if index != -1: index_pressed.emit(index)
	if id: id_pressed.emit(id)


func _on_visibility_changed() -> void:
	if popup_menu.visible == false: closed.emit()
