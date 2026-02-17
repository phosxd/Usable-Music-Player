extends VBoxContainer

const card_scene := preload('res://Scenes/Tabs/Genres/card.tscn')


func _ready() -> void:
	var genres:Dictionary[String,Array] = LibraryManager.get_genres_sorted()
	for genre:String in genres:
		var albums:Array = genres[genre]
		var covers:Array[ImageTexture] = []
		for album in albums:
			covers.append(album.cover)
			
		add_card(genre, albums, covers)


func add_card(genre_name:String, albums:Array, covers:Array[ImageTexture]) -> void:
	var card:Control = card_scene.instantiate()
	card.init(genre_name, albums, covers)
	%Grid.add_child(card)
