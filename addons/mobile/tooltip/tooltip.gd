extends Label;

signal delay_before_exit_ended();

enum Positions {ABOVE, BELOW, LEFT, RIGHT};

const MARGIN_X: int = 10;
const MARGIN_Y: int = 10;

const SETTINGS: PackedStringArray = [
	Mobile.Tooltip.ProjSettings.Paths.MARGIN,
	Mobile.Tooltip.ProjSettings.Paths.INDICATOR_MARGIN,
	Mobile.Tooltip.ProjSettings.Paths.ENTER_SOUND,
	Mobile.Tooltip.ProjSettings.Paths.EXIT_SOUND,
	Mobile.Tooltip.ProjSettings.Paths.AUDIO_BUS,
	Mobile.Tooltip.ProjSettings.Paths.ENTER_ANIMATION,
	Mobile.Tooltip.ProjSettings.Paths.CUSTOM_ENTER_ANIMATION,
	Mobile.Tooltip.ProjSettings.Paths.EXIT_ANIMATION,
	Mobile.Tooltip.ProjSettings.Paths.CUSTOM_EXIT_ANIMATION,
	Mobile.Tooltip.ProjSettings.Paths.DELAY_BEFORE_EXIT_SEC,
	Mobile.Tooltip.ProjSettings.Paths.REQUESTER_INDICATOR_ANIMATION,
	Mobile.Tooltip.ProjSettings.Paths.DISPLAY_REQUESTER_INDICATOR,
	Mobile.Tooltip.ProjSettings.Paths.DEFAULT_POSITION,
	Mobile.Tooltip.ProjSettings.Paths.TEXT_HORIZONTAL_ALIGNMENT,
	Mobile.Tooltip.ProjSettings.Paths.TEXT_VERTICAL_ALIGNMENT,
	Mobile.Tooltip.ProjSettings.Paths.FONT,
	Mobile.Tooltip.ProjSettings.Paths.BACKGROUND,
];

var margin: int;
var indicator_margin: int;
var enter_anim: String;
var custom_enter_anim: String;
var exit_anim: String;
var custom_exit_anim: String;
var enter_sound: String;
var exit_sound: String;
var delay_before_exit: float;
var audio_bus: String;
var requester_indicator_anim: String;
var display_requester_indicator: bool;
var relative_position: String;# relative to requester position
var requester_rect: Rect2;
var cur_relative_pos: Positions;# relative to requester position

var _tween: Tween; # use a global tween to avoid start and delete anim conflicts
var _data := {};

## You must implement a function with the same name in your custom scene.
## The type of the scene doesn't matter. When using a custom
## scene, you'll have to script your own tooltip logic.
## "data" content:
##     "text",# the tooltip_text
##     "requester",# absolute path to the tooltip requester
##     "event_position",# position of the finger in global coordinates
##     "settings_overrides",# custom settings for a single tooltip
func set_mobile_tooltip(data: Dictionary) -> void: _data = data;


func _load_data() -> void:
	text = _data["text"];
	requester_rect = get_node(_data["requester"]).get_global_rect();


