extends PanelContainer

var card_scene = SessionManager.get_layout_theme_scene('queue_card')
var last_node: Node


func _ready() -> void:
	update()
	track_updated(PlayerManager.queue_position, PlayerManager.get_current_track())
	PlayerManager.queue_updated.connect(update)
	PlayerManager.current_track_updated.connect(track_updated)


func update() -> void:
	for child:Node in %List.get_children():
		child.queue_free()
	var queue = PlayerManager.queue
	for track:DBTrack in queue:
		add_card(track)


func track_updated(queue_position:int, _track:DBTrack) -> void:
	var node = %List.get_child(queue_position)
	if not node: return
	node.highlight(true)
	if last_node:
		last_node.highlight(false)
	last_node = node


func add_card(track:DBTrack) -> void:
	var card = card_scene.instantiate()
	card.init(track)
	%List.add_child(card)
