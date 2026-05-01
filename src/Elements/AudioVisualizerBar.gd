class_name AudioVisualizerBar extends Control

@export var colors:Array = [Color.WHITE]

## Smoothing weight. Lower values are choppier but more accurate. Higher values are smoother & floatier.
## [br][br]Should be a value between [code]0.0[/code] & [code]0.999[/code]. Should never be "fully" smoothed.
@export var smoothing:float = 0.5:
	set(value):
		smoothing = value
		_init_smoothing()

## How many updates are performed every second.
## Leave at [code]-1[/code] if this should be the same as your project frame rate.
@export var frame_rate:int = -1:
	set(value):
		frame_rate = value
		_init_frame_rate()

@export var bar_count:int = 128:
	set(value):
		bar_count = value
		_init_data()
		_on_resized()

@export var freq_max:float = 11050
@export var db_min:float = 60
@export var align_top:bool = false
@export var position_offset := Vector2.ZERO

var spectrum: AudioEffectSpectrumAnalyzerInstance
var bar_width:float = 0
var data:Array[float] = []
var _smoothing:float = 0
var _update_time:float = 0
var _time_passed:float = 0
var _idle_time:float = 0


func _ready() -> void:
	_init_frame_rate()
	_init_smoothing()
	_init_data()
	spectrum = AudioServer.get_bus_effect_instance(0,0)

	resized.connect(_on_resized)
	_on_resized()


func _on_resized():
	bar_width = size.x / bar_count


func _process(delta:float) -> void:
	if visible:
		_time_passed += delta
		if _time_passed > _update_time && _idle_time < 7.0:
			_update_data()
			queue_redraw()
			_time_passed = 0

		if PlayerManager.is_playing:
			_idle_time = 0
		else:
			_idle_time += delta


func _draw() -> void:
	if data.is_empty(): return
	for i in bar_count:
		var height = data[i]
		var rect := Rect2(
			(i*bar_width) + position_offset.x,
			size.y + position_offset.y - (size.y if align_top else 0.0),
			bar_width-2,
			-MathUtils.transfer_range_of_value(Vector2(0,1), Vector2(0,size.y), height),
		)
		if self.visible: draw_rect(rect, colors[wrap(i, 0, colors.size())])


## Sets [param _smoothing] to a usable value based on [param smoothing].
func _init_smoothing() -> void:
	_smoothing = MathUtils.transfer_range_of_value(Vector2(0,1), Vector2(1,0), smoothing)


## Sets [param _update_time] to a usable value based on [param frame_rate].
func _init_frame_rate() -> void:
	_update_time = 1.0 / (ProjectSettings.get_setting('application/run/max_fps') if frame_rate == -1 else frame_rate)


## Initialize the data.
func _init_data() -> void:
	data.clear()
	data.resize(bar_count)
	data.fill(0.0)


## Update the visualizer data using [param spectrum].
func _update_data() -> void:
	if not spectrum: return

	var last_hz:float = 0
	for i in bar_count:
		var hz:float = (i+1) * freq_max/bar_count # Get Hz for current iteration.
		var value:float = 0
		if PlayerManager.is_playing: value = spectrum.get_magnitude_for_frequency_range(last_hz, hz).length()
		value = clampf((db_min+linear_to_db(value))/db_min, 0, 1) # Convert value to a proper range.

		value = lerp(data.get(i), value, _smoothing) # Apply smoothing.
		data.set(i, value)
		last_hz = hz
