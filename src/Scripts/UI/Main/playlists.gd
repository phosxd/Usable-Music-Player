extends Control

@onready var playlist_card_scene:PackedScene = SessionManager.get_scene('Main/playlist_card')


func _ready() -> void:
	sort()


func sort() -> void:
	for child:Node in %'Playlists Container'.get_children():
		child.queue_free()

	for playlist:DBPlaylist in LibraryManager.playlists:
		add_card(playlist)


func add_card(playlist:DBPlaylist) -> void:
	var card:Control = playlist_card_scene.instantiate()
	card.init(playlist)
	card.pressed.connect(_on_card_pressed.bind(playlist))
	%'Playlists Container'.add_child(card)


func _on_card_pressed(playlist:DBPlaylist) -> void:
	SessionManager.main_scene.set_tab('playlist_page', playlist)


func _on_playlists_container_reordered(from:int, to:int) -> void:
	var playlist = LibraryManager.playlists.get(from)
	if playlist is not DBPlaylist: return
	playlist = playlist as DBPlaylist
	LibraryManager.playlists.remove_at(from)
	LibraryManager.playlists.insert(to, playlist)
