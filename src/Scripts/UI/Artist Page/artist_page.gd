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
var loaded_tracks:Array[DBTrack] = []
var artist: DBArtist


func init(artist_:DBArtist) -> void:
	artist = artist_
	%Title.text = artist.name
	var dominant_color = artist.get_artist_dominant_color()
	var dominant_colors = [
		dominant_color,
		artist.palette.get('secondary', Color.WHITE),
		artist.palette.get('trinary', Color.WHITE),
		artist.palette.get('blend_full', Color.WHITE),
	]
	dominant_colors.shuffle()
	var mat = %Gradient.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))
		
	for i in artist.track_count:
		var track = artist.get_track(i)
		if track is not DBTrack: continue
		loaded_tracks.append(track)
		add_card(track)


func add_card(track:DBTrack) -> void:
	var card:Control = card_scene.instantiate()
	card.selected.connect(_on_track_selected.bind(track))
	card.init(track)
	%'Track List'.add_child(card)


func _on_track_selected(track:DBTrack) -> void:
	PlayerManager.queue.clear()
	for track_:DBTrack in loaded_tracks:
		PlayerManager.add_to_queue(track_)

	PlayerManager.set_current_track(PlayerManager.queue.find(track))
	if PlayerManager.is_shuffled:
		PlayerManager.shuffle_queue(track)
	PlayerManager.set_playing(true)


func _on_album_button_pressed() -> void:
	SessionManager.main_scene.go_back()
