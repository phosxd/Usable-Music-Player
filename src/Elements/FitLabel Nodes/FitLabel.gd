## A [Label] that adapts it's minimum size based on it's environment.
##
## Enable a form of clipping on the text for adapting to take effect (i.e. [param clip_text] or [param text_overrun_behavior]).
## [br][br]
## The label may not work correctly if it is not placed under an HBoxContainer.
## Use an [FLMHBoxContainer] for automatic update calls.
@tool
class_name FitLabel extends Label

@export_tool_button('Update') var update_button = update
## Order priority. See [member FLMHBoxContainer.update_order]. If you do not know how this works, don't worry about it.
@export var order_priority:int = 0

var currently_updating:bool = false


func update() -> void:
	var parent = self.get_parent()
	if parent == null or currently_updating or not self.visible: return
	if parent is not HBoxContainer: parent = parent.get_parent()
	if parent is not HBoxContainer: return
	parent = parent as HBoxContainer
	currently_updating = true

	# Set minimum size to "0" then wait one frame to ensure calculations are not influenced by changes.
	self.custom_minimum_size.x = 0
	await get_tree().process_frame

	var free_pixels:float = parent.size.x-parent.get_minimum_size().x # Get amount of pixels the parent container has available.
	var char_rect:Rect2 = self.get_character_bounds(self.text.length()-1)
	var needed_pixels:float = char_rect.position.x+char_rect.size.x # Get the amount of pixels needed to render ALL of the text.
	# If the amount of pixels needed to render all of the text is within the amount the container has to spare, then set minimum size to the needed amount of pixels.
	if needed_pixels <= free_pixels: self.custom_minimum_size.x = needed_pixels+1 # +1 so the last character doesn't get clipped.
	# If there aren't enough pixels to render all of the text, then set minimum size to whatever is available.
	else: self.custom_minimum_size.x = free_pixels

	currently_updating = false
