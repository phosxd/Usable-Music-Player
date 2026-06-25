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
	%'Created Date'.text = StringUtils.get_readable_date(playlist.created_date)
	%'Last Edit Date'.text = ''
	if not playlist.last_edit_date.is_empty():
		%'Last Edit Date'.text = 'Modified: '+StringUtils.get_readable_date(playlist.last_edit_date)
	var cover = playlist.get_cover()
	%Icon.texture = cover if cover else DBAlbum.default_cover
	update_gradient()

	sort()


func update_gradient() -> void:
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


func sort() -> void:
	loaded_tracks.clear()
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
	card.context_menu_name = 'playlist_card'
	card.details_scene_name = 'Playlist Page/card_details'
	card.set_meta('playlist', playlist)
	card.set_meta('scene', self)
	card.init(track)
	card.selected.connect(_on_track_selected.bind(track))
	%'Track List'.add_child(card)


func edit_details() -> void:
	var scene:Control = DialogManager.create_playlist_scene.instantiate()
	scene.title = 'Edit Details'
	scene.playlist_name = playlist.id
	scene.cover_path = playlist.cover_path
	scene.cover_texture = %Icon.texture
	DialogManager.popup_custom(scene, func(data:Dictionary) -> void:
		playlist.last_edit_date = DBPlaylist.get_current_date()
		%'Last Edit Date'.text = 'Modified: '+StringUtils.get_readable_date(playlist.last_edit_date)

		# Rename playlist.
		var playlist_order:PackedStringArray = SessionManager.get_var('playlist_order')
		var index:int = playlist_order.find(playlist.id)
		playlist_order.erase(playlist.id)
		DirAccess.remove_absolute(playlist.get_file_path()) # Delete playlist file with old name.
		playlist.id = StringUtils.resolve_duplicate(data.get('name'), playlist_order)

		if index == -1: playlist_order.append(playlist.id)
		else: playlist_order.insert(index, playlist.id)

		%Title.text = playlist.id

		# Update cover.
		playlist.cover_path = data.get('cover_path')
		var cover = playlist.get_cover()
		# If no cover, skip image processing & just save here.
		if not cover:
			playlist.save()
			return
		playlist.palette = DBAlbum.calculate_colors(cover) # Update color palette.
		%Icon.texture = cover if cover else DBAlbum.default_cover
		update_gradient()

		# Save playlist file & refresh page.
		playlist.save()
	)


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
		0: # Play next.
			pass
		1: # Add to queue.
			pass
		2: # Edit details.
			edit_details()
		3: # Delete.
			DialogManager.popup_confirmation_dialog('Delete Playlist', 'Are you sure you want to delete this playlist?', func() -> void:
				playlist.remove()
				SessionManager.refresh_current_page()
			)


func _on_add_pressed() -> void:
	DialogManager.popup_custom(DialogManager.select_tracks_scene.instantiate(), func(data:Dictionary) -> void:
		var tracks:Array[DBTrack] = data.get('selected_tracks')
		if tracks.is_empty(): return
		for track:DBTrack in tracks:
			playlist.track_ids.append(track.as_id())
		playlist.last_edit_date = DBPlaylist.get_current_date()
		%'Last Edit Date'.text = 'Modified: '+StringUtils.get_readable_date(playlist.last_edit_date)
		playlist.save()
		sort()
	)


func _on_track_list_reordered(from:int, to:int) -> void:
	var track_id:String = playlist.track_ids[from]
	playlist.track_ids.remove_at(from)
	if playlist.track_ids.size() <= to: playlist.track_ids.append(track_id)
	else: playlist.track_ids.insert(to, track_id)

	var track:DBTrack = loaded_tracks[from]
	loaded_tracks.remove_at(from)
	if loaded_tracks.size() <= to: loaded_tracks.append(track)
	else: loaded_tracks.insert(to, track)

	playlist.save()
