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
var card_scene := SessionManager.get_layout_theme_scene('Artists/card')
var sort_mode: LibraryManager.ArtistSortMode
var ascend_mode = null
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

	var artists := LibraryManager.get_artists_sorted(sort_mode)
	if ascend_mode == false: artists.reverse()
	var current_count:Array[int] = [update_count]
	Async.create_thread((func(scene:Node, grid:Control) -> void:
		var iter:int = 0
		for artist:DBArtist in artists:
			if update_count != current_count[0]: return
			# Filter with search term.
			if not SessionManager.search_term.is_empty():
				var search_term:String = SessionManager.search_term.to_lower()
				if not artist.name.to_lower().contains(search_term):
					continue
			iter += 1
			# Add card.
			if not is_instance_valid(self): return
			if not scene: return
			add_card(scene, grid, artist)
			# Add one frame delay to give time to add child.
			if iter % 4 == 0: await get_tree().create_timer(0).timeout
	).bind(self, %Grid))


func add_card(scene:Node, grid:Control, artist:DBArtist) -> void:
	if not scene or not card_scene: return
	# Create card.
	var card:Control = card_scene.instantiate()
	card.init(artist)
	# Connect signal to card.
	card.selected.connect(scene._on_card_selected.bind(artist))

	# Add to grid.
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
