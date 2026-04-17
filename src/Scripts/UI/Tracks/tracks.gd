extends VBoxContainer

@export var tab_config:Dictionary[String,Variant] = {
	'play': {
		'enabled': true,
		'callback': _on_play_pressed,
	},
	'shuffle': {
		'enabled': true,
		'callback': _on_shuffle_pressed,
	},
	'sort_mode': {
		'enabled': true,
		'options': [
			'Sort by: Title', 
			'Sort by: Artist',
			'Sort by: Year',
			'Sort by: Number',
			'Sort by: Length'
		],
		'default': 'tab_sort_mode',
		'callback': _on_sort_mode_item_selected,
	},
	'ascend_mode': {
		'enabled': true,
		'default': 'track_ascend_mode',
		'callback': _on_ascend_mode_pressed,
	},
	'search': {
		'enabled': true,
		'callback': _on_search_updated,
	},
}
@onready var card_scene := SessionManager.get_layout_theme_scene('Tracks/card')

var loaded_tracks:Array[DBTrack] = []
var selected_track_index: int
var sort_mode: LibraryManager.TrackSortMode
var ascend_mode = null
var update_count:int = 0


func _ready() -> void:
	sort_mode = SessionManager.track_sort_mode
	ascend_mode = SessionManager.track_ascend_mode
	sort()


func _process(_delta:float) -> void:
	SessionManager.tracks_tab_scroll_value = %Scroll.scroll_vertical


func unload() -> void:
	Async.unload(%Grid.get_children(), (func(scene:Node) -> void:
		scene.queue_free()
	).bind(self))


func sort(callback=null) -> void:
	update_count += 1
	SessionManager.track_sort_mode = sort_mode
	if ascend_mode != null: SessionManager.track_ascend_mode = ascend_mode
	for child:Node in %Grid.get_children():
		child.queue_free()

	var tracks := LibraryManager.get_tracks_sorted(sort_mode)
	if ascend_mode == false: tracks.reverse()
	loaded_tracks.clear()

	var current_count:Array[int] = [update_count]
	var iter:int = 0
	for track:DBTrack in tracks:
		if update_count != current_count[0]: return
		# Filter with search term.
		if not SessionManager.search_term.is_empty():
			var search_term:String = SessionManager.search_term
			if not StringUtils.fuzzy_match(search_term, track.name) \
			&& not StringUtils.fuzzy_match(search_term, track.album.artist.name) \
			&& not StringUtils.fuzzy_match(search_term, track.album.name):
				continue
		iter += 1
		# Add card.
		loaded_tracks.append(track)
		add_card(track, _on_track_selected.bind(track))
		# Add one frame delay every 4th iteration to give time to add child.
		if iter % 4 == 0: await get_tree().create_timer(0).timeout

	if Async.is_callable_valid(callback): callback.call()


func add_card(track:DBTrack, callback:Callable) -> void:
	var card:Control = card_scene.instantiate()
	card.init(track)
	card.selected.connect(callback)
	%Grid.add_child(card)


func _on_track_selected(track:DBTrack) -> void:
	PlayerManager.set_queue_and_track(loaded_tracks, track)


func _on_sort_mode_item_selected(index:int) -> void:
	var prev_sort_mode := sort_mode
	match index:
		0: sort_mode = LibraryManager.TrackSortMode.TITLE
		1: sort_mode = LibraryManager.TrackSortMode.ARTIST
		2: sort_mode = LibraryManager.TrackSortMode.YEAR
		3: sort_mode = LibraryManager.TrackSortMode.NUMBER
		4: sort_mode = LibraryManager.TrackSortMode.LENGTH
	if prev_sort_mode != sort_mode:
		sort()


func _on_ascend_mode_pressed(value:bool) -> void:
	var prev_ascend_mode = ascend_mode
	ascend_mode = value
	if prev_ascend_mode != ascend_mode:
		sort()


func _on_search_updated(_text:String) -> void:
	sort()


func _on_play_pressed() -> void:
	if loaded_tracks.is_empty(): return
	PlayerManager.set_queue_and_track(loaded_tracks, loaded_tracks[0])


func _on_shuffle_pressed() -> void:
	if loaded_tracks.is_empty(): return
	var track:DBTrack = loaded_tracks.pick_random()
	var shuffled_tracks = loaded_tracks.duplicate(); shuffled_tracks.shuffle()
	PlayerManager.set_queue_and_track(shuffled_tracks, track)
	PlayerManager.shuffle_queue(track)
