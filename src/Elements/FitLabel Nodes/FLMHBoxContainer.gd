## HBoxContainer for managing [FitLabel] children.
@tool
class_name FLMHBoxContainer extends HBoxContainer

enum UpdateOrder {
	## Children ordered near the top will be updated before those near the bottom.
	Index,
	## Same as [param Index], but reversed.
	IndexReversed,
	## Children with the lower [member FitLabel.order_priority] value will be updated first.
	Priority,
}

## The order in which children are updated. This can change which children get more space than others if there are multiple [FitLabel] children.
@export var update_order := UpdateOrder.Index
## How many times children will update per second. Keep at [code]0.0[/code] if you don't want constant updating.
@export var update_rate:float = 0.0

@export_category('Container Property Update Flags')
## Update children when this container has changed size.
@export var update_on_parent_resized:bool = false
## Update children when this container has changed it's minimum size (total size of all children).
@export var update_on_parent_minimum_size_changed:bool = true

@export_category('Label Property Update Flags')
## How many times per second children properties will be checked.
@export var monitor_rate:float = 1.0
## Update children when their text has changed.
@export var update_on_text_changed:bool = true
## Update children when their label settings property has changed.
@export var update_on_label_settings_changed:bool = true

@export_category('Other')
@warning_ignore('shadowed_global_identifier') @export var print_debug:bool = false

var monitoring_nodes:Array[FitLabel] = []
var _monitor_data:Dictionary[FitLabel,Dictionary] = {}
var _last_update_frame:int = 0
var _monitor_timer:float = 0.0
var _global_timer:float = 0.0


## Update all [FitLabel] children.
func update() -> void:
	if print_debug: print('FLMHBC: update')
	_last_update_frame = Engine.get_process_frames()

	# Get nodes.
	var nodes:Array[FitLabel] = []
	for child:Node in self.get_children():
		if child is not FitLabel: continue
		nodes.append(child)

	# Sort nodes.
	match update_order:
		UpdateOrder.Index:
			pass
		UpdateOrder.IndexReversed:
			nodes.reverse()
		UpdateOrder.Priority:
			nodes.sort_custom(func(a,b) -> bool:
				return a.order_priority > b.order_priority
			)

	# Update nodes.
	for node:FitLabel in nodes:
		if node.currently_updating: continue
		node.update()


func run_monitor_checks() -> void:
	if print_debug: print('FLMHBC: run_monitor_checks')
	for node:FitLabel in monitoring_nodes:
		var data = _monitor_data.get_or_add(node, {
			'last_text': node.text,
			'last_label_settings': node.label_settings,
		})
		if update_on_text_changed && data.last_text != node.text: node.update()
		if update_on_label_settings_changed && data.last_label_settings != node.label_settings: node.update()
		data.last_text = node.text
		data.last_label_settings = node.label_settings


func _ready() -> void:
	self.child_entered_tree.connect(_on_child_entered_tree)
	self.child_exiting_tree.connect(_on_child_exited_tree)
	self.resized.connect(_on_resized)
	self.minimum_size_changed.connect(_on_minimum_size_changed)

	for child:Node in get_children():
		if child is not FitLabel: continue
		monitoring_nodes.append(child)


func _process(delta:float) -> void:
	_global_timer += delta
	_monitor_timer += delta
	if _global_timer > 1.0 / update_rate:
		update()
		_global_timer = 0
	elif _monitor_timer > 1.0 / monitor_rate:
		run_monitor_checks()
		_monitor_timer = 0


func _on_child_entered_tree(node:Node) -> void:
	if node is not FitLabel or monitoring_nodes.has(node): return
	monitoring_nodes.append(node)


func _on_child_exited_tree(node:Node) -> void:
	if node is not FitLabel: return
	monitoring_nodes.erase(node)


func _on_resized() -> void:
	if not update_on_parent_resized: return
	update()


func _on_minimum_size_changed() -> void:
	if not update_on_parent_minimum_size_changed: return
	if _last_update_frame == Engine.get_process_frames(): return
	update()
