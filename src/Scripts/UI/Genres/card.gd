extends PanelContainer

signal selected
const max_cover_count:int = 4
const image_size := Vector2(100,100)
@onready var default_style:StyleBox = %Shadow.get_theme_stylebox('panel')
@onready var default_label_settings:LabelSettings = %Name.label_settings
var albums: Array


func init(genre_name:String, albums_:Array) -> void:
	albums = albums_
	%Name.text = genre_name
	var count:int = 0
	for album:DBAlbum in albums:
		if album is not DBAlbum: continue
		count += 1
		if count > max_cover_count: break
		album.get_cover_threaded(func(cover) -> void:
			var image:TextureRectRounded = %Image.duplicate()
			image.texture = cover
			image.custom_minimum_size = image_size
			image.show()
			%'Image Grid'.add_child(image)
		)
	for i in range(max_cover_count-count):
		var image:TextureRectRounded = %Image.duplicate()
		image.custom_minimum_size = image_size
		image.show()
		%'Image Grid'.add_child(image)


func _on_button_pressed() -> void:
	selected.emit()


func _on_button_mouse_entered() -> void:
	%Animation.play('Hover')


func _on_button_mouse_exited() -> void:
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
