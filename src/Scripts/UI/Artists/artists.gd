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
var update_count:int = 0


func _ready() -> void:
	sort_mode = SessionManager.artist_sort_mode
	ascend_mode = SessionManager.artist_ascend_mode
	sort()


func sort() -> void:
	update_count += 1
	SessionManager.artist_sort_mode = sort_mode
	if ascend_mode != null: SessionManager.artist_ascend_mode = ascend_mode
	for child:Node in %Grid.get_children():
		child.queue_free()

	var artists := LibraryManager.get_artists_sorted(sort_mode)
	if ascend_mode == false: artists.reverse()
	var current_count:Array[int] = [update_count]
	ThreadHelper.create_thread((func(scene:Node, grid:Control) -> void:
		for artist:DBArtist in artists:
			if update_count != current_count[0]: return
			# Filter with search term.
			if not SessionManager.search_term.is_empty():
				var search_term:String = SessionManager.search_term.to_lower()
				if not artist.name.to_lower().contains(search_term):
					continue
			# Add card.
			if not scene: return
			add_card(scene, grid, artist)
			# Add artificial delay so that there is time for the new card to be added to the tree.
			# Without this, the app would skip frames & stutter.
			await get_tree().create_timer(0.01).timeout
	).bind(self, %Grid))


func add_card(scene:Node, grid:Control, artist:DBArtist) -> void:
	if not scene: return
	var card:Control = card_scene.instantiate()
	card.init(artist)
	card.selected.connect(_on_card_selected.bind(artist))
	if not grid: return
	grid.add_child.call_deferred(card)


func _on_sort_mode_item_selected(_index:int) -> void:
	return


func _on_card_selected(artist:DBArtist) -> void:
	SessionManager.main_scene.set_tab('artist_page', artist)


func _on_ascend_mode_item_selected(index:int) -> void:
	var prev_ascend_mode = ascend_mode
	match index:
		0: ascend_mode = false
		1: ascend_mode = true
	if prev_ascend_mode != ascend_mode:
		sort()


func _on_search_updated(_text:String) -> void:
	sort()