func _place_requester_indicator() -> void:
	if !display_requester_indicator: return;
	
	# Hides indicator during positionnement
	%requester_indicator.modulate.a = 0.0;
	
	# Adapt indicator to small tooltip
	if %requester_indicator.size.y > size.y:
		%requester_indicator.size.y = size.y;
		await get_tree().process_frame;
	
	var requester_center: Vector2 = requester_rect.end / 2.0;
	var center: Vector2 = (global_position + size) / 2.0;
	var requester_global_center: Vector2 = (requester_rect.position + requester_rect.end) / 2.0;
	
	match cur_relative_pos:
		Positions.ABOVE, Positions.BELOW:
			var diff: float = global_position.y - requester_rect.position.y;
			
			# tooltip below requester.
			if diff > 0.0:
				# Center the indicator along the y axis.
				%requester_indicator.global_position.y = global_position.y - %requester_indicator.size.y + indicator_margin;
			
			# tooltip above requester
			elif diff < 0.0:
				# Center the indicator along the y axis.
				%requester_indicator.global_position.y = (global_position.y + size.y) - %requester_indicator.size.y + indicator_margin;
			
			await get_tree().process_frame;
			%requester_indicator.global_position.x = requester_global_center.x - (%requester_indicator.size.x / 2.0);
			var screen: Vector2 = get_viewport_rect().end;
			
			# Clamp requester inside screen area.
			if %requester_indicator.global_position.x <= 0.0:
				%requester_indicator.global_position.x = MARGIN_X + global_position.x;
			
			elif %requester_indicator.global_position.x + %requester_indicator.size.x >= screen.x:
				# Keep indicator inside tooltip area.
				var diffx: float = screen.x - (global_position.x + size.x);
				%requester_indicator.global_position.x = screen.x - %requester_indicator.size.x - margin - diffx;
		
		Positions.LEFT, Positions.RIGHT:
			var diff: float = global_position.x - requester_rect.position.x;
			
			# tooltip to the right of the requester
			if diff > 0:
				# Center the indicator along x axis
				%requester_indicator.global_position.x = global_position.x - (%requester_indicator.size.x / 4.0) + indicator_margin;
			
			# tooltip to the left of the requester
			elif diff < 0:
				# Center the indicator along x axis
				%requester_indicator.global_position.x = global_position.x + size.x - (%requester_indicator.size.x / 2.0) + indicator_margin;
			
			await get_tree().process_frame;
			%requester_indicator.global_position.y = requester_global_center.y - (%requester_indicator.size.y / 2.0);
	
	# Shows indicator
	%requester_indicator.modulate.a = 1.0;
	_start_requester_indicator_animation();


# Return true on sucess, false otherwise
func set_position_to(pos: Positions, rect: Rect2, force := false) -> bool:
	var screen := get_viewport_rect().end;
	
	match pos:
		Positions.ABOVE:
			global_position.x = ((rect.position.x + rect.end.x) / 2.0) - (size.x / 2.0);
			global_position.y = rect.position.y - rect.size.y - size.y - margin;
			await get_tree().process_frame;
			
			if global_position.x <= 0.0:
				global_position.x = MARGIN_X;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			elif global_position.x + size.x >= screen.x:
				global_position.x = screen.x - size.x - margin;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			if force:
				if global_position.x + size.x >= screen.x:
					global_position.x = screen.x - size.x - margin;
					await get_tree().process_frame;
			
			if global_position.y <= 0.0:
				global_position.y = MARGIN_Y;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			cur_relative_pos = Positions.ABOVE;
		
		Positions.BELOW:
			global_position.x = ((rect.position.x + rect.end.x) / 2.0) - (size.x / 2.0);
			global_position.y = rect.position.y + rect.size.y + size.y + margin;
			await get_tree().process_frame;
			
			if global_position.y + size.y >= screen.y:
				global_position.y = screen.y - size.y - margin;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			if global_position.x <= 0.0:
				global_position.x = MARGIN_X;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			if global_position.x + size.x >= screen.x:
				global_position.x = screen.x - size.x - margin;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			cur_relative_pos = Positions.BELOW;
		
		Positions.LEFT:
			global_position.x = rect.position.x - rect.size.x - size.x - margin;
			global_position.y = ((rect.position.y + rect.end.y) / 2.0) - (size.y / 2.0);
			await get_tree().process_frame;
			
			if global_position.x <= 0.0:
				global_position.x = MARGIN_X;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			if global_position.y <= 0.0:
				global_position.y = MARGIN_Y;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			if global_position.y + size.y >= screen.y:
				global_position.y = screen.y - size.y - margin;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			cur_relative_pos = Positions.LEFT;
		
		Positions.RIGHT:
			global_position.x = requester_rect.end.x + requester_rect.end.x / 1.7 + margin;
			global_position.y = ((rect.position.y + rect.end.y) / 2.0) - (size.y / 2.0);
			await get_tree().process_frame;
			
			if global_position.x + size.x >= screen.x:
				global_position.x = screen.x - size.x - MARGIN_X;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			if global_position.y <= 0.0:
				global_position.y = MARGIN_Y;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			if global_position.y + size.y >= screen.y:
				global_position.y = screen.y - size.y - margin;
				await get_tree().process_frame;
				
				if collide_requester() && !force: return false;
			
			cur_relative_pos = Positions.RIGHT;
		
		_: return false;
	
	return true;


