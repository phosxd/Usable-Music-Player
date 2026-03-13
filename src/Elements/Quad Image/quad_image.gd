extends GridContainer

@export var image_size := Vector2(100,100)


## Initialize from an array of [ImageTexture].
func from_array(images:Array[ImageTexture]) -> void:
	_reset_images()
	_add_images()
	var image_count:int = images.size()
	for i in 4:
		if i >= image_count: break
		var image:ImageTexture = images[i]
		var node = get_child(i)
		if node is TextureRectRounded:
			node.texture = image


## Initialize from artist album covers.
func from_artist(artist:DBArtist) -> void:
	_reset_images()
	_add_images()
	var index:int = -1
	for album:DBAlbum in artist.albums.values():
		index += 1
		if index > 3: break
		if index >= get_child_count(): continue

		# Get album cover.
		var cover = album.get_cover()
		if cover is not ImageTexture: continue
		# Get texture rect.
		var node = get_child(index)
		if node is not TextureRectRounded: continue
		# Set texture rect variables.
		node.texture = cover


func _reset_images() -> void:
	for child in get_children():
		if child.name != 'Template':
			child.queue_free()


func _add_images() -> void:
	for i in 3:
		var clone = $Template.duplicate()
		clone.custom_minimum_size = image_size
		add_child(clone)
