extends Control

@export var tab_config:Dictionary[String,Variant] = {
	'sort_mode': {
		'enabled': false,
	},
	'ascend_mode': {
		'enabled': false,
	},
	'search': {
		'enabled': false,
	}
}
var card_scene:PackedScene = SessionManager.get_layout_theme_scene('albums_card')
const overlay_color := Color(0.25, 0.25, 0.25, 0.5)
var loaded_albums:Array[DBAlbum] = []
var albums: Array


func _ready() -> void:
	if not albums:
		SessionManager.main_scene.set_tab('genres')


func init(data:Dictionary={}) -> void:
	var genre_name = data.get('genre_name')
	var albums_ = data.get('albums')
	if genre_name is not String: return
	if albums_ is not Array: return
	albums = albums_
	%Title.text = genre_name
	%Title.tooltip_text = genre_name
	var dominant_colors = [
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
	]
	dominant_colors.shuffle()
	var mat = %Gradient.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))

	for album in albums:
		if album is not DBAlbum: continue
		loaded_albums.append(album)
		add_card(album)


func set_gradient(image:ImageTexture) -> void:
	var colors = DBAlbum.calculate_colors(image)
	var dominant_colors = [
		colors.get('blend_full', Color.WHITE),
		colors.get('primary', Color.WHITE),
		colors.get('secondary', Color.WHITE),
		colors.get('trinary', Color.WHITE),
	]
	dominant_colors.shuffle()
	var mat = %Gradient.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))


func add_card(album:DBAlbum) -> void:
	var card:Control = card_scene.instantiate()
	card.selected.connect(_on_album_selected.bind(album))
	card.init(album)
	%'Album List'.add_child(card)


func _on_album_selected(album:DBAlbum) -> void:
	SessionManager.main_scene.set_tab('album_page', album)


func _on_album_button_pressed() -> void:
	SessionManager.main_scene.go_back()


func _on_play_pressed() -> void:
	if loaded_albums.is_empty(): return
	for album:DBAlbum in loaded_albums:
		var tracks:Array[DBTrack] = album.get_all_tracks()
		