func collide_requester() -> bool:
	return requester_rect.intersects(get_global_rect(), true);


func _ready() -> void:
	_load_data();
	_load_settings();
	
	# Hides tooltip during positionnement and cahe previous alpha value.
	var prev_alpha: float = modulate.a;
	modulate.a = 0;
	
	var max_size := get_viewport_rect().end;
	var temp_txt: String = text;
	
	await get_tree().process_frame;
	
	match relative_position:
		Mobile.Tooltip.Positions.ABOVE:
			if !await set_position_to(Positions.ABOVE, requester_rect):
				if !await set_position_to(Positions.BELOW, requester_rect):
					if !await set_position_to(Positions.LEFT, requester_rect):
						if !await set_position_to(Positions.RIGHT, requester_rect):
							await set_position_to(Positions.ABOVE, requester_rect, true);
			
		Mobile.Tooltip.Positions.BELOW:
			if !await set_position_to(Positions.BELOW, requester_rect):
				if !await set_position_to(Positions.ABOVE, requester_rect):
					if !await set_position_to(Positions.LEFT, requester_rect):
						if !await set_position_to(Positions.RIGHT, requester_rect):
							await set_position_to(Positions.BELOW, requester_rect, true);
			
		Mobile.Tooltip.Positions.LEFT:
			if !await set_position_to(Positions.LEFT, requester_rect):
				if !await set_position_to(Positions.RIGHT, requester_rect):
					if !await set_position_to(Positions.ABOVE, requester_rect):
						if !await set_position_to(Positions.BELOW, requester_rect):
							await set_position_to(Positions.LEFT, requester_rect, true);
		
		Mobile.Tooltip.Positions.RIGHT:
			if !await set_position_to(Positions.RIGHT, requester_rect):
				if !await set_position_to(Positions.LEFT, requester_rect):
					if !await set_position_to(Positions.ABOVE, requester_rect):
						if !await set_position_to(Positions.BELOW, requester_rect):
							await set_position_to(Positions.RIGHT, requester_rect, true);
	
	# Place tooltip in front of all nodes
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX;
	# Shows Tooltip
	modulate.a = prev_alpha;
	_start_animation();


func _set_aligment(vertical: bool, value: String) -> void:
	match value:
		Mobile.Tooltip.TEXT_H_ALIGNMENTS.CENTER, Mobile.Tooltip.TEXT_V_ALIGNMENTS.CENTER:
			if vertical:
				vertical_alignment = VERTICAL_ALIGNMENT_CENTER;
			else:
				horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
		
		Mobile.Tooltip.TEXT_H_ALIGNMENTS.FILL, Mobile.Tooltip.TEXT_V_ALIGNMENTS.FILL:
			if vertical:
				vertical_alignment = VERTICAL_ALIGNMENT_FILL;
			else:
				horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL;
		
		Mobile.Tooltip.TEXT_H_ALIGNMENTS.RIGHT:
			horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT;
		
		Mobile.Tooltip.TEXT_H_ALIGNMENTS.LEFT:
			horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT;
		
		Mobile.Tooltip.TEXT_V_ALIGNMENTS.BOTTOM:
			vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM;
		
		Mobile.Tooltip.TEXT_V_ALIGNMENTS.TOP:
			vertical_alignment = VERTICAL_ALIGNMENT_TOP;


