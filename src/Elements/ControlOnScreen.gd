## A helper node for determining whether or not the node is on screen.
class_name ControlOnScreen extends Control

## Emitted when this enters the bounds of the window.
signal activated
## Emitted when this leaves the bounds of the window.
signal deactivated

static var enabled_global:bool = true

## How much time between each update.
## [br][br]
## Higher values will update slower but consume less resources, while lower vaues consume more resources but are quicker to respond to changes.
@export var update_interval:float = 0.5
## Nodes to hide when this leaves the bounds of the window.
@export var hide_nodes:Array[Control] = []
## Nodes to show when this leaves the bounds of the window.
@export var show_nodes:Array[Control] = []
## If enabled, this node will set it's minimum size to it's current size before hiding the [member hide_nodes].
## Use this to avoid buggy behavior in containers.
@export var preserve_size:bool = true

## Upward margin ratio.
@export var ratio_up:float = 1.0:
	set(value):
		ratio_up = value
		if is_node_ready(): calculate_margins()
## Downward margin ratio.
@export var ratio_down:float = 1.0:
	set(value):
		ratio_down = value
		if is_node_ready(): calculate_margins()
## Lefthand margin ratio.
@export var ratio_left:float = 1.0:
	set(value):
		ratio_left = value
		if is_node_ready(): calculate_margins()
## Righthand margin ratio.
@export var ratio_right:float = 1.0:
	set(value):
		ratio_right = value
		if is_node_ready(): calculate_margins()

var _cache:Array[float] = [0,0,0,0]

## Whether or not this node is within the bounds of the window. See related [member activated] & [member deactivated].
var on_screen:bool = false
var last_global_position: Vector2
var _timer:float = 0.0

@onready var window:Window = get_window()


func _ready() -> void:
	resized.connect(_on_resized)


func _process(delta:float) -> void:
	if not enabled_global: return
	_timer += delta
	if _timer < update_interval: return
	_timer = 0.0
	# If the global position of this node has changed, run checks to see if it has entered or left the window.
	if global_position != last_global_position:
		update()
		last_global_position = global_position


func _on_resized() -> void:
	calculate_margins()
	if enabled_global: update()


func calculate_margins() -> void:
	_cache = [
		size.y * ratio_up,
		size.y * ratio_down,
		size.x * ratio_left,
		size.x * ratio_right,
	]


func update() -> void:
	on_screen = check_on_screen()
	# On screen.
	if on_screen && enabled_global:
		activate()
	# Off screen.
	else:
		deactivate()


func activate() -> void:
	# Reset minimum size.
	self.custom_minimum_size = Vector2.ZERO
	# Hide previously shown nodes.
	for node:Control in show_nodes:
		if not node: continue
		node.hide()
	# Show previously hidden nodes.
	for node:Control in hide_nodes:
		if not node: continue
		node.show()
	# Emit signal.
	activated.emit()


func deactivate() -> void:
	# Set minimum size if "preserve_size" is enabled.
	if preserve_size: custom_minimum_size = size
	# Show nodes.
	for node:Control in show_nodes:
		if not node: continue
		node.show()
	# Hide nodes.
	for node:Control in hide_nodes:
		if not node: continue
		node.hide()
	# Emit signal.
	deactivated.emit()


## Returns whether or not this node is currently on screen.
## Global position & size is taken into account.
func check_on_screen() -> bool:
	if window == null:
		window = get_window()
		if window == null:
			printerr('Cannot get window.')
			return false

	return not (\
		# Check Y axis.
		(global_position.y < -_cache[0] \
		or global_position.y - _cache[1] > window.size.y) \
		or \
		# Check X axis.
		(global_position.x < -_cache[2] \
		or global_position.x - _cache[3] > window.size.x)
	)
