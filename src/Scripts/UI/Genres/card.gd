extends PanelContainer

signal selected
const image_size := Vector2(100,100)
var default_style: StyleBox
@onready var default_label_settings:LabelSettings = %Name.label_settings
var albums: Array


func _ready() -> void:
	if has_node('%Shadow'):
		default_style = %Shadow.get_theme_stylebox('panel')


func init(genre_name:String, albums_:Array) -> void:
	albums = albums_
	%Name.text = genre_name

	if %'Quad Image': # "has_node" does not work here for some reason, so gonna have to deal with an error everytime it is not found.
		var covers:Array[ImageTexture] = []
		var count:int = 0
		for album:DBAlbum in albums:
			if album is not DBAlbum: continue
			count += 1
			if count > 4: break
			var cover = album.get_cover()
			if cover is not ImageTexture: continue
			covers.append(cover)
		%'Quad Image'.from_array(covers)


func _on_button_pressed() -> void:
	selected.emit()


func _on_button_mouse_entered() -> void:
	var new_label_settings:LabelSettings = %Name.label_settings.duplicate()
	new_label_settings.shadow_size = 2
	new_label_settings.shadow_color = Color.WHITE
	%Name.label_settings = new_label_settings


func _on_button_mouse_exited() -> void:
	%Name.label_settings = default_label_settings
