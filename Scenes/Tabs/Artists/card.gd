extends PanelContainer

signal selected
const max_cover_count:int = 4
const cover_size := Vector2(100,100)
const empty_cover := preload('res://Assets/Icons/texture.svg')


func init(artist_name:String, covers:Array[ImageTexture]) -> void:
	$VBox/Label.text = artist_name
	var grid:GridContainer = $'VBox/Images'
	var count:int = 0
	for cover in covers:
		count += 1
		if count > max_cover_count: break
		var texture_rect := setup_texture_rect(TextureRect.new())
		texture_rect.texture = cover
		grid.add_child(texture_rect)

	var empty_covers = max_cover_count - count
	for i in range(empty_covers):
		var texture_rect := setup_texture_rect(TextureRect.new())
		texture_rect.texture = empty_cover
		grid.add_child(texture_rect)


func setup_texture_rect(texture_rect:TextureRect) -> TextureRect:
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texture_rect.custom_minimum_size = cover_size
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _on_button_pressed() -> void:
	selected.emit()
