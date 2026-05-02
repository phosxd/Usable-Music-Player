extends Control

const nodes_to_hide:Array[String] = [
	'Topbar',
	'Sidebar',
	'Right Sidebar Margin',
]
var previous_global_margin:Array[int] = []
@onready var default_shadow_style:StyleBox = %Shadow.get_theme_stylebox('panel')
var dominant_colors:Array[Color] = []


func _ready() -> void:
	# Hide main screen UI.
	for node_name in nodes_to_hide:
		var node:Node = SessionManager.main_scene.get_node('%'+node_name)
		node.hide()
		node.set_process(false)

	# Remove global margins.
	var global_margin = (SessionManager.main_scene.get_node('%Global Margin') as MarginContainer)
	for item in ['left','top','right','bottom']:
		previous_global_margin.append(global_margin.get_theme_constant('margin_%s' % item))
		global_margin.add_theme_constant_override('margin_%s' % item, 0)

	# Replace player.
	SessionManager.main_scene.get_node('%Player').hide()
	for button:Node in %Player.get_buttons():
		if button is not Button: continue
		var style:StyleBox = button.get_theme_stylebox('normal').duplicate()
		style.bg_color = Color(style.bg_color.r, style.bg_color.g, style.bg_color.b, 0.5)
		button.add_theme_stylebox_override('normal', style)

	# Apply texture to background.
	var bg_texture = SessionManager.get_immersive_view_texture()
	if bg_texture:
		%Background.texture = bg_texture
	# Apply random noise seed to background texture.
	if %Background.texture is NoiseTexture2D:
		%Background.texture.noise.seed = randi_range(0,100_000)

	# Connect signals.
	PlayerManager.current_track_updated.connect(update_current_track)
	PlayerManager.track_peak_volume_changed.connect(update_visualizer)
	update_current_track(0, PlayerManager.get_current_track())


func _exit_tree() -> void:
	# Restore main screen UI.
	for node_name in nodes_to_hide:
		var node:Node = SessionManager.main_scene.get_node('%'+node_name)
		node.show()
		node.set_process(true)

	# Restore global margins.
	var global_margin = (SessionManager.main_scene.get_node('%Global Margin') as MarginContainer)
	var i:int = -1
	for item in ['left','top','right','bottom']:
		i += 1
		global_margin.add_theme_constant_override('margin_%s' % item, previous_global_margin[i])

	# Restore normal player.
	SessionManager.main_scene.get_node('%Player').show()


func _process(delta:float) -> void:
	# Animate background.
	if Engine.get_process_frames() % 2 == 0 && %Background.texture is NoiseTexture2D:
		var noise:FastNoiseLite = (%Background.texture as NoiseTexture2D).noise
		noise.offset.z += delta*75


func update_current_track(_track_queue_position:int, track:DBTrack) -> void:
	if not track: return
	# Set album cover.
	track.album.get_cover_threaded(func(cover) -> void:
		%Image.texture = cover
	)

	# Update background colors.
	var dominant_color = track.album.get_album_dominant_color()
	dominant_colors = [
		dominant_color,
		track.album.palette.get('secondary', Color.WHITE),
		track.album.palette.get('trinary', Color.WHITE),
	]
	if %Background.texture is NoiseTexture2D:
		var ramp:Gradient = %Background.texture.color_ramp
		for i in ramp.colors.size():
			ramp.set_color(i, dominant_colors[wrap(i,0,2)])
		%Background.self_modulate = Color.WHITE

	# Update album cover shadow.
	var new_style = default_shadow_style.duplicate()
	var shadow_color:Color = dominant_color
	shadow_color.v = 1.0
	shadow_color.a = 0.3
	new_style.shadow_color = shadow_color
	new_style.shadow_size = 14
	%Shadow.remove_theme_stylebox_override('panel')
	%Shadow.add_theme_stylebox_override('panel', new_style)


var prev_bg_color := Color.WHITE
func update_visualizer(db:float) -> void:
	if not SessionManager.reactive_immersive_view:
		%Background.self_modulate = Color.WHITE
		return

	var linear := db_to_linear(db)
	var bg_color := Color.WHITE*linear
	bg_color.a = 1.0
	bg_color.v = max(0.3,min(1.5,bg_color.v))
	bg_color = lerp(prev_bg_color, bg_color, 0.025)
	%Background.self_modulate = bg_color
	prev_bg_color = bg_color


func _on_button_pressed() -> void:
	SessionManager.main_scene.go_back()


func _on_right_item_visibility_changed() -> void:
	if not %Lyrics.visible && not %Queue.visible:
		%'Middle Separator'.hide()
	else:
		%'Middle Separator'.show()
