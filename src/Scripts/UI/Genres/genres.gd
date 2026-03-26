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
@onready var card_scene := SessionManager.get_layout_theme_scene('Elements/Grid Item/Grid Item')


func _ready() -> void:
	var genres:Dictionary[String,Array] = LibraryManager.get_genres_sorted()
	for genre:String in genres:
		var albums:Array = genres[genre]
		add_card(genre, albums)
		# Add one frame delay to give time to add child.
		await get_tree().create_timer(0).timeout


func add_card(genre_name:String, albums:Array) -> void:
	# Create card & images.
	var card:Control = card_scene.instantiate()
	var images:Array[Texture2D] = []
	for album:DBAlbum in albums:
		var cover = album.get_cover()
		if not cover: continue
		images.append(cover)
		if images.size() == 4: break
	# Set images & text.
	card.images = images
	card.primary_text = genre_name
	# Connect signal to card.
	card.pressed.connect(_on_card_pressed.bind(genre_name, albums))
	# Add to grid.
	%Grid.add_child(card)


func _on_card_pressed(genre_name:String, albums:Array) -> void:
	SessionManager.main_scene.set_tab('genre_page', {'genre_name':genre_name, 'albums':albums})
