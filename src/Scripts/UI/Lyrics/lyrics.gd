extends PanelContainer

var current_track: DBTrack


func _ready() -> void:
	PlayerManager.current_track_updated.connect(update)
	update(0, PlayerManager.get_current_track())


func update(_queue_position:int, track:DBTrack) -> void:
	current_track = track
	%Label.text = ''
	%'Info Label'.show()
	%'Info Label'.text= 'No track...'
	if not track: return
	var stored_lyrics = track.get_lyrics()

	# Fetch from API if not in DB.
	if stored_lyrics.is_empty():
		var url = 'https://lrclib.net/api/get?artist_name=%s&track_name=%s&album_name=%s&duration=%s' % [
			track.artist.name.uri_encode(),
			track.name.uri_encode(),
			track.album.name.uri_encode(),
			str(int(track.length)),
		]
		%HTTPRequest.cancel_request()
		%HTTPRequest.request(url)
		for connection:Dictionary in %HTTPRequest.request_completed.get_connections():
			(%HTTPRequest.request_completed as Signal).disconnect(connection.callable)
		%HTTPRequest.request_completed.connect(_on_http_request_request_completed.bind(track))
		%'Info Label'.text = 'Fetching lyrics...'

	else:
		%'Info Label'.hide()
		%Label.text = stored_lyrics


func _on_http_request_request_completed(result:int, _response_code:int, _headers:PackedStringArray, body:PackedByteArray, track:DBTrack) -> void:
	if track != current_track: return
	%Label.text = ''
	%'Info Label'.show()
	match result:
		HTTPRequest.RESULT_SUCCESS: %'Info Label'.hide()
		HTTPRequest.RESULT_TIMEOUT:
			%'Info Label'.text = 'Fetching timed-out, trying again...'
			update(0, PlayerManager.get_current_track())
			return
		_:
			update(0, PlayerManager.get_current_track())
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
