extends Control

@onready var playlist_card_scene:PackedScene = SessionManager.get_scene('Main/playlist_card')


func _ready() -> void:
	sort()


func sort() -> void:
	for child:Node in %'Playlists Container'.get_children():
		child.queue_free()

	for playlist_id:String in SessionManager.get_var('playlist_order'):
		var playlist:DBPlaylist = LibraryManager.get_playlist(playlist_id)
		add_card(playlist)


func add_card(playlist:DBPlaylist) -> void:
	var card:Control = playlist_card_scene.instantiate()
	card.init(playlist)
	card.pressed.connect(_on_card_pressed.bind(playlist))
	%'Playlists Container'.add_child(card)


func _on_card_pressed(playlist:DBPlaylist) -> void:
	print('pressed %s' %playlist.id)
