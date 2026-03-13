extends VBoxContainer

@export var tab_config:Dictionary[String,Variant] = {
	'sort_mode': {
		'enabled': true,
		'options': [
			'Sort by: Title', 
			'Sort by: Artist',
			'Sort by: Year',
		],
		'default': 'album_sort_mode',
		'callback': _on_sort_mode_item_selected,
	},
	'ascend_mode': {
		'enabled': true,
		'default': 'album_ascend_mode',
		'callback': _on_ascend_mode_item_selected,
	},
	'search': {
		'enabled': true,
		'callback': _on_search_updated,
	}
}
var card_scene := SessionManager.get_layout_theme_scene('Albums/card')
var sort_mode: LibraryManager.AlbumSortMode
var ascend_mode = null
var update_count:int = 0


func _ready() -> void:
	sort_mode = SessionManager.album_sort_mode
	ascend_mode = SessionManager.album_ascend_mode
	sort()


func sort() -> void:
	update_count += 1
	SessionManager.album_sort_mode = sort_mode
	if ascend_mode != null: SessionManager.album_ascend_mode = ascend_mode
	for child:Node in %Grid.get_children():
		child.queue_free()

	var albums := LibraryManager.get_albums_sorted(sort_mode)
	if ascend_mode == false: albums.reverse()

	var current_count:Array[int] = [update_count]
	var iter:int = 0
	for album:DBAlbum in albums:
		if update_count != current_count[0]: return
		var display_data:String = ''
		match sort_mode:
			LibraryManager.AlbumSortMode.YEAR: display_data = album.year
		# Filter with search term.
		if not SessionManager.search_term.is_empty():
			var search_term:String = SessionManager.search_term.to_lower()
			if not display_data.to_lower().contains(search_term) \
			&& not album.name.to_lower().contains(search_term) \
			&& not album.artist.name.to_lower().contains(search_term):
				continue
		iter += 1
		# Add card.
		add_card(album, display_data)
		# Add one frame delay to give time to add child.
		if iter % 4 == 0: await get_tree().create_timer(0).timeout


func add_card(album:DBAlbum, display_data:String) -> void:
	# Create card.
	var card:Control = card_scene.instantiate()
	card.init(album, display_data)
	# Connect signal to card.
	card.selected.connect(_on_card_selected.bind(album))
	# Add to grid.
	%Grid.add_child(card)
	
	
func _on_card_selected(album:DBAlbum) -> void:
	SessionManager.main_scene.set_tab('album_page', album)


func _on_sort_mode_item_selected(index:int) -> void:
	var prev_sort_mode := sort_mode
	match index:
		0: sort_mode = LibraryManager.AlbumSortMode.TITLE
		1: sort_mode = LibraryManager.AlbumSortMode.ARTIST
		2: sort_mode = LibraryManager.AlbumSortMode.YEAR
	if prev_sort_mode != sort_mode:
		sort()


func _on_ascend_mode_item_selected(index:int) -> void:
	var prev_ascend_mode = ascend_mode
	match index:
		0: ascend_mode = false
		1: ascend_mode = true
	if prev_ascend_mode != ascend_mode:
		sort()


func _on_search_updated(_text:String) -> void:
	sort()
