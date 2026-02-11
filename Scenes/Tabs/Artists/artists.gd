extends VBoxContainer

const card_scene := preload('res://Scenes/Tabs/Artists/card.tscn')


func _ready() -> void:
	var artists:Array = LibraryManager.database.artists.keys()
	artists.sort()

	for artist:String in artists:
		add_card(artist)


func add_card(artist_name:String) -> void:
	# Get album covers.
	var albums:Dictionary = LibraryManager.database.artists[artist_name].albums
	var album_keys := albums.keys()
	album_keys.sort()
	var album_covers:Array[ImageTexture] = []
	for key:String in album_keys:
		album_covers.append(albums[key].cover)
	# Add card.
	var card:Control = card_scene.instantiate()
	card.init(artist_name, album_covers)
	%Grid.add_child(card)
