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
	ThreadHelper.create_thread((func(scene:Node, grid:Control) -> void:
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
			# Add card.
			if not scene: return
			add_card(scene, grid, album, display_data)
			# Add artificial delay so that there is time for the new card to be added to the tree.
			# Without this, the app would skip frames & stutter.
			await get_tree().create_timer(0.01).timeout
	).bind(self, %Grid))


func add_card(scene:Node, grid:Control, album:DBAlbum, display_data:String) -> void:
	if not scene or not card_scene: return
	var card:Control = card_scene.instantiate()
	card.init(album, display_data)
	card.selected.connect(_on_card_selected.bind(album))
	if not grid: return
	grid.add_child.call_deferred(card)
	
	
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
