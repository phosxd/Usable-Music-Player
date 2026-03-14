extends PanelContainer

signal selected
var default_style: StyleBox
@onready var default_label_settings:LabelSettings = %Name.label_settings

var album: DBAlbum


func init(album_:DBAlbum, display_data:String='') -> void:
	album = album_
	%Name.text = album.name
	%Artist.text = album.artist.name
	if not display_data.is_empty():
		%Artist.text = display_data
	%Image.texture = album.get_cover()


func _ready() -> void:
	if has_node('%Shadow'):
		default_style = %Shadow.get_theme_stylebox('panel')


func unload() -> void:
	Async.unload(%Grid.get_children(), (func(scene:Node) -> void:
		scene.queue_free()
	).bind(self))


func _on_button_pressed() -> void:
	selected.emit()


func _on_button_mouse_entered() -> void:
	if not has_node('%Animation'): return
	%Animation.play('Hover')


func _on_button_mouse_exited() -> void:
	if not has_node('%Animation'): return
	%Animation.play_backwards('Hover')


func hover(value:float=0) -> void:
	if value == 0:
		if has_node('%Shadow'):
			%Shadow.remove_theme_stylebox_override('panel')
			%Shadow.add_theme_stylebox_override('panel', default_style)
		%Name.label_settings = default_label_settings

	else:
		var new_label_settings:LabelSettings = %Name.label_settings.duplicate()
		new_label_settings.shadow_color = Color.TRANSPARENT.lerp(Color.WHITE, value)
		%Name.label_settings = new_label_settings

		var dominant_color:Color = album.get_album_dominant_color()

		if default_style:
			var style = default_style.duplicate()
			style.shadow_color = (default_style.shadow_color as Color).lerp(Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.5), value)
			style.shadow_size = lerpf(default_style.shadow_size, default_style.shadow_size+2, value)
			if has_node('%Shadow'):
				%Shadow.remove_theme_stylebox_override('panel')
				%Shadow.add_theme_stylebox_override('panel', style)


func _on_button_gui_input(event:InputEvent) -> void:
	if event.is_action_pressed('right_click'):
		pass
