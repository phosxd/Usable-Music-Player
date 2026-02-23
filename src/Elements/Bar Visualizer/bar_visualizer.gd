extends PanelContainer

@export var bar_count:int = 128
@export var freq_max:float = 11050
@export var db_min:float = 60
@export var color_1 := Color.WHITE
@export var color_2 := Color.WHITE

var spectrum: AudioEffectSpectrumAnalyzerInstance
var heights:Array[Height] = []
var bar_width:float = 0


class Height:
	var high: float
	var low: float
	var current: float


func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)

	for i:int in bar_count:
		heights.append(Height.new())

	_on_resized()


func _process(_delta:float) -> void:
	if visible:
		_update_spectrum_data()
		queue_redraw()


func _draw() -> void:
	for i in bar_count:
		var height = heights[i].current
		var l_rect := Rect2(
			i * bar_width,
			size.y/2,
			bar_width-2,
			-height-size.y/2,
		)
		draw_rect(l_rect, color_1)


func _on_resized():
	bar_width = size.x / bar_count


func _update_spectrum_data() -> void:
	if spectrum == null: return
	var l_prev_hz:float = 0.0
	
	for i in bar_count:
		var l_hz:float = (i+1) * freq_max / bar_count
		var l_mag:float = spectrum.get_magnitude_for_frequency_range(l_prev_hz, l_hz).length()
		if not PlayerManager.audio_stream_player.playing:
			l_mag = 0
		var l_energy:float = clampf((db_min + linear_to_db(l_mag)) / db_min, 0, 1)
		var l_height:float = l_energy * size.y * 10.0

		if l_height > heights[i].high:
			heights[i].high = l_height
		else:
			heights[i].high = lerp(heights[i].high, l_height, 0.1)
		if l_height <= 0.0:
			heights[i].low = lerp(heights[i].low, l_height, 0.1)

		heights[i].current = lerp(heights[i].low, heights[i].high, 0.1)
		l_prev_hz = l_hz