func _set_setting(setting: String, value: Variant) -> void:
	match setting:
		Mobile.Tooltip.ProjSettings.Paths.TEXT_HORIZONTAL_ALIGNMENT:
			_set_aligment(false, value);
		
		Mobile.Tooltip.ProjSettings.Paths.TEXT_VERTICAL_ALIGNMENT:
			_set_aligment(false, value);
		
		Mobile.Tooltip.ProjSettings.Paths.FONT:
			label_settings = value;
		
		Mobile.Tooltip.ProjSettings.Paths.BACKGROUND:
			set("theme_override_styles/normal", value);
			
			%requester_indicator.set(
				"theme_override_styles/panel/bg_color",
				get("theme_override_styles/normal/bg_color")
			);
		
		Mobile.Tooltip.ProjSettings.Paths.ENTER_ANIMATION: enter_anim = value;
		
		Mobile.Tooltip.ProjSettings.Paths.EXIT_ANIMATION: exit_anim = value;
		
		Mobile.Tooltip.ProjSettings.Paths.REQUESTER_INDICATOR_ANIMATION:
			requester_indicator_anim = value;
		
		Mobile.Tooltip.ProjSettings.Paths.DISPLAY_REQUESTER_INDICATOR:
			display_requester_indicator = value;
		
		Mobile.Tooltip.ProjSettings.Paths.DEFAULT_POSITION:
			relative_position = value;
		
		Mobile.Tooltip.ProjSettings.Paths.MARGIN: margin = value;
		
		Mobile.Tooltip.ProjSettings.Paths.INDICATOR_MARGIN: indicator_margin = value;
		
		Mobile.Tooltip.ProjSettings.Paths.ENTER_SOUND: enter_sound = value;
		
		Mobile.Tooltip.ProjSettings.Paths.EXIT_SOUND: exit_sound = value;
		
		Mobile.Tooltip.ProjSettings.Paths.AUDIO_BUS: audio_bus = value;
		
		Mobile.Tooltip.ProjSettings.Paths.DELAY_BEFORE_EXIT_SEC:
			delay_before_exit = value;
		
		Mobile.Tooltip.ProjSettings.Paths.CUSTOM_ENTER_ANIMATION:
			custom_enter_anim = value;
		
		Mobile.Tooltip.ProjSettings.Paths.CUSTOM_EXIT_ANIMATION:
			custom_exit_anim = value;


func _load_settings() -> void:
	var settings_overrides: Dictionary = _data["settings_overrides"];
	
	for setting in SETTINGS:
		if settings_overrides.has(setting):
			var value = settings_overrides[setting];
			_set_setting(setting, value);
		
		else:
			var property: String = setting.get_slice("/", setting.get_slice_count("/") - 1);
			var key: String = property.to_upper();
			
			_set_setting(
				setting, ProjectSettings.get_setting(
					setting,
					Mobile.Tooltip.ProjSettings.DefaultValues[key]
				)
			);


func _restart_tween() -> void:
	if _tween == null or not _tween.is_valid(): return;
	
	_tween.stop();
	_tween.kill();


