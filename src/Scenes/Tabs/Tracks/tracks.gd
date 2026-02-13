extends VBoxContainer

const card_scene := preload('res://Scenes/Tabs/Tracks/card.tscn')


func _ready() -> void:
	var artists:Array = LibraryManager.database.artists.keys()
	artists.sort()

	for artist_name:String in artists:
		var artist := DBArtist.new(artist_name)
		var albums:Dictionary = LibraryManager.database.artists[artist_name].albums
		albums.sort()
		for album_name:String in albums:
			var album := DBAlbum.new(artist, album_name)
			for i in range(album.track_count):
				var track := DBTrack.new(artist, album, i)
				if track.path.is_empty(): continue
				add_card(track, _on_track_selected.bind(track.path))


func add_card(track:DBTrack, callback:Callable) -> void:
	var card:Control = card_scene.instantiate()
	card.init(track)
	card.selected.connect(callback)
	%Grid.add_child(card)


func _on_track_selected(_track_path:String) -> void:
	pass
