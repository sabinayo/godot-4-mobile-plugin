extends PanelContainer;

signal text_changed(text: String);
signal text_submitted(text: String);
signal deletion_requested();

const SETTINGS: PackedStringArray = [
	Mobile.HelpBar.ProjSettings.Paths.HIDE_ON_EXTERNAL_EVENTS,
	Mobile.HelpBar.ProjSettings.Paths.BACKGROUND,
	Mobile.HelpBar.ProjSettings.Paths.FONT,
	Mobile.HelpBar.ProjSettings.Paths.ENTER_ANIMATION,
	Mobile.HelpBar.ProjSettings.Paths.CUSTOM_ENTER_ANIMATION,
	Mobile.HelpBar.ProjSettings.Paths.ENTER_SOUND,
	Mobile.HelpBar.ProjSettings.Paths.EXIT_ANIMATION,
	Mobile.HelpBar.ProjSettings.Paths.CUSTOM_EXIT_ANIMATION,
	Mobile.HelpBar.ProjSettings.Paths.EXIT_SOUND,
	Mobile.HelpBar.ProjSettings.Paths.AUDIO_BUS,
	Mobile.HelpBar.ProjSettings.Paths.TIP_BACKGROUND,
	Mobile.HelpBar.ProjSettings.Paths.TIP_FONT,
	Mobile.HelpBar.ProjSettings.Paths.LINE_EDIT_NORMAL_BACKGROUND,
	Mobile.HelpBar.ProjSettings.Paths.LINE_EDIT_FOCUS_BACKGROUND,
	Mobile.HelpBar.ProjSettings.Paths.LINE_EDIT_FONT_SIZE,
];

var enter_anim = Mobile.HelpBar.Anims.FADE_LEFT;
var custom_enter_anim: String;
var enter_sound: String;
var exit_anim = Mobile.HelpBar.Anims.POP;
var custom_exit_anim: String;
var exit_sound: String;
var audio_bus: String;
var settings_overrides := {};

var _hide_on_external_events: bool;


func _ready() -> void: _load_settings();


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		text_submitted.emit(%edition.text);


func _input(event: InputEvent) -> void:
	if _hide_on_external_events:
		match event.get_class():
			"InputEventScreenDrag", "InputEventScreenTouch":
				var area: Rect2 = get_global_rect();
				
				if not area.has_point(event.position):
					deletion_requested.emit();


func _start_animation() -> void:
	if custom_enter_anim != "":
		var anim: Object = load(custom_enter_anim).new();
		get_tree().current_scene.add_child(anim);
		
		if anim.has_method(Mobile.CUSTOM_ANIMATION_FUNC):
			anim.animate(self);
			return;
	
	_play_sound(enter_sound);
	
	if enter_anim == Mobile.HelpBar.Anims.NONE: return;
	
	match enter_anim:
		Mobile.HelpBar.Anims.FADE:
			var tween: Tween = create_tween();
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeIn.fromAlpha;
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeIn.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeIn.duration
			);
		
		Mobile.HelpBar.Anims.FADE_DOWN:
			var tween: Tween = create_tween();
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeDownIn.fromAlpha;
			tween.set_parallel(true);
			
			var next_pos: float = global_position.y;
			var begin_pos: float = global_position.y - (global_position.y + size.y);
			
			tween.tween_property(
				self, "global_position:y",
				next_pos,
				Mobile.HelpBar.AnimsSettings.FadeDownIn.duration
			).set_ease(Tween.EASE_OUT_IN).from(begin_pos);
			
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeDownIn.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeDownIn.fadeDuration
			).set_ease(Tween.EASE_IN_OUT).set_delay(Mobile.HelpBar.AnimsSettings.FadeDownIn.fadeDelay);
		
		Mobile.HelpBar.Anims.FADE_UP:
			var tween: Tween = create_tween();
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeUpIn.fromAlpha;
			tween.set_parallel(true);
			
			var next_pos: float = global_position.y;
			var begin_pos: float = global_position.y + (global_position.y + size.y);
			
			tween.tween_property(
				self, "global_position:y",
				next_pos,
				Mobile.HelpBar.AnimsSettings.FadeUpIn.duration
			).set_ease(Tween.EASE_OUT_IN).from(begin_pos);
			
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeUpIn.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeUpIn.fadeDuration
			).set_ease(Tween.EASE_IN_OUT).set_delay(Mobile.HelpBar.AnimsSettings.FadeUpIn.fadeDelay);
		
		Mobile.HelpBar.Anims.FADE_RIGHT:
			var tween: Tween = create_tween();
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeRightIn.fromAlpha;
			
			var prev_pos: float = global_position.x;
			var begin_pos: float = global_position.x - (global_position.x + size.x);
			
			
			tween.set_parallel();
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeRightIn.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeRightIn.duration
			).set_delay(Mobile.HelpBar.AnimsSettings.FadeRightIn.fadeDelay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT);
			tween.tween_property(
				self, "global_position:x",
				prev_pos,
				Mobile.HelpBar.AnimsSettings.FadeRightIn.duration
			).from(begin_pos);
		
		Mobile.HelpBar.Anims.FADE_LEFT:
			var tween: Tween = create_tween();
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeLeftIn.fromAlpha;
			
			var next_pos: float = global_position.x;
			var begin_pos: float = global_position.x + (global_position.x + size.x);
			
			tween.set_parallel();
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeLeftIn.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeLeftIn.duration
			).set_delay(Mobile.HelpBar.AnimsSettings.FadeLeftIn.fadeDelay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);
			tween.tween_property(
				self, "global_position:x",
				next_pos,
				Mobile.HelpBar.AnimsSettings.FadeLeftIn.duration
			).from(begin_pos);
		
		Mobile.HelpBar.Anims.BOUNCE:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.Bounce.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("BOUNCE");
		
		Mobile.HelpBar.Anims.SCALE:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.Scale.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("SCALE");
		
		Mobile.HelpBar.Anims.SCALE_X:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.ScaleX.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("SCALE_X");
		
		Mobile.HelpBar.Anims.SCALE_Y:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.ScaleY.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("SCALE_Y");
		
		Mobile.HelpBar.Anims.POP:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.Pop.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("POP");


