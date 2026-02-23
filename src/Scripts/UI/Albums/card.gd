extends PanelContainer

signal selected
@onready var default_style:StyleBox = %Shadow.get_theme_stylebox('panel')
@onready var default_label_settings:LabelSettings = %Name.label_settings

var album: DBAlbum


func init(album_:DBAlbum, display_data:String='') -> void:
	album = album_
	%Name.text = album.name
	%Artist.text = album.artist.name
	if not display_data.is_empty():
		%Artist.text += ' - ' + display_data
	%Image.texture = album.get_cover()


func _on_button_pressed() -> void:
	selected.emit()


func _on_button_mouse_entered() -> void:
	if not %Animation: return
	%Animation.play('Hover')


func _on_button_mouse_exited() -> void:
	if not %Animation: return
	%Animation.play_backwards('Hover')


func hover(value:float=0) -> void:
	if value == 0:
		%Shadow.remove_theme_stylebox_override('panel')
		%Shadow.add_theme_stylebox_override('panel', default_style)
		%Name.label_settings = default_label_settings

	else:
		var new_label_settings:LabelSettings = %Name.label_settings.duplicate()
		new_label_settings.shadow_color = Color.TRANSPARENT.lerp(Color.WHITE, value)
		%Name.label_settings = new_label_settings

		var dominant_color:Color = album.get_album_dominant_color()

		var style = default_style.duplicate()
		style.shadow_color = (default_style.shadow_color as Color).lerp(Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.45), value)
		style.shadow_size = lerpf(default_style.shadow_size, 14, value)
		%Shadow.remove_theme_stylebox_override('panel')
		%Shadow.add_theme_stylebox_override('panel', style)
