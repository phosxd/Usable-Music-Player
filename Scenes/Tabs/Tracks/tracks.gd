extends VBoxContainer

const card_scene := preload('res://Scenes/Tabs/Tracks/card.tscn')


func _ready() -> void:
	var artists:Array = LibraryManager.database.artists.keys()
	artists.sort()

	for artist_name:String in artists:
		var albums:Dictionary = LibraryManager.database.artists[artist_name].albums
		albums.sort()
		for album_name:String in albums:
			var album:Dictionary = LibraryManager.database.artists[artist_name].albums[album_name]
			for track in album.tracks:
				if track is not Dictionary: continue
				add_card(track.title, track.path, track.length, album_name, artist_name, album.cover, _on_track_selected.bind(track.path))


func add_card(track_name:String, track_path:String, track_length:float, album_name:String, artist_name:String, album_cover, callback:Callable) -> void:
	var card:Control = card_scene.instantiate()
	card.init(track_name, track_path, track_length, album_name, artist_name, album_cover)
	card.selected.connect(callback)
	%Grid.add_child(card)


func _on_track_selected(_track_path:String) -> void:
	pass
