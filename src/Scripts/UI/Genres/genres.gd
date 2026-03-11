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


func add_card(genre_name:String, albums:Array) -> void:
	if not card_scene: return
	var card:Control = card_scene.instantiate()
	card.init(genre_name, albums)
	card.selected.connect(_on_card_selected.bind(genre_name, albums))
	%Grid.add_child(card)


func _on_card_selected(genre_name:String, albums:Array) -> void:
	SessionManager.main_scene.set_tab('genre_page', {'genre_name':genre_name, 'albums':albums})