func _start_animation() -> void:
#	_place_requester_indicator();
	if custom_enter_anim != "":
		var anim: Object = load(custom_enter_anim).new();
		get_tree().current_scene.add_child(anim);
		
		if anim.has_method(Mobile.CUSTOM_ANIMATION_FUNC):
			anim.animate(self);
			await anim.animation_finished;
			_place_requester_indicator();
			return;
	
	_play_sound(enter_sound);
	
	if enter_anim == Mobile.Tooltip.Anims.NONE:
		_place_requester_indicator();
		return;
	
	match enter_anim:
		Mobile.Tooltip.Anims.FADE:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: _place_requester_indicator());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeIn.fromAlpha;
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeIn.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeIn.duration
			);
		
		Mobile.Tooltip.Anims.FADE_DOWN:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: _place_requester_indicator());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeDownIn.fromAlpha;
			_tween.set_parallel(true);
			
			var next_pos: float = global_position.y;
			var diff: float = global_position.y - requester_rect.position.y;
			var begin_pos: float;
			
			if diff > 0:
				begin_pos = global_position.y - (size.y / 1.7);
			
			elif diff < 0:
				begin_pos = global_position.y - (size.y / 1.7);
			
			_tween.tween_property(
				self, "global_position:y",
				next_pos,
				Mobile.Tooltip.AnimsSettings.FadeDownIn.duration
			).set_ease(Tween.EASE_OUT_IN).from(begin_pos);
			
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeDownIn.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeDownIn.fadeDuration
			).set_ease(Tween.EASE_IN_OUT).set_delay(Mobile.Tooltip.AnimsSettings.FadeDownIn.fadeDelay);
		
		Mobile.Tooltip.Anims.FADE_UP:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: _place_requester_indicator());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeUpIn.fromAlpha;
			_tween.set_parallel(true);
			
			var next_pos: float = global_position.y;
			var diff: float = global_position.y - requester_rect.position.y;
			var begin_pos: float;
			
			if diff > 0:
				begin_pos = global_position.y - (size.y / 1.7);
			
			elif diff < 0:
				begin_pos = global_position.y + (size.y / 1.7);
			
			_tween.tween_property(
				self, "global_position:y",
				next_pos,
				Mobile.Tooltip.AnimsSettings.FadeUpIn.duration
			).set_ease(Tween.EASE_OUT_IN).from(begin_pos);
			
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeUpIn.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeUpIn.fadeDuration
			).set_ease(Tween.EASE_IN_OUT).set_delay(Mobile.Tooltip.AnimsSettings.FadeUpIn.fadeDelay);
		
		Mobile.Tooltip.Anims.FADE_RIGHT:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: _place_requester_indicator());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeRightIn.fromAlpha;
			
			var prev_pos: float = global_position.x;
			var begin_pos: float = global_position.x - size.x;
			
			_tween.set_parallel();
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeRightIn.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeRightIn.duration
			).set_delay(Mobile.Tooltip.AnimsSettings.FadeRightIn.fadeDelay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT);
			_tween.tween_property(
				self, "global_position:x",
				prev_pos,
				Mobile.Tooltip.AnimsSettings.FadeRightIn.duration
			).from(begin_pos);
		
		Mobile.Tooltip.Anims.FADE_LEFT:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: _place_requester_indicator());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeLeftIn.fromAlpha;
			
			var next_pos: float = global_position.x;
			var begin_pos: float = global_position.x + size.x;
			
			_tween.set_parallel();
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeLeftIn.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeLeftIn.duration
			).set_delay(Mobile.Tooltip.AnimsSettings.FadeLeftIn.fadeDelay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT);
			_tween.tween_property(
				self, "global_position:x",
				next_pos,
				Mobile.Tooltip.AnimsSettings.FadeLeftIn.duration
			).from(begin_pos);
		
		Mobile.Tooltip.Anims.BOUNCE:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.Bounce.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("BOUNCE");
			await %anim.animation_finished;
			_place_requester_indicator();
		
		Mobile.Tooltip.Anims.SCALE:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.Scale.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("SCALE");
			await %anim.animation_finished;
			_place_requester_indicator();
		
		Mobile.Tooltip.Anims.SCALE_X:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.ScaleX.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("SCALE_X");
			await %anim.animation_finished;
			_place_requester_indicator();
		
		Mobile.Tooltip.Anims.SCALE_Y:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.ScaleY.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("SCALE_Y");
			await %anim.animation_finished;
			_place_requester_indicator();
		
		Mobile.Tooltip.Anims.POP:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.Pop.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play("POP");
			await %anim.animation_finished;
			_place_requester_indicator();


func _start_requester_indicator_animation() -> void:
	if requester_indicator_anim == Mobile.Tooltip.RequesterIndicatorAnims.NONE: return;
	
	match requester_indicator_anim:
		Mobile.Tooltip.RequesterIndicatorAnims.FADE:
			var tween: Tween = create_tween();
			%requester_indicator.modulate.a = Mobile.Tooltip.AnimsSettings.FadeIn.fromAlpha;
			tween.tween_property(
				%requester_indicator, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeIn.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeIn.duration
			);
		
		Mobile.Tooltip.RequesterIndicatorAnims.BOUNCE: %anim.play("INDICATOR_BOUNCE");
		
		Mobile.Tooltip.RequesterIndicatorAnims.SCALE: %anim.play("INDICATOR_SCALE");
	
		Mobile.Tooltip.RequesterIndicatorAnims.POP: %anim.play("INDICATOR_POP");


