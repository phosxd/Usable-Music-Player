class_name GridTextureRect extends GridContainer

@export var template: Control


## Initialize from an array of [Texture2D].
func from_array(images:Array[Texture2D]) -> void:
	_reset_images()
	_add_images()
	var image_count:int = images.size()
	for i in 4:
		if i >= image_count: break
		var image:Texture2D = images[i]
		var node = get_child(i)
		if node is TextureRectRounded or node is TextureRect:
			node.texture = image


## Initialize from artist album covers.
func from_artist(artist:DBArtist) -> void:
	_reset_images()
	_add_images()
	var index:int = -1
	for album:DBAlbum in artist.albums.values():
		index += 1
		if index > 4: break
		if index >= get_child_count(): continue

		# Get album cover.
		var cover = album.get_cover()
		if cover is not ImageTexture: continue
		# Get texture rect.
		var node = get_child(index)
		if node is TextureRectRounded or node is TextureRect:
			node.texture = cover


func _reset_images() -> void:
	for child in get_children():
		child.queue_free()


func _add_images() -> void:
	if template is not TextureRect && template is not TextureRectRounded: return
	for i in 4:
		var clone:Control = template.duplicate()
		clone.custom_minimum_size = Vector2.ZERO
		clone.set('stretch_mode', 5) # Stretch Keep Aspect Centered.
		clone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		clone.size_flags_vertical = Control.SIZE_EXPAND_FILL
		clone.show()
		add_child(clone)
