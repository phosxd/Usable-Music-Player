extends Control

const section:String = 'Audio'


func _ready() -> void:
	%'Audio Fold'.folded = section in SessionManager.get_var('folded_sections')
	%'Replay Gain'.selected = SessionManager.get_var('replay_gain_mode')
	%'Replay Gain Preamp'.value = SessionManager.get_var('replay_gain_preamp')


func _on_audio_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && section not in SessionManager.get_var('folded_sections'):
		SessionManager.get_var('folded_sections').append(section)
	else:
		SessionManager.get_var('folded_sections').erase(section)


func _on_replay_gain_item_selected(index:int) -> void:
	SessionManager.set_var('replay_gain_mode', index)


func _on_replay_gain_preamp_value_changed(value:float) -> void:
	SessionManager.set_var('replay_gain_preamp', value)
