@tool
extends PanelContainer

signal confirmed(data:Dictionary)
signal denied

@export var title:String = 'Create Playlist':
	set(v):
		title = v
		if not is_node_ready(): await ready
		%Title.text = v

@export var playlist_name:String = '':
	set(v):
		playlist_name = v
		if not is_node_ready(): await ready
		%Name.text = v

@export var cover_path:String = ''

@export var cover_texture: Texture2D:
	set(v):
		cover_texture = v
		if not is_node_ready(): await ready
		%Cover.texture = v


var cover_added:bool = false


func _on_yes_pressed() -> void:
	if %Name.text.is_empty(): return
	confirmed.emit({
		'name': %Name.text,
		'cover_path': cover_path,
		'texture': %Cover.texture if %Cover.texture is ImageTexture else null,
	})
	queue_free()


func _on_no_pressed() -> void:
	denied.emit()
	queue_free()


func _on_set_cover_pressed() -> void:
	DialogManager.popup_image_select(func(data:Dictionary) -> void:
		var path = data.get('path')
		var texture = data.get('texture')
		if texture is not ImageTexture or path is not String: return
		cover_path = path
		cover_texture = texture
		cover_added = true
		%'Set Cover'.hide()
	)


func _on_cover_mouse_entered() -> void:
	if cover_added: %'Set Cover'.show()


func _on_cover_mouse_exited() -> void:
	if cover_added: %'Set Cover'.hide()
