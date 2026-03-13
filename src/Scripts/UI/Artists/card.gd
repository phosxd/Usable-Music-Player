extends PanelContainer

signal selected
var default_style: StyleBox
@onready var default_label_settings:LabelSettings = %Name.label_settings
var artist: DBArtist
var attempts_left:int = 4


func _ready() -> void:
	if has_node('%Shadow'):
		default_style = %Shadow.get_theme_stylebox('panel')


func init(artist_:DBArtist) -> void:
	if not artist_: return
	artist = artist_
	%Name.text = artist.name

	if %'Quad Image': # "has_node" does not work here for some reason, so gonna have to deal with an error everytime it is not found.
		%'Quad Image'.from_artist(artist)
		artist.get_cover_threaded(func(cover) -> void:
			if not cover: return
			if cover.get_size().x == 1: return
			%Image.texture = cover
			%Image.show()
			%'Quad Image'.queue_free()
		)

	update()


func block_requests() -> void:
	artist.save_cover(null)


func update() -> void:
	if attempts_left == 0:
		return
	attempts_left -= 1
	var stored_cover = artist.get_cover()

	# Fetch from API if not in DB.
	if not stored_cover && SessionManager.fetch_artist_cover:
		var url = AppInfo.audio_db_api_url % [
			artist.name.uri_encode(),
		]
		RequestManager.request(RequestManager.RequestType.Web, 'artist_cover', url, {}, _on_http_request_request_completed, 2.5, true)

	elif stored_cover && stored_cover.get_size().x != 1:
		%Image.texture = stored_cover


func _on_http_request_request_completed(result:int, data:Dictionary) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		print('Failed: %s' % error_string(result))
	var body:PackedByteArray = data.get('body',PackedByteArray([]))

	var content = body.get_string_from_utf8()
	var json = JSON.parse_string(content)
	if json is not Dictionary:
		block_requests()
		return
	var artists_json = json.get('artists',[])
	if artists_json is not Array:
		block_requests()
		return
	var artist_json = artists_json.get(0)
	if artist_json is not Dictionary:
		block_requests()
		return
	var img_url = artist_json.get('strArtistThumb','')
	if not img_url or img_url.is_empty():
		block_requests()
		return
	RequestManager.request(RequestManager.RequestType.Web, 'artist_cover_image_'+str(randf()), img_url, {}, _on_http_request_image_request_completed)


func _on_http_request_image_request_completed(result:int, data:Dictionary) -> void:
	if result != HTTPRequest.RESULT_SUCCESS: return
	var headers:PackedStringArray = data.get('headers',PackedStringArray([]))
	var body:PackedByteArray = data.get('body',PackedByteArray([]))

	var img_ext: String
	for header:String in headers:
		if not header.begins_with('Content-Type: '): continue
		img_ext = header.split('/')[-1]
	if img_ext.is_empty(): return
	if img_ext == 'jpeg': img_ext = 'jpg'

	var image = Image.new()
	image.call('load_%s_from_buffer' % img_ext, body)
	%Image.texture = ImageTexture.create_from_image(image)
	%Image.show()
	if has_node("%'Quad Image'"): %'Quad Image'.queue_free()
	artist.save_cover(image)


func _exit_tree() -> void:
	RequestManager.cancel_request('artist_cover')


func _on_button_pressed() -> void:
	selected.emit()


func _on_button_mouse_entered() -> void:
	if not has_node('%Animation'): return
	%Animation.play('Hover')


func _on_button_mouse_exited() -> void:
	if not has_node('%Animation'): return
	%Animation.play_backwards('Hover')


func hover(value:float=0) -> void:
	if value == 0:
		if has_node('%Shadow'):
			%Shadow.remove_theme_stylebox_override('panel')
			%Shadow.add_theme_stylebox_override('panel', default_style)
		%Name.label_settings = default_label_settings

	else:
		var new_label_settings:LabelSettings = %Name.label_settings.duplicate()
		new_label_settings.shadow_color = Color.TRANSPARENT.lerp(Color.WHITE, value)
		%Name.label_settings = new_label_settings

		var image:Image = %Image.texture.get_image()
		image.crop(1,1)
		var dominant_color := image.get_pixel(0,0)

		if has_node('%Shadow'):
			var style = default_style.duplicate()
			style.shadow_color = (default_style.shadow_color as Color).lerp(Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.5), value)
			style.shadow_size = lerpf(default_style.shadow_size, default_style.shadow_size+2, value)
			%Shadow.remove_theme_stylebox_override('panel')
			%Shadow.add_theme_stylebox_override('panel', style)
