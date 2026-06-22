extends Control

@export var tab_config:Dictionary[String,Variant] = {
	'sort_mode': {
		'enabled': false,
	},
	'ascend_mode': {
		'enabled': false,
	},
	'search': {
		'enabled': true,
		'callback': _on_search_updated,
	}
}
@onready var card_scene:PackedScene = SessionManager.get_scene('Tracks/card')
const overlay_color := Color(0.25, 0.25, 0.25, 0.5)
@onready var options_popup:PopupMenu = %Options.get_popup()
var loaded_tracks:Array[DBTrack] = []
var playlist: DBPlaylist


func _ready() -> void:
	options_popup.id_pressed.connect(_on_option_id_pressed)
	if not playlist:
		SessionManager.main_scene.go_back()


func init(playlist_:DBPlaylist=null) -> void:
	if not playlist_: return
	playlist = playlist_
	await ready
	%Title.text = playlist.id
	%Title.tooltip_text = playlist.id
	%'Created Date'.text = playlist.created_date
	%'Last Edit Date'.text = playlist.last_edit_date
	var cover = playlist.get_cover()
	%Icon.texture = cover if cover else DBAlbum.default_cover
	var dominant_color = playlist.get_cover_dominant_color()
	var dominant_colors = [
		dominant_color,
		playlist.palette.get('secondary', Color.WHITE),
		playlist.palette.get('trinary', Color.WHITE),
		playlist.palette.get('blend_full', Color.WHITE),
	]
	dominant_colors.shuffle()
	var mat = %Gradient.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))

	sort()


func sort() -> void:
	for child in %'Track List'.get_children():
		child.queue_free()

	var runtime:float = 0
	for track:DBTrack in playlist.get_tracks():
		loaded_tracks.append(track)
		runtime += track.length
		add_card(track)

	%'Track Count'.text = '%s Tracks' % loaded_tracks.size()
	%'Runtime'.text = '%s Minutes' % int(runtime/60.0)


func add_card(track:DBTrack) -> void:
	if not card_scene: return
	var card:Control = card_scene.instantiate()
	card.selected.connect(_on_track_selected.bind(track))
	card.init(track)
	card.set_mode(1)
	%'Track List'.add_child(card)


func _on_search_updated(_text:String) -> void:
	pass


func _on_track_selected(track:DBTrack) -> void:
	PlayerManager.set_queue_and_track(loaded_tracks, track)


func _on_album_button_pressed() -> void:
	SessionManager.main_scene.go_back()


func _on_play_pressed() -> void:
	if loaded_tracks.is_empty(): return
	_on_track_selected(loaded_tracks[0])


func _on_shuffle_pressed() -> void:
	if loaded_tracks.is_empty(): return
	var track:DBTrack = loaded_tracks.pick_random()
	PlayerManager.set_queue_and_track(loaded_tracks, track)
	PlayerManager.shuffle_queue(track)


func _on_option_id_pressed(id:int) -> void:
	match id:
		# Play next.
		0:
			pass
		# Add to queue.
		1:
			pass
		# Rescan.
		2:
			pass


func _on_add_pressed() -> void:
	DialogManager.popup_custom(DialogManager.select_tracks_scene.instantiate(), func(data:Dictionary) -> void:
		var tracks:Array[DBTrack] = data.get('selected_tracks')
		for track:DBTrack in tracks:
			playlist.track_ids.append(track.as_id())

		sort()
	)