func delete(just_after_display := false) -> void:
	if just_after_display:
		await get_tree().create_timer(delay_before_exit).timeout;
		delay_before_exit_ended.emit();
	
	if custom_enter_anim != "":
		var anim: Object = load(custom_exit_anim).new();
		get_tree().current_scene.add_child(anim);
		
		if anim.has_method(Mobile.CUSTOM_ANIMATION_FUNC):
			anim.animate(self);
			anim.animation_finished.connect(func () -> void: queue_free());
			return;
	
	_play_sound(exit_sound);
	
	if exit_anim == Mobile.Tooltip.Anims.NONE: queue_free();
	
	match exit_anim:
		Mobile.Tooltip.Anims.FADE:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: queue_free());
		
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeOut.fromAlpha;
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeOut.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeOut.duration
			);
		
		Mobile.Tooltip.Anims.BOUNCE:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.Bounce.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("BOUNCE");
			await %anim.animation_finished;
			queue_free();
		
		Mobile.Tooltip.Anims.FADE_UP:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: queue_free());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeUpOut.fromAlpha;
			_tween.set_parallel(true);
			
			var next_pos: float = global_position.y;
			var diff: float = global_position.y - requester_rect.position.y;
			
			if diff > 0:
				next_pos = global_position.y + (size.y / 1.7);
			
			elif diff < 0:
				next_pos = global_position.y - (size.y / 1.7);
			
			_tween.tween_property(
				self, "global_position:y",
				next_pos,
				Mobile.Tooltip.AnimsSettings.FadeUpOut.duration
			).set_ease(Tween.EASE_OUT_IN);
			
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeUpOut.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeUpOut.fadeDuration
			).set_ease(Tween.EASE_IN_OUT).set_delay(Mobile.Tooltip.AnimsSettings.FadeUpOut.fadeDelay);
		
		Mobile.Tooltip.Anims.FADE_DOWN:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: queue_free());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeDownOut.fromAlpha;
			_tween.set_parallel(true);
			
			var next_pos: float;
			var diff: float = global_position.y - requester_rect.position.y;
			
			if diff > 0:
				next_pos = global_position.y - (size.y / 1.7);
			
			elif diff < 0:
				next_pos = global_position.y + (size.y / 1.7);
			
			_tween.tween_property(
				self, "global_position:y",
				next_pos,
				Mobile.Tooltip.AnimsSettings.FadeDownOut.duration
			).set_ease(Tween.EASE_OUT_IN);
			
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeDownOut.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeDownOut.fadeDuration
			).set_ease(Tween.EASE_IN_OUT).set_delay(Mobile.Tooltip.AnimsSettings.FadeDownOut.fadeDelay);
		
		Mobile.Tooltip.Anims.FADE_RIGHT:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: queue_free());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeRightOut.fromAlpha;
			
			var next_pos: float = global_position.x + global_position.x + size.x;
			
			_tween.set_parallel();
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeRightOut.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeRightOut.duration
			).set_delay(Mobile.Tooltip.AnimsSettings.FadeRightOut.fadeDelay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT);
			_tween.tween_property(
				self, "global_position:x",
				next_pos,
				Mobile.Tooltip.AnimsSettings.FadeRightOut.duration
			);
		
		Mobile.Tooltip.Anims.FADE_LEFT:
			_restart_tween();
			_tween = create_tween();
			_tween.finished.connect(func () -> void: queue_free());
			modulate.a = Mobile.Tooltip.AnimsSettings.FadeLeftOut.fromAlpha;
			
			var next_pos: float = global_position.x - global_position.x - size.x;
			
			_tween.set_parallel();
			_tween.tween_property(
				self, "modulate:a",
				Mobile.Tooltip.AnimsSettings.FadeLeftOut.toAlpha,
				Mobile.Tooltip.AnimsSettings.FadeLeftOut.duration
			).set_delay(Mobile.Tooltip.AnimsSettings.FadeLeftOut.fadeDelay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT);
			_tween.tween_property(
				self, "global_position:x",
				next_pos,
				Mobile.Tooltip.AnimsSettings.FadeLeftOut.duration
			);
		
		Mobile.Tooltip.Anims.SCALE:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.Scale.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("SCALE");
			await %anim.animation_finished;
			queue_free();
		
		Mobile.Tooltip.Anims.SCALE_X:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.ScaleX.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("SCALE_X");
			await %anim.animation_finished;
			queue_free();
		
		Mobile.Tooltip.Anims.SCALE_Y:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.ScaleY.pivot;
			pivot_offset = size * pivot / 100;
			%anim.play_backwards("SCALE_Y");
			await %anim.animation_finished;
			queue_free();
		
		Mobile.Tooltip.Anims.POP:
			var pivot: Vector2 = Mobile.Tooltip.AnimsSettings.Pop.pivot;
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
