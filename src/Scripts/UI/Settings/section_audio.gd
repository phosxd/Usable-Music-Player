extends Control

const section:String = 'audio'


func _ready() -> void:
	%'Audio Fold'.folded = self.section in SessionManager.folded_sections
	%'Replay Gain'.selected = SessionManager.replay_gain_mode
	%'Replay Gain Preamp'.value = SessionManager.replay_gain_preamp


func _on_audio_fold_folding_changed(is_folded:bool) -> void:
	if is_folded && self.section not in SessionManager.folded_sections:
		SessionManager.folded_sections.append(self.section)
	else:
		SessionManager.folded_sections.erase(self.section)


func _on_replay_gain_item_selected(index:int) -> void:
	SessionManager.replay_gain_mode = index as SessionManager.ReplayGainMode


func _on_replay_gain_preamp_value_changed(value:float) -> void:
	SessionManager.replay_gain_preamp = value
