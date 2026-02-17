extends Control

const loop_off_icon := preload('res://Assets/Icons/scale_x2/loop.svg')
const loop_track_icon := preload('res://Assets/Icons/scale_x2/loop_track.svg')
const loop_queue_icon := preload('res://Assets/Icons/scale_x2/loop_queue.svg')
const play_icon := preload('res://Assets/Icons/play.svg')
const pause_icon := preload('res://Assets/Icons/pause.svg')

var original_queue:Array[DBTrack] = []
var original_queue_position:int = -1
var current_track: DBTrack
var track_progress_blocked := false


func  _ready() -> void:
	PlayerManager.current_track_updated.connect(update_current_track)
	PlayerManager.track_progress_updated.connect(update_track_progress)
	PlayerManager.play_requested.connect(update_playing.bind(true))
	PlayerManager.pause_requested.connect(update_playing.bind(false))
	update_current_track(0, PlayerManager.get_current_track())
	update_track_progress(PlayerManager.track_progress)


func update_current_track(_track_queue_position:int, track:DBTrack) -> void:
	if not track: return
	current_track = track
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


func _on_toggle_shuffle_toggled(toggled_on:bool) -> void:
	if toggled_on:
		original_queue_position = PlayerManager.queue_position
		original_queue = PlayerManager.queue.duplicate()
		PlayerManager.shuffle_queue(current_track)
	else:
		PlayerManager.set_queue(original_queue)
		PlayerManager.queue_position = original_queue_position
		original_queue = []


func _on_swap_loop_mode_pressed() -> void:
	match PlayerManager.loop_mode:
		PlayerManager.LoopMode.OFF:
			PlayerManager.loop_mode = PlayerManager.LoopMode.TRACK
			%'Swap Loop Mode'.icon = loop_track_icon
			%'Swap Loop Mode'.button_pressed = true
		PlayerManager.LoopMode.TRACK:
			PlayerManager.loop_mode = PlayerManager.LoopMode.QUEUE
			%'Swap Loop Mode'.icon = loop_queue_icon
			%'Swap Loop Mode'.button_pressed = true
		PlayerManager.LoopMode.QUEUE:
			PlayerManager.loop_mode = PlayerManager.LoopMode.OFF
			%'Swap Loop Mode'.icon = loop_off_icon
			%'Swap Loop Mode'.button_pressed = false
