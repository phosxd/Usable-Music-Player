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
var card_scene:PackedScene = SessionManager.get_layout_theme_scene('Tracks/card')
const overlay_color := Color(0.25, 0.25, 0.25, 0.5)
@onready var options_popup:PopupMenu = %Options.get_popup()
var loaded_tracks:Array[DBTrack] = []
var album: DBAlbum


func _ready() -> void:
	options_popup.id_pressed.connect(_on_option_id_pressed)
	if not album:
		SessionManager.main_scene.set_tab('albums')


func init(album_:DBAlbum=null) -> void:
	if not album_: return
	album = album_
	%Title.text = album.name
	%Title.tooltip_text = album.name
	%Artist.text = album.artist.name if album.artist else 'None found'
	%Year.text = album.year
	album.get_cover_threaded(func(cover) -> void:
		%Icon.texture = cover if cover else DBAlbum.default_cover
	)
	var dominant_color = album.get_album_dominant_color()
	var dominant_colors = [
		dominant_color,
		album.palette.get('secondary', Color.WHITE),
		album.palette.get('trinary', Color.WHITE),
		album.palette.get('blend_full', Color.WHITE),
	]
	dominant_colors.shuffle()
	var mat = %Gradient.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))

	var runtime:float = 0
	var discs = album.get_tracks_in_order()
	for disc in discs:
		if discs.size() > 1:
			add_disc_sep(disc)
		for track:DBTrack in discs[disc]:
			loaded_tracks.append(track)
			runtime += track.length
			add_card(track)

	%'Track Count'.text = '%s Tracks' % loaded_tracks.size()
	%'Runtime'.text = '%s Minutes' % int(runtime/60.0)
	%'Genre'.text = ', '.join(album.genres) if not album.genres.is_empty() else 'No genre'
	%'Copyright'.text = album.copyright


func add_disc_sep(disc:String) -> void:
	var label := Label.new()
	label.label_settings = preload('res://Assets/primary_label_large.tres')
	label.text = 'Disc %s' % disc
	%'Track List'.add_spacer(false)
	%'Track List'.add_child(label)
	%'Track List'.add_spacer(false)


func add_card(track:DBTrack) -> void:
	if not card_scene: return
	var card:Control = card_scene.instantiate()
	card.selected.connect(_on_track_selected.bind(track))
	card.init(track)
	card.set_mode(1)
	%'Track List'.add_child(card)


func _on_track_selected(track:DBTrack) -> void:
	PlayerManager.queue.clear()
	for track_:DBTrack in loaded_tracks:
		PlayerManager.add_to_queue(track_, false)

	PlayerManager.set_current_track(PlayerManager.queue.find(track))
	if PlayerManager.is_shuffled:
		PlayerManager.shuffle_queue(track)
	PlayerManager.queue_updated.emit()
	PlayerManager.set_playing(true)


func _on_album_button_pressed() -> void:
	SessionManager.main_scene.go_back()


func _on_play_pressed() -> void:
	if loaded_tracks.is_empty(): return
	_on_track_selected(loaded_tracks[0])


func _on_artist_pressed() -> void:
	SessionManager.main_scene.set_tab('artist_page', album.artist)


func _on_option_id_pressed(id:int) -> void:
	match id:
		0: pass
		1: pass
		2:
			LibraryManager.rescan_album(album)
			SessionManager.main_scene.refresh_tab()
