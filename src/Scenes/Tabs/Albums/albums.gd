extends VBoxContainer

const card_scene := preload('res://Scenes/Tabs/Albums/card.tscn')
var sort_mode: LibraryManager.AlbumSortMode
var ascend_mode = null


func _ready() -> void:
	_update_property('album_sort_mode')
	_update_property('ascend_mode')
	sort()


func _update_property(property_name:String) -> void:
	match property_name:
		'album_sort_mode':
			var value = SessionManager.album_sort_mode
			%'Sort Mode'.selected = value
			_on_sort_mode_item_selected(value)
		'ascend_mode':
			var value = SessionManager.album_ascend_mode
			%'Ascend Mode'.selected = value
			_on_ascend_mode_item_selected(value)


func sort() -> void:
	SessionManager.album_sort_mode = sort_mode
	if ascend_mode != null: SessionManager.album_ascend_mode = ascend_mode
	for child:Node in %Grid.get_children():
		child.queue_free()

	var albums := LibraryManager.get_albums_sorted(sort_mode)
	if ascend_mode == false: albums.reverse()
	for album:DBAlbum in albums:
		var display_data:String = ''
		match sort_mode:
			LibraryManager.AlbumSortMode.YEAR: display_data = album.year
			LibraryManager.AlbumSortMode.GENRE: display_data = album.genre
		add_card(album, display_data)


func add_card(album:DBAlbum, display_data:String) -> void:
	var card:Control = card_scene.instantiate()
	card.init(album, display_data)
	%Grid.add_child(card)


func _on_sort_mode_item_selected(index:int) -> void:
	var prev_sort_mode := sort_mode
	match index:
		0: sort_mode = LibraryManager.AlbumSortMode.TITLE
		1: sort_mode = LibraryManager.AlbumSortMode.ARTIST
		2: sort_mode = LibraryManager.AlbumSortMode.YEAR
		3: sort_mode = LibraryManager.AlbumSortMode.GENRE
	if prev_sort_mode != sort_mode:
		sort()


func _on_ascend_mode_item_selected(index:int) -> void:
	var prev_ascend_mode = ascend_mode
	match index:
		0: ascend_mode = false
		1: ascend_mode = true
	if prev_ascend_mode != ascend_mode:
		sort()
