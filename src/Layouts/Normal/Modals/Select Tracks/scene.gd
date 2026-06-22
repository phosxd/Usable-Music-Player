extends PanelContainer

signal confirmed(data:Dictionary)
signal denied

@onready var card_scene := SessionManager.get_scene('Modals/Select Tracks/track_card')

var tracks:Array[DBTrack] = []
var selected_tracks:Array[DBTrack] = []
var update_count:int = 0


func _ready() -> void:
	sort()


func sort() -> void:
	for child:Node in %List.get_children():
		child.queue_free()

	tracks = LibraryManager.get_tracks_sorted()
	Async.create_thread(_sort.bind(%List))


func _sort(list:Control) -> void:
	var current_count:Array[int] = [update_count]
	for track:DBTrack in tracks:
		if update_count != current_count[0]: return
		# Add card.
		add_card(track, _on_card_selected.bind(track), list)
		# Wait one frame to give time to add child.
		await get_tree().process_frame


func add_card(track:DBTrack, callback:Callable, list:Control) -> void:
	var card:Control = card_scene.instantiate()
	card.init(track)
	card.selected.connect(callback.bind(card))
	list.add_child.call_deferred(card)


func _on_card_selected(card:Control, track:DBTrack) -> void:
	if card.button_pressed: selected_tracks.append(track)
	else: selected_tracks.erase(track)


func _on_search_text_changed(_new_text:String) -> void:
	pass


func _on_yes_pressed() -> void:
	confirmed.emit({
		'selected_tracks': selected_tracks,
	})
	queue_free()


func _on_no_pressed() -> void:
	denied.emit()
	queue_free()
