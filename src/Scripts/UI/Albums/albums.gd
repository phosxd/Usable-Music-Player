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
@onready var card_scene := SessionManager.get_scene('Elements/Grid Item/Grid Item')
@onready var sort_mode: DBLibrary.AlbumSortMode
var ascend_mode = null
var albums:Array[DBAlbum] = []
var update_count:int = 0


func _ready() -> void:
	sort_mode = SessionManager.get_var('album_sort_mode')
	ascend_mode = SessionManager.get_var('album_ascend_mode')
	sort()


func unload() -> void:
	update_count += 1 # Interupt sorting.
	Async.unload(%Grid.get_children(), (func(scene:Node) -> void:
		scene.queue_free()
	).bind(self))


func sort() -> void:
	update_count += 1
	SessionManager.set_var('album_sort_mode', sort_mode)
	if ascend_mode != null: SessionManager.set_var('album_ascend_mode', ascend_mode)
	for child:Node in %Grid.get_children():
		child.queue_free()

	albums = LibraryManager.get_albums_sorted(sort_mode).filter(func(album:DBAlbum) -> bool:
		# Filter with search term.
		if not SessionManager.get_var('search_term').is_empty():
			var search_term:String = SessionManager.get_var('search_term').to_lower()
			if not StringUtils.fuzzy_match(search_term, album.name) \
			&& not StringUtils.fuzzy_match(search_term, album.artist.name) \
			&& not album.year.contains(search_term):
				return false
		return true
	) 
	if ascend_mode == false: albums.reverse()

	Async.create_thread(_sort.bind(%Grid))


func _sort(grid:Control) -> void:
	var current_count:Array[int] = [update_count]
	for album:DBAlbum in albums:
		if not album or update_count != current_count[0]: return
		var secondary_text:String = album.artist.name
		match sort_mode:
			DBLibrary.AlbumSortMode.year: secondary_text = album.year
		# Add card.
		add_card(album, secondary_text, grid)
		# Wait one frame to give time to add child.
		await get_tree().process_frame


func add_card(album:DBAlbum, secondary_text:String, grid:Control) -> void:
	# Create card.
	var card:Control = card_scene.instantiate()
	# Show library icon if multiple libraries visible.
	if SessionManager.get_var('visible_libraries').size() > 1:
		card.icon = album.artist.library.get_icon()
		card.icon_tooltip_text = album.artist.library.name
	card.primary_text = album.name
	card.secondary_text = secondary_text
	card.images = [album.get_cover()]
	# Connect signal to card.
	card.pressed.connect(_on_card_pressed.bind(album))
	card.secondary_pressed.connect(_on_card_secondary_pressed.bind(album))
	# Add to grid.
	grid.add_child.call_deferred(card)


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
	if albums.is_empty(): return
	var all_tracks:Array[DBTrack] = []
	for album:DBAlbum in albums:
		for disc:Array in album.get_tracks_in_order().values():
			all_tracks.append_array(disc)

	PlayerManager.set_queue_and_track(all_tracks, all_tracks[0])


func _on_shuffle_pressed() -> void:
	if albums.is_empty(): return
	var all_tracks:Array[DBTrack] = []
	var shuffled_albums:Array[DBAlbum] = albums.duplicate(); shuffled_albums.shuffle()
	for album:DBAlbum in shuffled_albums:
		for disc:Array in album.get_tracks_in_order().values():
			all_tracks.append_array(disc)

	PlayerManager.set_queue_and_track(all_tracks, all_tracks[0])
