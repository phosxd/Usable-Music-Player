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
	for genre:String in genres:
		var albums:Array = genres[genre]
		add_card(genre, albums)
		# Add one frame delay to give time to add child.
		await get_tree().create_timer(0).timeout


func add_card(genre_name:String, albums:Array) -> void:
	# Create card.
	var card:Control = card_scene.instantiate()
	card.init(genre_name, albums)
	# Connect signal to card.
	card.selected.connect(_on_card_selected.bind(genre_name, albums))
	# Add to grid.
	%Grid.add_child.call_deferred(card)


func _on_card_selected(genre_name:String, albums:Array) -> void:
	SessionManager.main_scene.set_tab('genre_page', {'genre_name':genre_name, 'albums':albums})
