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
@onready var card_scene := SessionManager.get_scene('Tracks/card')

var tracks:Array[DBTrack] = []
var sort_mode: DBLibrary.TrackSortMode
var ascend_mode = null
var update_count:int = 0


func _ready() -> void:
	sort_mode = SessionManager.get_var('track_sort_mode')
	ascend_mode = SessionManager.get_var('track_ascend_mode')
	sort()


func _process(_delta:float) -> void:
	SessionManager.set_var('tracks_tab_scroll_value', %Scroll.scroll_vertical)


func unload() -> void:
	update_count += 1 # Interupt sorting.
	Async.unload(%Grid.get_children(), (func(scene:Node) -> void:
		scene.queue_free()
	).bind(self))


func sort() -> void:
	update_count += 1
	SessionManager.set_var('track_sort_mode', sort_mode)
	if ascend_mode != null: SessionManager.set_var('track_ascend_mode', ascend_mode)
	for child:Node in %Grid.get_children():
		child.queue_free()

	# Get filtered & sorted tracks.
	var search_term = SessionManager.get_var('search_term')
	tracks = LibraryManager.get_tracks_sorted(sort_mode).filter(func(track:DBTrack) -> bool:
		if not search_term.is_empty():
			if not StringUtils.fuzzy_match(search_term, track.name) \
			&& not StringUtils.fuzzy_match(search_term, track.album.artist.name) \
			&& not StringUtils.fuzzy_match(search_term, track.album.name) \
			&& not track.album.year.contains(search_term):
				return false
		return true
	)
	if ascend_mode == false: tracks.reverse()

	Async.create_thread(_sort.bind(%Grid))


func _sort(grid:Control) -> void:
	var current_count:Array[int] = [update_count]
	for track:DBTrack in tracks:
		if update_count != current_count[0]: return
		# Add card.
		add_card(track, _on_track_selected.bind(track), grid)
		# Wait one frame to give time to add child.
		await get_tree().process_frame


func add_card(track:DBTrack, callback:Callable, grid:Control) -> void:
	var card:Control = card_scene.instantiate()
	card.details_scene_name = 'Tracks/card_details'
	card.init(track)
	card.selected.connect(callback)
	grid.add_child.call_deferred(card)


func _on_track_selected(track:DBTrack) -> void:
	PlayerManager.set_queue_and_track(tracks, track)


func _on_sort_mode_item_selected(index:int) -> void:
	var prev_sort_mode := sort_mode
	match index:
		0: sort_mode = DBLibrary.TrackSortMode.title
		1: sort_mode = DBLibrary.TrackSortMode.artist
		2: sort_mode = DBLibrary.TrackSortMode.year
		3: sort_mode = DBLibrary.TrackSortMode.number
		4: sort_mode = DBLibrary.TrackSortMode.length
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
	if tracks.is_empty(): return
	PlayerManager.set_queue_and_track(tracks, tracks[0])


func _on_shuffle_pressed() -> void:
	if tracks.is_empty(): return
	var track:DBTrack = tracks.pick_random()
	var shuffled_tracks = tracks.duplicate(); shuffled_tracks.shuffle()
	PlayerManager.set_queue_and_track(shuffled_tracks, track)
	PlayerManager.shuffle_queue(track)
