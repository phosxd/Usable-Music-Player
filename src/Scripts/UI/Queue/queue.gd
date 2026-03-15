extends PanelContainer

var card_scene = SessionManager.get_layout_theme_scene('Queue/card')
var last_node: Node
var update_count:int = 0
var queue_update_blocked:bool = false



func _ready() -> void:
	update()
	PlayerManager.queue_updated.connect(update)
	PlayerManager.current_track_updated.connect(track_updated)


func update() -> void:
	if queue_update_blocked:
		queue_update_blocked = false
		return
	update_count += 1
	for child:Node in %List.get_children():
		child.queue_free()

	var queue = PlayerManager.queue
	var current_count:int = update_count
	for track:DBTrack in queue:
		if update_count != current_count: return
		add_card(track)
		await get_tree().create_timer(0).timeout
	if update_count != current_count: return
	track_updated(PlayerManager.queue_position, PlayerManager.get_current_track())


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


func add_card(track:DBTrack) -> void:
	if not card_scene: return
	var card = card_scene.instantiate()
	card.init(track)
	%List.add_child(card)


func _on_list_reordered(from:int, to:int) -> void:
	var track = PlayerManager.queue[from]
	PlayerManager.queue.remove_at(from)
	queue_update_blocked = true
	if from == PlayerManager.queue_position: PlayerManager.queue_position = to
	PlayerManager.insert_to_queue(to, track)
