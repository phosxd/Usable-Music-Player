extends VBoxContainer

@export var tab_config:Dictionary[String,Variant] = {
	'sort_mode': {
		'enabled': false,
	},
	'ascend_mode': {
		'enabled': false,
		#'callback': _on_ascend_mode_item_selected,
	},
	'search': {
		'enabled': false,
	}
}
var card_scene := SessionManager.get_layout_theme_scene('Genres/card')


func _ready() -> void:
	var genres:Dictionary[String,Array] = LibraryManager.get_genres_sorted()
	Async.create_thread((func(scene:Node, grid:Control) -> void:
		for genre:String in genres:
			var albums:Array = genres[genre]
			if not is_instance_valid(self): return
			if not scene: return
			add_card(scene, grid, genre, albums)
			# Add one frame delay to give time to add child.
			await get_tree().create_timer(0).timeout
	).bind(self, %Grid))


func add_card(scene:Node, grid:Control, genre_name:String, albums:Array) -> void:
	if not scene or not card_scene: return
	# Create card.
	var card:Control = card_scene.instantiate()
	card.init(genre_name, albums)
	# Connect signal to card.
	card.selected.connect(scene._on_card_selected.bind(genre_name, albums))
	# Add to grid.
	if not grid: return
	grid.add_child.call_deferred(card)


func _on_card_selected(genre_name:String, albums:Array) -> void:
	SessionManager.main_scene.set_tab('genre_page', {'genre_name':genre_name, 'albums':albums})
