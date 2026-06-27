extends PanelContainer

@onready var card_scene = SessionManager.get_scene('Queue/card')
var last_node: Node
var update_count:int = 0
var queue_update_blocked:bool = false


func _ready() -> void:
	update()
	PlayerManager.queue_updated.connect(update)
	PlayerManager.current_track_updated.connect(track_updated)
	SessionManager.value_changed.connect(_session_manager_value_changed)
	_session_manager_value_changed('right_sidebar_tab')


func _session_manager_value_changed(property:String, _source_name:String='base') -> void:
	match property:
		'right_sidebar_tab':
			visible = SessionManager.get_var('right_sidebar_tab') == 'queue'


func update(code:=PlayerManager.QueueUpdateCode.Set, data:Variant=null) -> void:
	if code in [0,3,4]: # Set, insert, or shuffle.
		if queue_update_blocked:
			queue_update_blocked = false
			return
		update_count += 1
		for child:Node in %List.get_children():
			child.queue_free()
		Async.create_thread(_sort.bind(%List))

	elif code == 1: # Add
		add_card(PlayerManager.queue[-1], %List)

	elif code == 2: # Remove.
		if data.index >= %List.get_child_count(): return
		var node = %List.get_child(data.index)
		%List.remove_child(node)
		node.queue_free()


func track_updated(queue_position:int, _track:DBTrack) -> void:
	if %List.get_child_count() <= queue_position: return
	var node:Control = %List.get_child(queue_position)
	if not node: return
	node.highlight(true)
	if last_node:
		last_node.highlight(false)
	last_node = node
	node.set_focus_mode(Control.FOCUS_ALL)
	node.grab_focus()
	#var auto_queue_node = %List.get_child(PlayerManager.auto_queue_start_index)
	#if auto_queue_node:
		#auto_queue_node.get_node('%Auto Queue Indicator').show()


func _sort(list:Control) -> void:
	var queue = PlayerManager.queue
	var current_count:Array[int] = [update_count]
	for track:DBTrack in queue:
		if update_count != current_count[0]: return
		if not self: return
		add_card(track, list)
		OS.delay_msec(4)
	if update_count != current_count[0]: return
	track_updated.call_deferred(PlayerManager.queue_position, PlayerManager.get_current_track())


func add_card(track:DBTrack, list:Control) -> void:
	if not card_scene: return
	var card = card_scene.instantiate()
	card.init(track)
	if list: list.add_child.call_deferred(card)


func _on_list_reordered(from:int, to:int) -> void:
	var track = PlayerManager.queue[from]
	PlayerManager.queue.remove_at(from)
	queue_update_blocked = true
	if from == PlayerManager.queue_position: PlayerManager.queue_position = to
	PlayerManager.insert_to_queue(to, track)


func _on_show_current_pressed() -> void:
	var node = %List.get_child(PlayerManager.queue_position)
	if not node: return
	node.set_focus_mode(Control.FOCUS_ALL)
	node.grab_focus()


func _on_save_playlist_pressed() -> void:
	var scene:Node = DialogManager.create_playlist_scene.instantiate()
	DialogManager.popup_custom(scene, func(data:Dictionary) -> void:
		var track_ids:Array[String] = []
		for track:DBTrack in PlayerManager.queue:
			track_ids.append(track.as_id())
		DBPlaylist.add_from_data(data, track_ids)
		SessionManager.main_scene.get_node('%Playlists').sort()
	)
