extends PanelContainer

signal selected
@onready var default_style:StyleBox = %Shadow.get_theme_stylebox('panel')
@onready var default_label_settings:LabelSettings = %Name.label_settings


func init(artist:DBArtist) -> void:
	%Name.text = artist.name
	%'Quad Image'.from_artist(artist)
	artist.get_cover_threaded(func(cover) -> void:
		if not cover: return
		if cover.get_size().x == 1: return
		%Image.texture = cover
		%Image.show()
		%'Quad Image'.queue_free()
	)


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

		var image:Image = %Image.texture.get_image()
		image.crop(1,1)
		var dominant_color := image.get_pixel(0,0)

		var style = default_style.duplicate()
		style.shadow_color = (default_style.shadow_color as Color).lerp(Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.45), value)
		style.shadow_size = lerpf(default_style.shadow_size, 14, value)
		%Shadow.remove_theme_stylebox_override('panel')
		%Shadow.add_theme_stylebox_override('panel', style)
