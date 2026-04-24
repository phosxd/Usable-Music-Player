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
			'Artist',
			'Year',
		],
		'default': 'album_sort_mode',
		'callback': _on_sort_mode_item_selected,
	},
	'ascend_mode': {
		'enabled': true,
		'default': 'album_ascend_mode',
		'callback': _on_ascend_mode_pressed,
	},
	'search': {
		'enabled': true,
		'callback': _on_search_updated,
	}
}
@onready var card_scene := SessionManager.get_layout_theme_scene('Elements/Grid Item/Grid Item')
@onready var sort_mode: DBLibrary.AlbumSortMode
var ascend_mode = null
var loaded_albums:Array[DBAlbum]
var update_count:int = 0


func _ready() -> void:
	sort_mode = SessionManager.album_sort_mode
	ascend_mode = SessionManager.album_ascend_mode
	sort()


func unload() -> void:
	Async.unload(%Grid.get_children(), (func(scene:Node) -> void:
		scene.queue_free()
	).bind(self))


func sort() -> void:
	update_count += 1
	SessionManager.album_sort_mode = sort_mode
	if ascend_mode != null: SessionManager.album_ascend_mode = ascend_mode
	for child:Node in %Grid.get_children():
		child.queue_free()

	var albums := LibraryManager.get_albums_sorted(sort_mode)
	if ascend_mode == false: albums.reverse()

	loaded_albums.clear()
	var current_count:Array[int] = [update_count]
	var iter:int = 0
	for album:DBAlbum in albums:
		if not album or update_count != current_count[0]: return
		var secondary_text:String = album.artist.name
		match sort_mode:
			DBLibrary.AlbumSortMode.year: secondary_text = album.year
		# Filter with search term.
		if not SessionManager.search_term.is_empty():
			var search_term:String = SessionManager.search_term.to_lower()
			if not secondary_text.to_lower().contains(search_term) \
			&& not album.name.to_lower().contains(search_term):
				continue
		iter += 1
		# Add card.
		loaded_albums.append(album)
		add_card(album, secondary_text)
		# Add one frame delay to give time to add child.
		if iter % 4 == 0: await get_tree().create_timer(0).timeout


func add_card(album:DBAlbum, secondary_text:String) -> void:
	# Create card.
	var card:Control = card_scene.instantiate()
	card.primary_text = album.name
	card.secondary_text = secondary_text
	card.images = [album.get_cover()]
	# Connect signal to card.
	card.pressed.connect(_on_card_pressed.bind(album))
	card.secondary_pressed.connect(_on_card_secondary_pressed.bind(album))
	# Add to grid.
	%Grid.add_child(card)


func _on_card_pressed(album:DBAlbum) -> void:
	SessionManager.main_scene.set_tab('album_page', album)


func _on_card_secondary_pressed(album:DBAlbum) -> void:
	SessionManager.main_scene.set_tab('artist_page', album.artist)


func _on_sort_mode_item_selected(index:int) -> void:
	var prev_sort_mode := sort_mode
	match index:
		0: sort_mode = DBLibrary.AlbumSortMode.title
		1: sort_mode = DBLibrary.AlbumSortMode.artist
		2: sort_mode = DBLibrary.AlbumSortMode.year
	if prev_sort_mode != sort_mode:
		sort()


func _on_ascend_mode_pressed(value:bool) -> void:
	var prev_ascend_mode = ascend_mode
	ascend_mode = value
	if prev_ascend_mode != ascend_mode:
		sort()


func _on_search_updated(_text:String) -> void:
	sort()


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
	var shuffled_albums:Array[DBAlbum] = loaded_albums.duplicate(); shuffled_albums.shuffle()
	for album:DBAlbum in shuffled_albums:
		for disc:Array in album.get_tracks_in_order().values():
			all_tracks.append_array(disc)

	PlayerManager.set_queue_and_track(all_tracks, all_tracks[0])
