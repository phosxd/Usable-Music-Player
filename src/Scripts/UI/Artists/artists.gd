extends VBoxContainer

@export var tab_config:Dictionary[String,Variant] = {
	'play': {
		'enabled': true,
		'callback': _on_play_pressed,
	},
	'shuffle': {
		'enabled': true,
		'callback': _on_shuffle_pressed,
	},
	'sort_mode': {
		'enabled': true,
		'options': [
			'Title', 
		],
		'default': 'artist_sort_mode',
		'callback': _on_sort_mode_item_selected,
	},
	'ascend_mode': {
		'enabled': true,
		'default': 'artist_ascend_mode',
		'callback': _on_ascend_mode_pressed,
	},
	'search': {
		'enabled': true,
		'callback': _on_search_updated,
	}
}
@onready var card_scene := SessionManager.get_layout_theme_scene('Elements/Grid Item/Grid Item')
@onready var sort_mode: DBLibrary.ArtistSortMode
var ascend_mode = null
var loaded_artists:Array[DBArtist] = []
var update_count:int = 0


func _ready() -> void:
	sort_mode = SessionManager.artist_sort_mode
	ascend_mode = SessionManager.artist_ascend_mode
	sort()


func unload() -> void:
	Async.unload(%Grid.get_children(), (func(scene:Node) -> void:
		scene.queue_free()
	).bind(self))


func sort() -> void:
	update_count += 1
	SessionManager.artist_sort_mode = sort_mode
	if ascend_mode != null: SessionManager.artist_ascend_mode = ascend_mode
	for child:Node in %Grid.get_children():
		child.queue_free()

	loaded_artists.clear()
	var artists := LibraryManager.get_artists_sorted(sort_mode)
	if ascend_mode == false: artists.reverse()

	Async.create_thread(_sort.bind(%Grid, artists))


func _sort(grid:Control, artists:Array[DBArtist]) -> void:
	if artists.is_empty(): return

	var current_count:Array[int] = [update_count]
	var iter:int = 0
	#var current_library_id:String = artists[0].library.id
	for artist:DBArtist in artists:
		if update_count != current_count[0]: return
		## If new library, add separator.
		#if artist.library.id != current_library_id:
			#var separator := HSeparator.new()
			#separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#var title := Label.new()
			#title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			#title.text = artist.library.name
			#title.theme_type_variation = 'LabelHeader2'
			#grid.add_child(title)
			#grid.add_child(separator)

		# Filter with search term.
		if not SessionManager.search_term.is_empty():
			var search_term:String = SessionManager.search_term.to_lower()
			if not artist.name.to_lower().contains(search_term):
				continue
		iter += 1
		# Add card.
		loaded_artists.append(artist)
		add_card(artist, grid)
		# Wait one frame to give time to add child.
		if iter % 4 == 0: await get_tree().process_frame


func add_card(artist:DBArtist, grid:Control) -> void:
	# Create card.
	var card:Control = card_scene.instantiate()
	card.icon = artist.library.get_icon()
	card.icon_tooltip_text = artist.library.name
	card.primary_text = artist.name
	# Connect signal to card.
	card.pressed.connect(_on_card_pressed.bind(artist))

	var stored_cover = artist.get_cover()
	# Fetch from API if not in DB.
	#if not stored_cover && SessionManager.fetch_artist_cover:
		#var url = AppInfo.audio_db_api_url % [artist.name.uri_encode()]
		#RequestManager.request(RequestManager.RequestType.Web, 'artist_cover', url, {}, _on_http_request_request_completed.bind(card, artist), 2.5, true)
	# Use stored image if valid.
	if stored_cover && stored_cover.get_size().x != 1:
		card.images = [stored_cover]
	# Use album covers.
	else:
		var images:Array[Texture2D] = []
		for album:DBAlbum in artist.albums:
			var cover = album.get_cover()
			if not cover: continue
			images.append(cover)
			if images.size() == 4: break
		card.images = images

	# Add to grid.
	grid.add_child.call_deferred(card)


#region card_functions
func _card_block_requests(artist:DBArtist) -> void:
	artist.save_cover(null)


func _on_http_request_request_completed(result:int, data:Dictionary, card, artist:DBArtist) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		print('Failed: %s' % error_string(result))
	var body:PackedByteArray = data.get('body',PackedByteArray([]))

	var content = body.get_string_from_utf8()
	var json = JSON.parse_string(content)
	if json is not Dictionary:
		_card_block_requests(artist)
		return
	var artists_json = json.get('artists',[])
	if artists_json is not Array:
		_card_block_requests(artist)
		return
	var artist_json = artists_json.get(0)
	if artist_json is not Dictionary:
		_card_block_requests(artist)
		return
	var img_url = artist_json.get('strArtistThumb','')
	if not img_url or img_url.is_empty():
		_card_block_requests(artist)
		return
	RequestManager.request(RequestManager.RequestType.Web, 'artist_cover_image_'+str(randf()), img_url, {}, _on_http_request_image_request_completed.bind(card,artist))


func _on_http_request_image_request_completed(result:int, data:Dictionary, card, artist:DBArtist) -> void:
	if not self: return
	if result != HTTPRequest.RESULT_SUCCESS: return
	var headers:PackedStringArray = data.get('headers',PackedStringArray([]))
	var body:PackedByteArray = data.get('body',PackedByteArray([]))

	var img_ext: String
	for header:String in headers:
		if not header.begins_with('Content-Type: '): continue
		img_ext = header.split('/')[-1]
	if img_ext.is_empty(): return
	if img_ext == 'jpeg': img_ext = 'jpg'

	var image = Image.new()
	image.call('load_%s_from_buffer' % img_ext, body)
	card.images = [ImageTexture.create_from_image(image)]
	artist.save_cover(image)


func _card_exit_tree() -> void:
	RequestManager.cancel_request('artist_cover')

#endregion


func _on_sort_mode_item_selected(_index:int) -> void:
	return


func _on_card_pressed(artist:DBArtist) -> void:
	SessionManager.main_scene.set_tab('artist_page', artist)


func _on_ascend_mode_pressed(value:bool) -> void:
	var prev_ascend_mode = ascend_mode
	ascend_mode = value
	if prev_ascend_mode != ascend_mode:
		sort()


func _on_search_updated(_text:String) -> void:
	sort()


func _on_play_pressed() -> void:
	if loaded_artists.is_empty(): return
	var all_tracks:Array[DBTrack] = []
	for artist:DBArtist in loaded_artists:
		for album:DBAlbum in artist.albums:
			for disc:Array in album.get_tracks_in_order().values():
				all_tracks.append_array(disc)

	PlayerManager.set_queue_and_track(all_tracks, all_tracks[0])


func _on_shuffle_pressed() -> void:
	if loaded_artists.is_empty(): return
	var all_tracks:Array[DBTrack] = []
	var shuffled_artists:Array[DBArtist] = loaded_artists.duplicate(); shuffled_artists.shuffle()
	for artist:DBArtist in shuffled_artists:
		for album:DBAlbum in artist.albums:
			for disc:Array in album.get_tracks_in_order().values():
				all_tracks.append_array(disc)

	PlayerManager.set_queue_and_track(all_tracks, all_tracks[0])
