class_name EfficientList extends Node

signal populate_complete
signal add_content_complete

const empty_style:StyleBoxEmpty = preload('res://Assets/empty_style.tres')

@export var list: Container
@export var threaded:bool = true
## Time between each item content addition.
@export var add_content_interval_ms:int = 4

## Minimum size of each item.
@export var item_minimum_size := Vector2i.ONE*10
## PlanelContainer style that will be used for each item.
## If empty, will use no style.
@export var item_placeholder_style_name:StringName = ''

static var item_pool:Array[EfficientListItem] = []


func pool() -> void:
	for child:Node in get_children():
		if child is not EfficientListItem: continue
		remove_child(child)
		child.empty()
		item_pool.append(child)


## Populate the list with [param count] items.
func populate(count:int) -> void:
	var item_style: StyleBox
	if not item_placeholder_style_name.is_empty(): item_style = ThemeManager.theme.get_stylebox(item_placeholder_style_name, 'PanelContainer')
	Async.create_thread(_populate.bind(item_style, count))


func _populate(item_style:StyleBox, count:int) -> void:
	for i:int in count:
		if not self: return

		var item: EfficientListItem
		if item_pool.is_empty():
			item = item_pool.pop_back()
		else:
			item = EfficientListItem.new()

		item.custom_minimum_size = item_minimum_size
		if item_style: item.add_theme_stylebox_override('panel', item_style)
		else: item.add_theme_stylebox_override('panel', empty_style)

		if self: add_child.call_deferred(item)

	if self: populate_complete.emit()


## Adds content to the populated items.
## [br][br][param get_content] is called with no parameters & expects a Control node as the result.
## The function is called from a separate thread, you need to make sure you have binded everything you want to use.
func add_content(get_content:Callable) -> void:
	var children:Array[Node] = get_children()
	Async.create_thread(_add_content.bind(children, get_content))


func _add_content(children:Array[Node], get_content:Callable):
	for child:Node in children:
		if not get_content: continue
		var content:Control = get_content.call()
		child.add_child.call_deferred(content)
		OS.delay_msec(add_content_interval_ms)

	if self: add_content_complete.emit()
