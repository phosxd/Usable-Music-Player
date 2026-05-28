extends Object

enum LibraryType {
	LocalDirectory,
	NavidromeServer,
}

enum ReplayGainMode {
	None,
	Track,
	Album,
	Auto,
}

enum AccentMode {
	System,
	Dynamic,
	Custom,
}

## Audio visualizer mode.
enum VisualizerMode {
	OFF,
	GLOW,
	BAR,
}

const image_detail_values:Dictionary[int,int] = {
	0: 100,
	1: 300,
	2: 600,
	3: 800,
	4: 1200,
	5: 1800,
}

const sections:Array[Array] = [
	['Library', [
		'auto_scan_internal',
	]],
	['Audio', [
		'replay_gain',
		'replay_gain_preamp',
	]],
	['Theme', [
		'theme',
		'theme_mode',
		'accent_mode',
		'visualizer_mode',
		'visualizer_bar_count',
		'visualizer_bar_smoothing',
		'custom_accent',
		'panel_tint',
		'button_tint',
	]],
	['UI', [
		'landing_page',
		'grid_item_size',
		'queue_size_limit',
		'image_detail',
	]],
	['Immersive View', [
		'immersive_view_slide_away_player',
		'immersive_view_reactive_background',
		'immersive_view_texture_name',
	]],
	['API', [
		'fetch_lyrics',
		'fetch_artist_cover',
		'fetch_album_cover',
		'send_track_finished_notif',
		'send_library_scan_finished_notif',
	]],
]

const property_data:Array[Array] = [
	# Library settings.
	['library_order',[TYPE_PACKED_STRING_ARRAY]],
	['visible_libraries',[TYPE_PACKED_STRING_ARRAY]],
	['auto_scan_interval',[TYPE_INT,TYPE_FLOAT]],
	# Theme.
	['theme',[TYPE_STRING]],
	['theme_mode',[TYPE_INT]],
	['accent_mode',[TYPE_INT]],
	['visualizer_mode',[TYPE_INT]],
	['visualizer_bar_count',[TYPE_INT]],
	['visualizer_bar_smoothing',[TYPE_FLOAT]],
	['custom_accent',[TYPE_COLOR]],
	['panel_tint',[TYPE_COLOR]],
	['button_tint',[TYPE_COLOR]],
	# UI.
	['landing_page',[TYPE_STRING]],
	['grid_item_size',[TYPE_INT,TYPE_FLOAT]],
	['queue_size_limit',[TYPE_INT]],
	['image_detail',[TYPE_INT]],
	['clear_queue_warning',[TYPE_BOOL]],
	# Immersive View.
	['immersive_view_slide_away_player',[TYPE_BOOL]],
	['immersive_view_reactive_background',[TYPE_BOOL]],
	['immersive_view_texture_name',[TYPE_STRING]],
	# Audio.
	['replay_gain_mode',[TYPE_INT]],
	['replay_gain_preamp',[TYPE_FLOAT]],
	# API.
	['fetch_lyrics',[TYPE_BOOL]],
	['fetch_artist_cover',[TYPE_BOOL]],
	['fetch_album_cover',[TYPE_BOOL]],
	['send_track_finished_notif',[TYPE_BOOL]],
	['send_library_scan_finished_notif',[TYPE_BOOL]],

	# Misc data.
	['user_data_bytes',[TYPE_INT]],
	# Tab data.
	['last_tab',[TYPE_STRING]],
	['artists_tab_scroll_value',[TYPE_FLOAT]],
	['albums_tab_scroll_value',[TYPE_FLOAT]],
	['tracks_tab_scroll_value',[TYPE_FLOAT]],
	['right_sidebar_tab',[TYPE_STRING]],
	['tab_content_split',[TYPE_PACKED_INT32_ARRAY]],
	# Sort data.
	['folded_sections',[TYPE_PACKED_STRING_ARRAY]],
	['search_term',[TYPE_STRING]],
	['artist_sort_mode',[TYPE_INT]],
	['artist_ascend_mode',[TYPE_BOOL]],
	['album_sort_mode',[TYPE_INT]],
	['album_ascend_mode',[TYPE_BOOL]],
	['track_sort_mode',[TYPE_INT]],
	['track_ascend_mode',[TYPE_BOOL]],
]


#region library settings

