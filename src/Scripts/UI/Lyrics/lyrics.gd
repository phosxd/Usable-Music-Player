extends PanelContainer

var current_track: DBTrack
var attempts_left:int = 4
var updated:bool = false


func _ready() -> void:
	PlayerManager.current_track_updated.connect(func(_queue_position, _track) -> void:
		updated = false
		if visible: update()
		else:
			await visibility_changed
			update()
	)
	SessionManager.value_changed.connect(_session_manager_value_changed)
	_session_manager_value_changed('right_sidebar_tab')
	update()


func _session_manager_value_changed(property:String, _source_name:String='base') -> void:
	match property:
		'right_sidebar_tab':
			visible = SessionManager.get_var('right_sidebar_tab') == 'lyrics'


func update() -> void:
	if updated: return
	var track:DBTrack = PlayerManager.get_current_track()
	if track != current_track:
		attempts_left = 4
	if attempts_left == 0:
		%'Info Label'.text = 'No lyrics found...'
		return
	attempts_left -= 1
	current_track = track
	%Label.text = ''
	%'Info Label'.show()
	%'Info Label'.text= 'No track...'
	if not track: return
	var stored_lyrics = track.get_lyrics()

	# Fetch from API if not in DB.
	if stored_lyrics.is_empty() && SessionManager.get_var('fetch_lyrics'):
		var url = 'https://lrclib.net/api/get?artist_name=%s&track_name=%s&album_name=%s&duration=%s' % [
			track.album.artist.name.uri_encode(),
			track.name.uri_encode(),
			track.album.name.uri_encode(),
			str(int(track.length)),
		]
		RequestManager.request(RequestManager.RequestType.Web, 'lyrics', url, {}, _on_http_request_request_completed.bind(track))
		%'Info Label'.text = 'Fetching lyrics...'

	elif not stored_lyrics.is_empty():
		%'Info Label'.hide()
		%Label.text = stored_lyrics

	elif not SessionManager.get_var('fetch_lyrics'):
		%'Info Label'.text = 'No lyrics found...'


func _on_http_request_request_completed(result:int, data:Dictionary, track:DBTrack) -> void:
	if track != current_track: return
	var body:PackedByteArray = data.get('body',PackedByteArray([]))

	%Label.text = ''
	%'Info Label'.show()
	match result:
		HTTPRequest.RESULT_SUCCESS: %'Info Label'.hide()
		HTTPRequest.RESULT_TIMEOUT:
			%'Info Label'.text = 'Fetching timed-out, trying again...'
			update()
			return
		_:
			update()
			return

	var body_json = JSON.parse_string(body.get_string_from_utf8())
	if body_json is not Dictionary: return
	var plain_lyrics = body_json.get('plainLyrics','')
	if plain_lyrics is not String or plain_lyrics.is_empty():
		%'Info Label'.text = 'No lyrics found...'
		%'Info Label'.show()
		return

	track.save_lyrics(plain_lyrics)
	%Label.text = plain_lyrics


func _on_refresh_pressed() -> void:
	update()


func _on_edit_pressed() -> void:
	var file_path:String = current_track.get_lyrics_path()
	OS.shell_open(file_path)
