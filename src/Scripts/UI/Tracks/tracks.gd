extends VBoxContainer

@export var tab_config:Dictionary[String,Variant] = {
	'sort_mode': {
		'enabled': true,
		'options': [
			'Sort by: Title', 
			'Sort by: Artist',
			'Sort by: Year',
			'Sort by: Genre',
			'Sort by: Number',
			'Sort by: Length'
		],
		'default': 'tab_sort_mode',
		'callback': _on_sort_mode_item_selected,
	},
	'ascend_mode': {
		'enabled': true,
		'default': 'track_ascend_mode',
		'callback': _on_ascend_mode_item_selected,
	},
	'search': {
		'enabled': true,
		'callback': _on_search_updated,
	},
}
var card_scene := SessionManager.get_layout_theme_scene('tracks_card')
var placeholder_card_scene := SessionManager.get_layout_theme_scene('tracks_placeholder_card')
const page_size:int = 50

var loaded_tracks:Array[DBTrack] = []
var selected_track_index: int
var sort_mode: LibraryManager.TrackSortMode
var ascend_mode = null
var update_count:int = 0


func _ready() -> void:
	sort_mode = SessionManager.track_sort_mode
	ascend_mode = SessionManager.track_ascend_mode
	sort()
	%Scroll.scroll_vertical = SessionManager.tracks_tab_scroll_value


func _process(_delta:float) -> void:
	SessionManager.tracks_tab_scroll_value = %Scroll.scroll_vertical


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
	ThreadHelper.create_thread((func(scene:Node, grid:Control) -> void:
		for track:DBTrack in tracks:
			if update_count != current_count[0]: return
			# Filter with search term.
			if not SessionManager.search_term.is_empty():
				var search_term:String = SessionManager.search_term
				if not StringUtils.fuzzy_match(search_term, track.name) \
				&& not StringUtils.fuzzy_match(search_term, track.artist.name) \
				&& not StringUtils.fuzzy_match(search_term, track.album.name):
					continue
			# Add card.
			if not scene: return
			loaded_tracks.append(track)
			add_card(scene, grid, track, _on_track_selected.bind(track))
			# Add artificial delay so that there is time for the new card to be added to the tree.
			# Without this, the app would skip frames & stutter.
			await get_tree().create_timer(0.01).timeout
	).bind(self, %Grid), callback)


func add_card(scene:Node, grid:Control, track:DBTrack, callback:Callable) -> void:
	if not scene: return
	var card:Control = card_scene.instantiate()
	card.init(track)
	card.selected.connect(callback)
	if not grid: return
	grid.add_child.call_deferred(card)
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
	for track_:DBTrack in loaded_tracks:
		PlayerManager.add_to_queue(track_, false)

	PlayerManager.set_current_track(PlayerManager.queue.find(track))
	if PlayerManager.is_shuffled:
		PlayerManager.shuffle_queue(track, false)
	PlayerManager.queue_updated.emit()
	PlayerManager.set_playing(true)


func _on_sort_mode_item_selected(index:int) -> void:
	var prev_sort_mode := sort_mode
	match index:
		0: sort_mode = LibraryManager.TrackSortMode.TITLE
		1: sort_mode = LibraryManager.TrackSortMode.ARTIST
		2: sort_mode = LibraryManager.TrackSortMode.YEAR
		3: sort_mode = LibraryManager.TrackSortMode.GENRE
		4: sort_mode = LibraryManager.TrackSortMode.NUMBER
		5: sort_mode = LibraryManager.TrackSortMode.LENGTH
	if prev_sort_mode != sort_mode:
		sort()


func _on_ascend_mode_item_selected(index:int) -> void:
	var prev_ascend_mode = ascend_mode
	match index:
		0: ascend_mode = false
		1: ascend_mode = true
	if prev_ascend_mode != ascend_mode:
		sort()


func _on_search_updated(_text:String) -> void:
	sort()
