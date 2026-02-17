extends VBoxContainer

const card_scene := preload('res://Scenes/Tabs/Tracks/card.tscn')
const placeholder_card_scene := preload('res://Scenes/Tabs/Tracks/placeholder_card.tscn')
const page_size:int = 50

var tracks:Array[DBTrack] = []
var selected_track_index: int


func _ready() -> void:
	for track:DBTrack in LibraryManager.get_tracks_sorted():
		tracks.append(track)
		add_card(track, _on_track_selected.bind(track))


func add_card(track:DBTrack, callback:Callable) -> void:
	var card:Control = card_scene.instantiate()
	card.init(track)
	card.selected.connect(callback)
	%Grid.add_child(card)
	#var placeholder_card:Control = placeholder_card_scene.instantiate()
	#placeholder_card.init(%Scroll)
	#placeholder_card.activated.connect(func()->void:
		#print('added')
		#placeholder_card.queue_free()
		#var function = func()->void:
			#var card:Control = card_scene.instantiate()
			#card.init(track)
			#card.selected.connect(callback)
			#%Grid.add_child(card)
		#function.call_deferred()
	#)
	#%Grid.add_child(placeholder_card)


func _on_track_selected(track:DBTrack) -> void:
	PlayerManager.queue.clear()
	for track_:DBTrack in tracks:
		PlayerManager.add_to_queue(track_)

	PlayerManager.set_current_track(PlayerManager.queue.find(track))
	if PlayerManager.is_shuffled:
		PlayerManager.shuffle_queue(track)
	PlayerManager.set_playing(true)
