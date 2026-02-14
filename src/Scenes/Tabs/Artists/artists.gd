extends VBoxContainer

const card_scene := preload('res://Scenes/Tabs/Artists/card.tscn')


func _ready() -> void:
	var artists:Array = LibraryManager.database.artists.keys()
	artists.sort()

	for artist_name:String in artists:
		var albums = LibraryManager.database.artists[artist_name].albums
		var album_names = albums.keys(); album_names.sort()
		var covers:Array[ImageTexture] = []
		for album_name in album_names:
			var album = LibraryManager.database.artists[artist_name].albums[album_name]
			covers.append(album.cover)
		add_card(artist_name, covers)


func add_card(artist_name:String, covers:Array[ImageTexture]) -> void:
	var card:Control = card_scene.instantiate()
	card.init(artist_name, covers)
	%Grid.add_child(card)
