extends PanelContainer

signal activated
var is_activated:bool = false
var allow_checking:bool = true

var parent: ScrollContainer


func init(parent_:ScrollContainer) -> void:
	parent = parent_


func _ready() -> void:
	pass


func _process(_delta:float) -> void:
	if Engine.get_process_frames() % 20 != 0: return
	# Off-screen.
	if self.global_position.y < 0 or self.global_position.y > get_window().size.y:
		pass
	else:
		print(self.global_position)
	#if not parent: return
	#if is_activated: return
	#if not allow_checking: return
	#var self_rect: = Rect2(global_position, size)
	#var parent_rect := Rect2(parent.global_position, parent.size)
	#if self_rect.intersects(parent_rect):
		#activated.emit()
		#is_activated = true


func _on_mouse_entered() -> void:
	self.set_process(true)


func _on_mouse_exited() -> void:
	return
	self.set_process(false)
