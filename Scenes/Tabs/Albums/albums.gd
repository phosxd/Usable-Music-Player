extends VBoxContainer

const card_scene := preload('res://Scenes/Tabs/Albums/card.tscn')


func _ready() -> void:
	var artists:Array = LibraryManager.database.artists.keys()
	artists.sort()

	for artist_name:String in artists:
		var albums:Dictionary = LibraryManager.database.artists[artist_name].albums
		albums.sort()
		for album_name:String in albums:
			var album:Dictionary = albums[album_name]
			add_card(artist_name, album_name, album.cover)


func add_card(artist_name:String, album_name:String, album_cover) -> void:
	var card:Control = card_scene.instantiate()
	card.init(album_name, artist_name, album_cover)
	%Grid.add_child(card)