func _on_edition_text_changed(new_text: String) -> void:
	text_changed.emit(new_text);


func _on_edition_text_submitted(new_text: String) -> void:
	text_submitted.emit(new_text);


func _set_setting(setting: String, value: Variant) -> void:
	match setting:
		Mobile.HelpBar.ProjSettings.Paths.BACKGROUND:
			set("theme_override_styles/panel", value);
		
		Mobile.HelpBar.ProjSettings.Paths.TIP_BACKGROUND:
			%tip.set("theme_override_styles/normal", value);
		
		Mobile.HelpBar.ProjSettings.Paths.TIP_FONT:
			if value is String:
				%tip.label_settings = ProjectSettings.get_setting(
					Mobile.HelpBar.ProjSettings.Paths.FONT,
					Mobile.HelpBar.ProjSettings.DefaultValues.FONT
				);
			
			else:
				%tip.label_settings = value;
		
		Mobile.HelpBar.ProjSettings.Paths.LINE_EDIT_NORMAL_BACKGROUND:
			%edition.set("theme_override_styles/normal", value);
		
		Mobile.HelpBar.ProjSettings.Paths.ENTER_ANIMATION: enter_anim = value;
		
		Mobile.HelpBar.ProjSettings.Paths.CUSTOM_ENTER_ANIMATION:
			custom_enter_anim = value;
		
		Mobile.HelpBar.ProjSettings.Paths.ENTER_SOUND: enter_sound = value;
		
		Mobile.HelpBar.ProjSettings.Paths.EXIT_ANIMATION: exit_anim = value;
		
		Mobile.HelpBar.ProjSettings.Paths.EXIT_SOUND: exit_sound = value;
		
		Mobile.HelpBar.ProjSettings.Paths.AUDIO_BUS: audio_bus = value;
		
		Mobile.HelpBar.ProjSettings.Paths.CUSTOM_EXIT_ANIMATION:
			custom_exit_anim = value;
		
		Mobile.HelpBar.ProjSettings.Paths.LINE_EDIT_FOCUS_BACKGROUND:
			%edition.set("theme_override_styles/focus", value);
		
		Mobile.HelpBar.ProjSettings.Paths.LINE_EDIT_FONT_SIZE:
			%edition.set("theme_override_font_sizes/font_size", value);
		
		Mobile.HelpBar.ProjSettings.Paths.LINE_EDIT_NORMAL_BACKGROUND:
			%edition.set("theme_override_styles/normal", value);
			
		Mobile.HelpBar.ProjSettings.Paths.HIDE_ON_EXTERNAL_EVENTS:
			_hide_on_external_events = value;
			


func _load_settings() -> void:
	for setting in SETTINGS:
		if settings_overrides.has(setting):
			var value = settings_overrides[setting];
			_set_setting(setting, value);
		
		else:
			var property: String = setting.get_slice("/", setting.get_slice_count("/") - 1);
			var key: String = property.to_upper();
			
			var dflt_val = Mobile.HelpBar.ProjSettings.DefaultValues.get(key);
			
			if dflt_val == null:
				property = setting.get_slice("/", setting.get_slice_count("/") - 2);
				dflt_val = Mobile.HelpBar.ProjSettings.DefaultValues[
					"%s_%s" % [property.to_upper(), key]
				];
			
			_set_setting(
				setting, ProjectSettings.get_setting(setting, dflt_val)
			);


