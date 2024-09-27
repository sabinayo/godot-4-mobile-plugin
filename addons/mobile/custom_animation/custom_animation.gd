class_name MobileCustomAnimation;

extends Node;

enum _SoundStates {
	ENTER, EXIT
};

enum _AnimationFallBacks {
	TOOLTIP,
	HELP_BAR
};

signal animation_finished();


func animate(obj: Control) -> void:
	pass;


func _play_sound(
	stream_path: String, audio_bus := "Master", volume_db := 0.0,
	pitch_scale = 1.0, mix_target := AudioStreamPlayer.MIX_TARGET_STEREO
) -> void:
	if stream_path == "" or not stream_path.is_absolute_path(): return;
	
	var stream_player := AudioStreamPlayer.new();
	stream_player.stream = load(stream_path);
	stream_player.pitch_scale = pitch_scale;
	stream_player.volume_db = volume_db;
	stream_player.mix_target = mix_target;
	
	add_child(stream_player);
	stream_player.play();
	await stream_player.finished;
	stream_player.queue_free();


func _play_sound_from_project_settings(
	sound_state := _SoundStates.ENTER,
	fall_back := _AnimationFallBacks.HELP_BAR
) -> void:
	var data := {
		"values": {
			_SoundStates.ENTER: {
				_AnimationFallBacks.TOOLTIP: ProjectSettings.get_setting(
					Mobile.Tooltip.ProjSettings.Paths.ENTER_SOUND,
					Mobile.Tooltip.ProjSettings.DefaultValues.ENTER_SOUND,
				),
				_AnimationFallBacks.HELP_BAR: ProjectSettings.get_setting(
					Mobile.HelpBar.ProjSettings.Paths.ENTER_SOUND,
					Mobile.HelpBar.ProjSettings.DefaultValues.ENTER_SOUND,
				),
			},
			_SoundStates.EXIT: {
				_AnimationFallBacks.TOOLTIP: ProjectSettings.get_setting(
					Mobile.Tooltip.ProjSettings.Paths.EXIT_SOUND,
					Mobile.Tooltip.ProjSettings.DefaultValues.EXIT_SOUND,
				),
				_AnimationFallBacks.HELP_BAR: ProjectSettings.get_setting(
					Mobile.HelpBar.ProjSettings.Paths.EXIT_SOUND,
					Mobile.HelpBar.ProjSettings.DefaultValues.EXIT_SOUND,
				),
			},
		},
		"paths": {
			_SoundStates.ENTER: {
				_AnimationFallBacks.TOOLTIP: Mobile.Tooltip.ProjSettings.Paths.ENTER_SOUND,
				_AnimationFallBacks.HELP_BAR: Mobile.HelpBar.ProjSettings.Paths.ENTER_SOUND,
			},
			_SoundStates.EXIT: {
				_AnimationFallBacks.TOOLTIP: Mobile.Tooltip.ProjSettings.Paths.EXIT_SOUND,
				_AnimationFallBacks.HELP_BAR: Mobile.HelpBar.ProjSettings.Paths.EXIT_SOUND,
			},
		},
	};
	
	var cur_anim: _AnimationFallBacks;
	
	if fall_back == _AnimationFallBacks.HELP_BAR:
		cur_anim = _AnimationFallBacks.TOOLTIP;
	else:
		cur_anim = _AnimationFallBacks.HELP_BAR;
	
	var sound_path: String = data["values"][sound_state][cur_anim];
	
	if sound_path == "":
		push_warning("No sound found at '%s' switching to '%s'" % [
			data["paths"][sound_state][cur_anim],
			data["paths"][sound_state][fall_back],
		]);
		sound_path = data["values"][sound_state][fall_back];
	
	if sound_path == "":
		push_error("No sound found at '%s' and '%s'. Set one of them or disable current custom animation(%s)" % [
			data["paths"][sound_state][cur_anim],
			data["paths"][sound_state][fall_back],
			get_script().get_path()
		]);







