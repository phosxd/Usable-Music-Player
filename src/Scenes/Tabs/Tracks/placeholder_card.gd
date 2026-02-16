extends PanelContainer

signal activated
var is_activated:bool = false
var allow_checking:bool = true

var parent: ScrollContainer


func init(parent_:ScrollContainer) -> void:
	parent = parent_


func _process(_delta:float) -> void:
	if not parent: return
	if is_activated: return
	if not allow_checking: return
	var self_rect: = Rect2(global_position, size)
	var parent_rect := Rect2(parent.global_position, parent.size)
	if self_rect.intersects(parent_rect):
		activated.emit()
		is_activated = true
