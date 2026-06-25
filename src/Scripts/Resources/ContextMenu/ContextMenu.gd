class_name ContextMenu extends Resource

signal id_pressed(id:String)
signal index_pressed(index:int)
signal opened
signal closed

## Array of [ContextMenu] or [ContextMenuItem] resources.
@export_custom(PROPERTY_HINT_ARRAY_TYPE, 'ContextMenuItem,ContextMenu') var items: Array

var popup_menu := _ContextMenuPopup.new()
var current_instance_id:String = ''


func init() -> void:
	popup_menu.visibility_changed.connect(_on_visibility_changed)
	SessionManager.add_child(popup_menu)
	ContextMenu._build(items, popup_menu, _on_index_pressed)


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
	opened.emit()


static func _build(local_items:Array, popup_menu_node:PopupMenu, index_pressed_callback=null, id_map:Dictionary={}) -> void:
	for item in local_items:
		# Parse context menu.
		if item is ContextMenu:
			ContextMenu._build(item.items, popup_menu_node, null, id_map)

		# Parse context menu item.
		elif item is ContextMenuItem:
			var icon:Texture2D = SessionManager.get_icon(item.icon_name)
			match item.type:
				ContextMenuItem.ItemType.Button:
					if icon is Texture2D:
						if item.checkable: popup_menu_node.add_icon_check_item(icon, item.text)
						else: popup_menu_node.add_icon_item(icon, item.text)
					else:
						if item.checkable: popup_menu_node.add_check_item(item.text)
						else: popup_menu_node.add_item(item.text)
				ContextMenuItem.ItemType.SubMenu:
					var submenu := _ContextMenuPopup.new()
					ContextMenu._build(item.items, submenu, func(_sub_index:int, sub_id:String) -> void:
						if index_pressed_callback is not Callable: return
						index_pressed_callback.call(-1, sub_id)
					)
					popup_menu_node.add_submenu_node_item(item.text, submenu)
					if icon is Texture2D:
						popup_menu_node.set_item_icon(-1, icon)

			id_map.set(popup_menu_node.item_count-1, item.id)
		else: continue

	popup_menu_node.index_pressed.connect(func(index:int) -> void:
		if index_pressed_callback is not Callable: return
		index_pressed_callback.call(index, id_map.get(index))
	)


func _on_index_pressed(index:int, id:String) -> void:
	if index != -1: index_pressed.emit(index)
	if not id.is_empty(): id_pressed.emit(id)


func _on_visibility_changed() -> void:
	if popup_menu.visible == false: closed.emit()