func delete() -> void:
	if custom_enter_anim != "":
		var anim: Object = load(custom_exit_anim).new();
		get_tree().current_scene.add_child(anim);
		
		if anim.has_method(Mobile.CUSTOM_ANIMATION_FUNC):
			anim.animate(self);
			anim.animation_finished.connect(func () -> void: queue_free());
			return;
	
	_play_sound(enter_sound);
	
	if exit_anim == Mobile.HelpBar.Anims.NONE: queue_free();
	
	match exit_anim:
		Mobile.HelpBar.Anims.FADE:
			var tween: Tween = create_tween();
			tween.finished.connect(func () -> void: queue_free());
		
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeOut.fromAlpha;
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeOut.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeOut.duration
			);
		
		Mobile.HelpBar.Anims.BOUNCE:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.Bounce.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("BOUNCE");
			await %anim.animation_finished;
			queue_free();
		
		Mobile.HelpBar.Anims.FADE_UP:
			var tween: Tween = create_tween();
			tween.finished.connect(func () -> void: queue_free());
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeUpOut.fromAlpha;
			tween.set_parallel(true);
			
			var next_pos: float = global_position.y - size.y;
			
			tween.tween_property(
				self, "global_position:y",
				next_pos,
				Mobile.HelpBar.AnimsSettings.FadeUpOut.duration
			).set_ease(Tween.EASE_OUT_IN);
			
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeUpOut.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeUpOut.fadeDuration
			).set_ease(Tween.EASE_IN_OUT).set_delay(Mobile.HelpBar.AnimsSettings.FadeUpOut.fadeDelay);
		
		Mobile.HelpBar.Anims.FADE_DOWN:
			var tween: Tween = create_tween();
			tween.finished.connect(func () -> void: queue_free());
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeDownOut.fromAlpha;
			tween.set_parallel(true);
			
			var next_pos: float = global_position.y + size.y;
			
			tween.tween_property(
				self, "global_position:y",
				next_pos,
				Mobile.HelpBar.AnimsSettings.FadeDownOut.duration
			).set_ease(Tween.EASE_OUT_IN);
			
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeDownOut.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeDownOut.fadeDuration
			).set_ease(Tween.EASE_IN_OUT).set_delay(Mobile.HelpBar.AnimsSettings.FadeDownOut.fadeDelay);
		
		Mobile.HelpBar.Anims.FADE_RIGHT:
			var tween: Tween = create_tween();
			tween.finished.connect(func () -> void: queue_free());
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeRightOut.fromAlpha;
			
			var next_pos: float = global_position.x + global_position.x + size.x;
			
			tween.set_parallel();
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeRightOut.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeRightOut.duration
			).set_delay(Mobile.HelpBar.AnimsSettings.FadeRightOut.fadeDelay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT);
			tween.tween_property(
				self, "global_position:x",
				next_pos,
				Mobile.HelpBar.AnimsSettings.FadeRightOut.duration
			);
		
		Mobile.HelpBar.Anims.FADE_LEFT:
			var tween: Tween = create_tween();
			tween.finished.connect(func () -> void: queue_free());
			modulate.a = Mobile.HelpBar.AnimsSettings.FadeLeftOut.fromAlpha;
			
			var next_pos: float = global_position.x - global_position.x - size.x;
			
			tween.set_parallel();
			tween.tween_property(
				self, "modulate:a",
				Mobile.HelpBar.AnimsSettings.FadeLeftOut.toAlpha,
				Mobile.HelpBar.AnimsSettings.FadeLeftOut.duration
			).set_delay(Mobile.HelpBar.AnimsSettings.FadeLeftOut.fadeDelay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT);
			tween.tween_property(
				self, "global_position:x",
				next_pos,
				Mobile.HelpBar.AnimsSettings.FadeLeftOut.duration
			);
		
		Mobile.HelpBar.Anims.SCALE:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.Scale.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("SCALE");
			await %anim.animation_finished;
			queue_free();
		
		Mobile.HelpBar.Anims.SCALE_X:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.ScaleX.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("SCALE_X");
			await %anim.animation_finished;
			queue_free();
		
		Mobile.HelpBar.Anims.SCALE_Y:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.ScaleY.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("SCALE_Y");
			await %anim.animation_finished;
			queue_free();
		
		Mobile.HelpBar.Anims.POP:
			var pivot: Vector2 = Mobile.HelpBar.AnimsSettings.Pop.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("POP");
			await %anim.animation_finished;
			queue_free();


func _play_sound(stream: String) -> void:
	if stream == "" or not stream.is_absolute_path(): return;
	
	var stream_player := AudioStreamPlayer.new();
	stream_player.stream = load(stream);
	stream_player.bus = audio_bus;
	get_tree().current_scene.add_child(stream_player);
	stream_player.play();
	await stream_player.finished;
	stream_player.queue_free();


func set_settings_overrides(settings: Dictionary) -> void: settings_overrides = settings;


## You must implement a function with the same name and arguments type
## in your custom scene. The type of the scene doesn't matter.
func set_edition(keyboard: int, tip: String, text: String) -> void:
	%tip.text = tip;
	%tip.visible = tip != "";
	
	if text != "":
		%edition.insert_text_at_caret(text);
	
	%edition.virtual_keyboard_type = keyboard;
	%edition.call_deferred("grab_focus");
	
	pivot_offset = size / 2;
	# Place help bar in front of all nodes
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX;
	_start_animation();
