extends Control

const play_icon := preload('res://Assets/Icons/play.svg')
const pause_icon := preload('res://Assets/Icons/pause.svg')

var current_track: DBTrack
var track_progress_blocked := false


func  _ready() -> void:
	PlayerManager.current_track_updated.connect(update_current_track)
	PlayerManager.track_progress_updated.connect(update_track_progress)
	PlayerManager.play_requested.connect(update_playing.bind(true))
	PlayerManager.pause_requested.connect(update_playing.bind(false))
	update_current_track(PlayerManager.queue_position)
	update_track_progress(PlayerManager.track_progress)


func update_current_track(track_queue_position:int) -> void:
	if PlayerManager.queue.get(track_queue_position) == null: return
	current_track = PlayerManager.queue[track_queue_position]
	%'Track Name'.text = current_track.name
	%'Artist Name'.text = '%s' % [current_track.artist.name]
	#var last_char_rect:Rect2 = %'Track Name'.get_character_bounds(%'Track Name'.text.length()-1)
	#print(last_char_rect)
	#print(%'Track Name'.get_,' ',%'Track Name'.get_total_character_count())
	#if last_char_rect.size == Vector2(0,0):
		#%'Track Name'.size_flags_horizontal = SIZE_EXPAND_FILL
	#else:
		#%'Track Name'.size_flags_horizontal = SIZE_FILL


func update_track_progress(value:float) -> void:
	if current_track == null: return
	if track_progress_blocked: return
	%'Play Progress'.value = MathUtils.transfer_range_of_value(Vector2(0,current_track.length), Vector2(0,100), value)
	%'Track Length'.text = DBTrack.get_track_position_formatted(value) + ' / ' + DBTrack.get_track_position_formatted(current_track.length)


func update_playing(playing:bool) -> void:
	%'Play Pause'.icon = pause_icon if playing else play_icon


func _on_play_pause_pressed() -> void:
	if PlayerManager.audio_stream_player.playing:
		PlayerManager.set_playing(false)
	else:
		PlayerManager.set_playing(true)


func _on_skip_backward_pressed() -> void:
	PlayerManager.skip_backward()


func _on_skip_forward_pressed() -> void:
	PlayerManager.skip_forward()


func _on_volume_value_changed(value:float) -> void:
	PlayerManager.set_volume(value)


func _on_play_progress_drag_ended(value_changed:bool) -> void:
	if current_track == null: return
	track_progress_blocked = false
	if value_changed:
		PlayerManager.set_track_progress(MathUtils.transfer_range_of_value(Vector2(0,100), Vector2(0,current_track.length), %'Play Progress'.value))


func _on_play_progress_drag_started() -> void:
	track_progress_blocked = true


func _on_toggle_queue_toggled(toggled_on:bool) -> void:
	var queue_bar = SessionManager.main_scene.get_node('%Queue')
	var lyrics_bar = SessionManager.main_scene.get_node('%Lyrics')
	if not queue_bar: return
	if not lyrics_bar: return

	if toggled_on:
		queue_bar.show()
		if %'Toggle Lyrics'.button_pressed:
			lyrics_bar.hide()
			%'Toggle Lyrics'.button_pressed = false
	else:
		queue_bar.hide()


func _on_toggle_lyrics_toggled(toggled_on:bool) -> void:
	var queue_bar = SessionManager.main_scene.get_node('%Queue')
	var lyrics_bar = SessionManager.main_scene.get_node('%Lyrics')
	if not queue_bar: return
	if not lyrics_bar: return

	if not lyrics_bar:return
	if toggled_on:
		lyrics_bar.show()
		if %'Toggle Queue'.button_pressed:
			queue_bar.hide()
			%'Toggle Queue'.button_pressed = false
	else:
		lyrics_bar.hide()
