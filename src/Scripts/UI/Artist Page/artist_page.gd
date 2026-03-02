extends Control

@export var tab_config:Dictionary[String,Variant] = {
	'sort_mode': {
		'enabled': false,
	},
	'ascend_mode': {
		'enabled': false,
	},
	'search': {
		'enabled': false,
	}
}
var card_scene:PackedScene = SessionManager.get_layout_theme_scene('albums_card')
const overlay_color := Color(0.25, 0.25, 0.25, 0.5)
var loaded_albums:Array[DBAlbum] = []
var artist: DBArtist
var attempts_left:int = 4


func _ready() -> void:
	if not artist:
		SessionManager.main_scene.set_tab('artists')


func init(artist_:DBArtist) -> void:
	if not artist_: return
	artist = artist_
	%Title.text = artist.name
	%Title.tooltip_text = artist.name
	var dominant_colors = [
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
		Color.WHITE,
	]
	dominant_colors.shuffle()
	var mat = %Gradient.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))

	for album_name in artist.album_names:
		var album = artist.get_album(album_name)
		if not album: continue
		loaded_albums.append(album)
		add_card(album)

	update()


func set_gradient(image:ImageTexture) -> void:
	var colors = DBAlbum.calculate_colors(image)
	var dominant_colors = [
		colors.get('blend_full', Color.WHITE),
		colors.get('primary', Color.WHITE),
		colors.get('secondary', Color.WHITE),
		colors.get('trinary', Color.WHITE),
	]
	dominant_colors.shuffle()
	var mat = %Gradient.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))


func add_card(album:DBAlbum) -> void:
	var card:Control = card_scene.instantiate()
	card.selected.connect(_on_album_selected.bind(album))
	card.init(album)
	%'Album List'.add_child(card)


func block_requests() -> void:
	artist.save_cover(null)


func update() -> void:
	if attempts_left == 0:
		return
	attempts_left -= 1
	var stored_cover = artist.get_cover()

	# Fetch from API if not in DB.
	if not stored_cover && SessionManager.fetch_artist_cover:
		print('Fetching')
		var url = 'https://theaudiodb.com/api/v1/json/123/search.php?s=%s' % [
			artist.name.uri_encode(),
		]
		RequestManager.request(RequestManager.RequestType.Web, 'artist_cover_%s' % name, url, {}, _on_http_request_request_completed)

	elif stored_cover && stored_cover.get_size().x != 1:
		%Icon.texture = stored_cover
		set_gradient(stored_cover)


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
	RequestManager.request(RequestManager.RequestType.Web, 'artist_cover_image_%s' % name, img_url, {}, _on_http_request_image_request_completed)


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
	%Icon.texture = ImageTexture.create_from_image(image)
	set_gradient(%Icon.texture)
	artist.save_cover(image)


func _on_album_selected(album:DBAlbum) -> void:
	SessionManager.main_scene.set_tab('album_page', album)


func _on_album_button_pressed() -> void:
	SessionManager.main_scene.go_back()


func _on_play_pressed() -> void:
	if loaded_albums.is_empty(): return
