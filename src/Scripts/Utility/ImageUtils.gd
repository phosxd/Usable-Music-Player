class_name ImageUtils extends RefCounted


## Limits the image width & height. Modifies the [param image].
## Uses BILINEAR interpolation.
static func limit_size(image:Image, max_size:Vector2i) -> void:
	var width:int = image.get_width()
	var height:int = image.get_height()
	var ratio := float(width)/float(height)

	var new_width:int = min(max_size.x, width)
	var new_height:int = min(max_size.y, height)
	if width > height:
		@warning_ignore('narrowing_conversion')
		new_height = new_height/ratio
	else:
		@warning_ignore('narrowing_conversion')
		new_width = new_width*ratio

	image.resize(new_width, new_height, Image.INTERPOLATE_BILINEAR)
