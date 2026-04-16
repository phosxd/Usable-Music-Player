extends Control

const nodes_to_hide:Array[String] = [
	'Topbar',
	'Sidebar',
]
@onready var default_shadow_style:StyleBox = %Shadow.get_theme_stylebox('panel')
@export var overlay_color := Color(0.25, 0.25, 0.25, 0.5)
var dominant_colors:Array[Color] = []


func _ready() -> void:
	PlayerManager.current_track_updated.connect(update_current_track)
	PlayerManager.track_peak_volume_changed.connect(update_visualizer)
	update_current_track(0, PlayerManager.get_current_track())

	for node_name in nodes_to_hide:
		SessionManager.main_scene.get_node('%'+node_name).hide()


func _exit_tree() -> void:
	for node_name in nodes_to_hide:
		SessionManager.main_scene.get_node('%'+node_name).show()


func update_current_track(_track_queue_position:int, track:DBTrack) -> void:
	if not track: return
	track.album.get_cover_threaded(func(cover) -> void:
		%Image.texture = cover
	)
	var dominant_color = track.album.get_album_dominant_color()
	dominant_colors = [
		dominant_color,
		track.album.palette.get('secondary', Color.WHITE),
		track.album.palette.get('trinary', Color.WHITE),
		track.album.palette.get('blend_full', Color.WHITE),
	]
	dominant_colors.shuffle()
	var mat = %'Background'.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))
	var new_style = default_shadow_style.duplicate()
	var shadow_color:Color = dominant_color
	shadow_color.v = 1.0
	shadow_color.a = 0.3
	new_style.shadow_color = shadow_color
	new_style.shadow_size = 14
	%Shadow.remove_theme_stylebox_override('panel')
	%Shadow.add_theme_stylebox_override('panel', new_style)


func update_visualizer(_db:float) -> void:
	pass
	#var linear := db_to_linear(db)
	#var value = linear*0.075
	#var color:Color = Color(overlay_color.r, overlay_color.g, overlay_color.b, overlay_color.a*linear*0.25)
	#var mat = %'Background'.material
	#var index:int = -1
	#for i in ['topright','topleft','bottomright','bottomleft']:
		#index += 1
		#var i_color:Color = dominant_colors[index]
		#mat.set_shader_parameter(i, i_color.blend(color))


func _on_button_pressed() -> void:
	SessionManager.main_scene.go_back()