var library_order: PackedStringArray
var visible_libraries: PackedStringArray
## How many minutes to wait before automatically scanning.
var auto_scan_interval:float = 0.5:
	set(value):
		auto_scan_interval = value
		if value == 0: auto_scan_timer.wait_time = 999_999_999_999
		else: auto_scan_timer.wait_time = value*60.0
		if auto_scan_timer.is_node_ready():
			auto_scan_timer.stop()
			auto_scan_timer.start()

#endregion

#region audio settings

var replay_gain_mode := ReplayGainMode.Album
var replay_gain_preamp:float = 0.0

#endregion

#region ui settings

var grid_item_size:float = 175
## The maximum number of items allowed in the queue at once.
var queue_size_limit:int = 150

## Image detail for album & artist covers.
## Resets cached album cover images when set.
var image_detail:int = image_detail_values[3]:
	set(value):
		image_detail = value
		for album:DBAlbum in LibraryManager.get_albums_sorted():
			if not album: continue
			album._cover = null

var clear_queue_warning:bool = true

#endregion

#region theme settings

var theme:String = '':
	set(value):
		theme = value
		ThemeManager.set_theme(value)

var theme_mode:int = 0:
	set(value):
		theme_mode = value
		ThemeManager.set_theme_mode(value)

var accent_mode := AccentMode.System

var custom_accent := Color(0.9, 0.9, 0.9)

var visualizer_mode:VisualizerMode = VisualizerMode.OFF

var visualizer_bar_count:int = 125

var visualizer_bar_smoothing:float = 0.5

var panel_tint := Color.TRANSPARENT:
	set(value):
		panel_tint = value
		ThemeManager.panel_tint = value

var button_tint := Color.TRANSPARENT:
	set(value):
		button_tint = value
		ThemeManager.button_tint = value

#endregion

#region immersive view

var immersive_view_slide_away_player:bool = true
var immersive_view_reactive_background:bool = false
var immersive_view_texture_name:String = 'Stripes'

#endregion

#region api settings

var fetch_lyrics:bool = true
var fetch_artist_cover:bool = false
var fetch_album_cover:bool = false
var send_track_finished_notif:bool = true
var send_library_scan_finished_notif:bool = true

#endregion

#region misc data

var user_data_bytes:int = 0

#endregion

#region sorting data

var folded_sections: PackedStringArray

## Global search term.
var search_term:String = ''
## Artists tab sort mode.
var artist_sort_mode := DBLibrary.ArtistSortMode.title

## Artists tab ascend mode.
var artist_ascend_mode:bool = true

## Albums tab sort mode.
var album_sort_mode := DBLibrary.AlbumSortMode.title

## Albums tab ascend mode.
var album_ascend_mode:bool = true

## Tracks tab sort mode.
var track_sort_mode := DBLibrary.TrackSortMode.title

## Tracks tab ascend mode.
var track_ascend_mode:bool = true

var landing_page:String = ''

var last_tab:String = 'albums'

var right_sidebar_tab:String = ''

var main_split := PackedInt32Array()

var artists_tab_scroll_value:float = 0
var albums_tab_scroll_value:float = 0
var tracks_tab_scroll_value:float = 0

#endregion


var immersive_view_texture_names:Array[String] = []

var auto_scan_timer := Timer.new()


func _init() -> void:
	for mod:TesseractMod in TesseractAPI.mod_instances.values():
		var files:PackedStringArray = mod.get_files_at('Assets/Immersive View Textures')
		for file_path in files:
			immersive_view_texture_names.append(file_path.split('/')[0].get_basename())

	for file_name:String in DirAccess.get_files_at('res://Assets/Immersive View Textures'):
		immersive_view_texture_names.append(file_name.get_basename())


func session_loaded() -> void:
	# Configure auto-scan timer.
	auto_scan_timer.one_shot = false
	auto_scan_timer.autostart = true
	auto_scan_interval = auto_scan_interval
	auto_scan_timer.timeout.connect(LibraryManager.scan_all_libraries)
	SessionManager.add_child(auto_scan_timer)


func get_immersive_view_texture() -> Texture2D:
	var texture
	var texture_path:String = 'res://Assets/Immersive View Textures/%s.tres' % immersive_view_texture_name
	if ResourceLoader.exists(texture_path): texture = load(texture_path)
	return texture
