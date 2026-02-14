extends Control

@onready var default_shadow_style:StyleBox = %Shadow.get_theme_stylebox('panel')


func _ready() -> void:
	PlayerManager.current_track_updated.connect(update_current_track)
	update_current_track(PlayerManager.queue_position)


func update_current_track(track_queue_position:int) -> void:
	if track_queue_position+1 > PlayerManager.queue.size(): return
	var track:DBTrack = PlayerManager.queue[track_queue_position]
	%Image.texture = track.album.cover
	var dominant_color:Color = track.album.get_album_dominant_color()
	var dom_color_2 = Color(dominant_color.r-0.1, dominant_color.g-0.1, dominant_color.b-0.1)
	var dom_color_3 = Color(dominant_color.r-0.1, dominant_color.g+0.1, dominant_color.b-0.1)
	var dom_color_4 = Color(dominant_color.r+0.1, dominant_color.g-0.1, dominant_color.b+0.1)
	var overlay_color = Color(0.25, 0.25, 0.25, 0.5)
	var mat = %'Background'.material
	mat.set_shader_parameter('topleft', dominant_color.blend(overlay_color))
	mat.set_shader_parameter('topright', dom_color_2.blend(overlay_color))
	mat.set_shader_parameter('bottomleft', dom_color_3.blend(overlay_color))
	mat.set_shader_parameter('bottomright', dom_color_4.blend(overlay_color))
	var new_style = default_shadow_style.duplicate()
	new_style.shadow_color = Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.6)
	new_style.shadow_size = 14
	%Shadow.remove_theme_stylebox_override('panel')
	%Shadow.add_theme_stylebox_override('panel', new_style)
