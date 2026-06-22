@tool
extends PanelContainer

signal confirmed
signal denied


@export var text:String:
	set(value):
		text = value
		if self.is_node_ready(): %Text.text = value

@export var subtext:String:
	set(value):
		subtext = value
		if self.is_node_ready(): %Subtext.text = value


func _ready() -> void:
	%Text.text = text
	%Subtext.text = subtext


func _on_yes_pressed() -> void:
	confirmed.emit()
	self.queue_free()


func _on_no_pressed() -> void:
	denied.emit()
	self.queue_free()
