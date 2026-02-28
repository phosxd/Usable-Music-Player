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
var artist: DBArtist


func _ready() -> void:
	if not artist:
		SessionManager.main_scene.set_tab('artists')


func init(artist_:DBArtist) -> void:
	if not artist_: return
	artist = artist_
	%Title.text = artist.name
	%Title.tooltip_text = artist.name
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

	for album_name in artist.album_names:
		var album = artist.get_album(album_name)
		if not album: continue
		loaded_albums.append(album)
		add_card(album)


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
