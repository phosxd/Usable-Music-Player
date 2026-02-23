extends VBoxContainer

@export var tab_config:Dictionary[String,Variant] = {
	'sort_mode': {
		'enabled': true,
		'options': [
			'Sort by: Title', 
		],
		'default': 'artist_sort_mode',
		'callback': _on_sort_mode_item_selected,
	},
	'ascend_mode': {
		'enabled': true,
		'default': 'artist_ascend_mode',
		'callback': _on_ascend_mode_item_selected,
	},
	'search': {
		'enabled': true,
		'callback': _on_search_updated,
	}
}
var card_scene := SessionManager.get_layout_theme_scene('artists_card')
var sort_mode: LibraryManager.ArtistSortMode
var ascend_mode = null


func _ready() -> void:
	sort_mode = SessionManager.artist_sort_mode
	ascend_mode = SessionManager.artist_ascend_mode
	sort()


func sort() -> void:
	SessionManager.artist_sort_mode = sort_mode
	if ascend_mode != null: SessionManager.artist_ascend_mode = ascend_mode
	for child:Node in %Grid.get_children():
		child.queue_free()

	var artists := LibraryManager.get_artists_sorted(sort_mode)
	if ascend_mode == false: artists.reverse()
	for artist:DBArtist in artists:
		# Filter with search term.
		if not SessionManager.search_term.is_empty():
			var search_term:String = SessionManager.search_term.to_lower()
			if not artist.name.to_lower().contains(search_term):
				continue

		add_card(artist)


func add_card(artist:DBArtist) -> void:
	var card:Control = card_scene.instantiate()
	card.init(artist)
	%Grid.add_child(card)


func _on_sort_mode_item_selected(_index:int) -> void:
	return


func _on_ascend_mode_item_selected(index:int) -> void:
	var prev_ascend_mode = ascend_mode
	match index:
		0: ascend_mode = false
		1: ascend_mode = true
	if prev_ascend_mode != ascend_mode:
		sort()


func _on_search_updated(_text:String) -> void:
	sort()
