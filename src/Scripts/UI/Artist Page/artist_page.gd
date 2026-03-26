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
@onready var card_scene:PackedScene = SessionManager.get_layout_theme_scene('Elements/Grid Item/Grid Item')
const overlay_color := Color(0.25, 0.25, 0.25, 0.5)
@onready var options_popup:PopupMenu = %Options.get_popup()
var loaded_albums:Array[DBAlbum] = []
var artist: DBArtist


func _ready() -> void:
	options_popup.id_pressed.connect(_on_option_id_pressed)
	if not artist:
		SessionManager.main_scene.set_tab('artists')


func init(artist_:DBArtist=null) -> void:
	if not artist_: return
	artist = artist_
	await ready
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

	var runtime:float = 0
	var track_count:int = 0
	for album:DBAlbum in artist.albums.values():
		loaded_albums.append(album)
		for track:DBTrack in album.tracks.values():
			track_count += 1
			runtime += track.length
		add_card(album)

	%'Album Count'.text = '%s Albums' % loaded_albums.size()
	%'Track Count'.text = '%s Tracks' % track_count
	var minutes:float = runtime/60.0
	var hours:float = minutes/60.0
	var remainder = fmod(minutes, 60.0)
	if int(hours) == 0:
		%'Runtime'.text = '%s Minutes' % int(remainder)
	else:
		%'Runtime'.text = '%s Hours %s Minutes' % [int(hours), int(remainder)]

	var stored_cover = artist.get_cover()
	if stored_cover && stored_cover.get_size().x != 1:
		%Icon.texture = stored_cover
		set_gradient(stored_cover)


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


func _on_option_id_pressed(id:int) -> void:
	match id:
		0: pass
		1: pass
		2:
			LibraryManager.rescan_artist(artist)
			SessionManager.main_scene.refresh_tab()
