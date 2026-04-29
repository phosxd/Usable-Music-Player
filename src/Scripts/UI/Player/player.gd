extends Control

var loop_off_icon:Texture2D = SessionManager.get_icon('scale_x2/loop')
var loop_track_icon:Texture2D = SessionManager.get_icon('scale_x2/loop_track')
var loop_queue_icon:Texture2D = SessionManager.get_icon('scale_x2/loop_queue')
var play_icon:Texture2D = SessionManager.get_icon('play')
var pause_icon:Texture2D = SessionManager.get_icon('pause')

var original_queue:Array[DBTrack] = []
var original_queue_position:int = -1
var current_track: DBTrack
var track_progress_blocked := false
var volume:float = 0.0

var visualizer_color: Color

@onready var replaygain_indicator_template:String = %'ReplayGain Indicator'.text


func  _ready() -> void:
	if PlayerManager.current_track_loading: load_started()
	PlayerManager.current_track_load_started.connect(load_started)
	PlayerManager.current_track_load_finished.connect(load_finished)
	PlayerManager.current_track_updated.connect(update_current_track)
	PlayerManager.track_progress_updated.connect(update_track_progress)
	PlayerManager.play_requested.connect(update_playing.bind(true))
	PlayerManager.pause_requested.connect(update_playing.bind(false))
	PlayerManager.volume_updated.connect(update_volume)
	PlayerManager.replay_gain_updated.connect(update_replaygain_indicator)
	PlayerManager.track_peak_volume_changed.connect(update_visualizer_2)
	SessionManager.value_changed.connect(_session_manager_value_changed)
	update_current_track(0, PlayerManager.get_current_track())
	update_track_progress(PlayerManager.track_progress)
	update_volume(PlayerManager.volume)
	update_replaygain_indicator(PlayerManager.replay_gain)
	_session_manager_value_changed('visualizer_bar_mode')
	_session_manager_value_changed('visualizer_bar_count')
	_session_manager_value_changed('visualizer_bar_smoothing')
	_session_manager_value_changed('right_sidebar_tab')


func _session_manager_value_changed(property_name:String) -> void:
	match property_name:
		'visualizer_mode':
			self.update_visualizer(SessionManager.get_accent_color())
		'visualizer_bar_count':
			%'Bar Visualizer'.bar_count = SessionManager.visualizer_bar_count
		'visualizer_bar_smoothing':
			%'Bar Visualizer'.smoothing = SessionManager.visualizer_bar_smoothing
		'right_sidebar_tab':
			var value:String = SessionManager.right_sidebar_tab
			%'Toggle Queue'.set_pressed_no_signal(value == 'queue')
			%'Toggle Lyrics'.set_pressed_no_signal(value == 'lyrics')


func load_started() -> void:
	%'Track Load Animation'.play('animation')


func load_finished() -> void:
	%'Track Load Animation'.stop()


func update_current_track(_track_queue_position:int, track:DBTrack) -> void:
	if not track: return
	current_track = track
	%'Track Name'.text = current_track.name
	%'Track Name'.button_tooltip_text = current_track.name
	%'Artist Name'.text = '%s' % [current_track.album.artist.name]
	%'Details HBox'.update()
	if %'Toggle Shuffle'.button_pressed:
		original_queue.clear()
		%'Toggle Shuffle'.button_pressed = false


func update_volume(value:float) -> void:
	%Volume.set_value_no_signal(value)
	if value == 0:
		%'Mute Button'.button_pressed = true


func update_replaygain_indicator(value:float) -> void:
	%'ReplayGain Indicator'.text = replaygain_indicator_template % snapped(value, 0.1)


func update_visualizer(color:Color, _db:float=0) -> void:
	var glow_gradient = %Glow.texture.gradient as Gradient
	visualizer_color = color
	glow_gradient.set_color(0, color)
	%'Bar Visualizer'.hide()
	%'Bar Visualizer'.process_mode = Node.PROCESS_MODE_DISABLED
	if SessionManager.visualizer_mode == SessionManager.VisualizerMode.OFF:
		%Glow.position.y = -40
	if SessionManager.visualizer_mode == SessionManager.VisualizerMode.GLOW:
		%Glow.position.y = -40
	elif SessionManager.visualizer_mode == SessionManager.VisualizerMode.BAR:
		%'Bar Visualizer'.process_mode = Node.PROCESS_MODE_INHERIT
		%'Bar Visualizer'.show()
		%Glow.position.y = -50
		glow_gradient.set_color(0, Color(0,0,0,0.5))
		%'Bar Visualizer'.color = color
	%Glow.texture.gradient = glow_gradient
	#var color_2:Color = glow_gradient.get_color(1)
	glow_gradient.set_color(1, Color(0,0,0,0))


func update_visualizer_2(db:float) -> void:
	if SessionManager.visualizer_mode == SessionManager.VisualizerMode.GLOW:
		var glow_gradient = %Glow.texture.gradient as Gradient
		var linear:float = db_to_linear(db)
		glow_gradient.set_color(0, Color(visualizer_color.r, visualizer_color.g, visualizer_color.b,
			MathUtils.transfer_range_of_value(Vector2(0,1), Vector2(0.25, 1), linear))
		)
		%Glow.texture.gradient = glow_gradient
		var color_2:Color = glow_gradient.get_color(1)
		glow_gradient.set_color(1, Color(color_2.r, color_2.g, color_2.b, 0))


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
	PlayerManager.volume = value
	volume = value
	%'Mute Button'.button_pressed = false if value > 0 else true


func _on_play_progress_drag_ended(value_changed:bool) -> void:
	if current_track == null: return
	track_progress_blocked = false
	if value_changed:
		PlayerManager.set_track_progress(MathUtils.transfer_range_of_value(Vector2(0,100), Vector2(0,current_track.length), %'Play Progress'.value))


func _on_play_progress_drag_started() -> void:
	track_progress_blocked = true


func _on_toggle_queue_toggled(toggled_on:bool) -> void:
	SessionManager.right_sidebar_tab = 'queue' if toggled_on else ''

func _on_toggle_lyrics_toggled(toggled_on:bool) -> void:
	SessionManager.right_sidebar_tab = 'lyrics' if toggled_on else ''


func _on_toggle_shuffle_toggled(toggled_on:bool) -> void:
	if toggled_on:
		original_queue_position = PlayerManager.queue_position
		original_queue = PlayerManager.queue.duplicate()
		PlayerManager.shuffle_queue(current_track)
	elif not original_queue.is_empty():
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


func _on_mute_button_toggled(toggled_on:bool) -> void:
	if toggled_on:
		volume = PlayerManager.volume
		PlayerManager.volume = 0
	else:
		PlayerManager.volume = volume


func _on_track_name_pressed() -> void:
	if not current_track: return
	SessionManager.main_scene.set_tab('album_page', current_track.album)


func _on_artist_name_pressed() -> void:
	if not current_track: return
	SessionManager.main_scene.set_tab('artist_page', current_track.album.artist)
