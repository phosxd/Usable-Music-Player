extends Control

const margin:int = 190
@onready var default_shadow_style:StyleBox = %Shadow.get_theme_stylebox('panel')
@export var overlay_color := Color(0.25, 0.25, 0.25, 0.5)
var dominant_colors:Array[Color] = []


func _ready() -> void:
	var sidebar = SessionManager.main_scene.get_node('%Sidebar')
	if sidebar is Control:
		sidebar.hide()

	PlayerManager.current_track_updated.connect(update_current_track)
	PlayerManager.track_peak_volume_changed.connect(update_visualizer)
	update_current_track(0, PlayerManager.get_current_track())
	_on_image_margin_item_rect_changed()


func _exit_tree() -> void:
	var sidebar = SessionManager.main_scene.get_node('%Sidebar')
	if sidebar is Control:
		sidebar.show()


func update_current_track(_track_queue_position:int, track:DBTrack) -> void:
	if not track: return
	%Image.texture = track.album.cover
	var dominant_color = track.album.get_album_dominant_color()
	dominant_colors = [
		dominant_color,
		Color(dominant_color.r-0.1, dominant_color.g-0.1, dominant_color.b-0.1),
		Color(dominant_color.r-0.1, dominant_color.g+0.1, dominant_color.b-0.1),
		Color(dominant_color.r+0.1, dominant_color.g-0.1, dominant_color.b+0.1),
	]
	var mat = %'Background'.material
	var index:int = -1
	for i in ['topright','topleft','bottomright','bottomleft']:
		index += 1
		mat.set_shader_parameter(i, dominant_colors[index].blend(overlay_color))
	var new_style = default_shadow_style.duplicate()
	new_style.shadow_color = Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.6)
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


func _on_image_margin_item_rect_changed() -> void:
	var default_size := SessionManager.default_window_size
	var current_size := get_window().size
	var new_margin = MathUtils.transfer_range_of_value(Vector2(0,default_size.y), Vector2(0,current_size.y), margin/2.0)
	%'Image Margin'.add_theme_constant_override('margin_bottom', new_margin)
	%'Image Margin'.add_theme_constant_override('margin_top', new_margin)
	%'Image Margin'.add_theme_constant_override('margin_left', new_margin)
	%'Image Margin'.add_theme_constant_override('margin_right', new_margin)


func _on_image_item_rect_changed() -> void:
	%Shadow.size = %Image.size
	%Shadow.position = %Image.global_position
	%Button.size = %Image.size
	%Button.position = %Image.global_position


func _on_button_pressed() -> void:
	SessionManager.main_scene.call('set_tab', 'albums')
