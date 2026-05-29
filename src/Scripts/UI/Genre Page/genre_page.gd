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
@onready var card_scene := SessionManager.get_scene('Elements/Grid Item/Grid Item')
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
	await ready
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
	if not card_scene: return
	var card:Control = card_scene.instantiate()
	card.primary_text = album.name
	card.secondary_text = album.artist.name
	card.images = [album.get_cover()]
	card.pressed.connect(_on_album_pressed.bind(album))
	%'Album List'.add_child(card)


func _on_album_pressed(album:DBAlbum) -> void:
	SessionManager.main_scene.set_tab('album_page', album)


func _on_album_button_pressed() -> void:
	SessionManager.main_scene.go_back()


func _on_play_pressed() -> void:
	if loaded_albums.is_empty(): return
	var all_tracks:Array[DBTrack] = []
	for album:DBAlbum in loaded_albums:
		for disc:Array in album.get_tracks_in_order().values():
			all_tracks.append_array(disc)

	PlayerManager.set_queue_and_track(all_tracks, all_tracks[0])


func _on_shuffle_pressed() -> void:
	if loaded_albums.is_empty(): return
	var all_tracks:Array[DBTrack] = []
	for album:DBAlbum in loaded_albums:
		for disc:Array in album.get_tracks_in_order().values():
			all_tracks.append_array(disc)

	var track:DBTrack = all_tracks.pick_random()
	PlayerManager.set_queue_and_track(all_tracks, track)
	PlayerManager.shuffle_queue(track)
