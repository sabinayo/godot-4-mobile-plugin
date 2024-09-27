class_name Mobile;

extends Node;

signal help_bar_state_changed(displayed: bool);

## The name of the node which appear on the scene dock when user select a node
## handled by the mobile plugin.
const SIGNALS_MANAGER := "mobile_plugin_signals_manager";
const SIGNALS_MANAGER_META := "signals_manager_path";
const CUSTOM_ANIMATION_FUNC := "animate";

## The global path of the node which request help bar display.
var help_bar_requester := "";

## The class of the node which request help bar display.
var help_bar_requester_class := "";

## The global path of the help bar scene currently displayed.
var help_bar_path := "";

## Indicates if help bar is requested by a node.
var help_bar_requested := false;

# Used to check previous instance of help bar scene in the current SceneTree
var _help_bar_name := "godot-mobile-plugin-helpbar-scene";

@onready var _help_bar: PackedScene = load(
	ProjectSettings.get_setting(
		Mobile.HelpBar.ProjSettings.Paths.SCENE,
		Mobile.HelpBar.ProjSettings.DefaultValues.SCENE,
));


## The [param data] must contains information those keys are part of the value of
## [code]Mobile.HelpBar.MetaProperties[/code] except [code]Mobile.HelpBar.MetaProperties.ENABLED[/code].[br]
## See below:
## [codeblock]
## func _on_line_edit_mouse_entered() -> void:
##     var data := {
##         Mobile.HelpBar.MetaProperties.KEYBOARD: Mobile.HelpBar.VirtualKeyboardType.KEYBOARD_TYPE_DEFAULT,
##         Mobile.HelpBar.MetaProperties.TIP: "Enter your name:",
##         Mobile.HelpBar.MetaProperties.ANCHOR: Mobile.HelpBar.Anchors.FULL_RECT,
##         Mobile.HelpBar.REQUESTER_PROPERTY: "global/path/to/the/help/bar/requester",
##     };
##     var mobile = Mobile.new();
##     add_child(mobile);
##     mobile.display_help_bar(data);
## [/codeblock]
## See [code]Mobile.HelpBar.VirtualKeyboardType[/code] and [code]Mobile.HelpBar.Anchors[/code]
func display_help_bar(data: Dictionary) -> void:
	if !DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return;
	
	# Hide virtual keyboard if displayed
	if DisplayServer.virtual_keyboard_get_height() != 0:
		DisplayServer.virtual_keyboard_hide();
	
	var cur_scene = get_tree().current_scene;
	
	if cur_scene.has_node(_help_bar_name):
		help_bar_requested = false;
		cur_scene.get_node(_help_bar_name).queue_free();
		help_bar_requester = "";
	
	var text;
	var keyboard: int = data[HelpBar.MetaProperties.KEYBOARD];
	var tip: String = data[HelpBar.MetaProperties.TIP];
	var anchor = data[HelpBar.MetaProperties.ANCHOR];
	anchor = HelpBar.Anchors.values()[anchor];
	help_bar_requester = data[HelpBar.REQUESTER_PROPERTY];
	
	help_bar_requested = true;
	var node = cur_scene.get_node(help_bar_requester);
	help_bar_requester_class = node.get_class();
	
	match help_bar_requester_class:
		"SpinBox":
			text = node.value;
		
		"LineEdit":
			text = node.text;
	
	DisplayServer.virtual_keyboard_show(str(text), Rect2(0, 0, 0, 0), keyboard);
	await get_tree().process_frame;
	
	var kbd_size_y: int = DisplayServer.virtual_keyboard_get_height();
	
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect();
	var screen: Vector2 = get_viewport().get_visible_rect().end;
	
	# If device has floating keyboard
	if kbd_size_y == 0:
		kbd_size_y = screen.y * 1/2;
	
	var helper = _help_bar.instantiate();
	var can_display_helper := true;
	
	for _signal in HelpBar.MANDATORY_SIGNALS:
		if not helper.has_signal(_signal):
			push_error("Attempt to display help bar with a custom scene which hasn't\
				 the required signal \"%s\". Use the default scene or add the signal \"%s\" \
				to your custom scene." % [_signal, _signal]
			);
			can_display_helper = false;
	
	for method in HelpBar.MANDATORY_METHODS:
		if not helper.has_method(method):
			push_error("Attempt to display help bar with a custom scene which hasn't\
				 the required function \"%s\". Use the default scene or add the function \"%s\" \
				to your custom scene." % [method, method]
			);
			can_display_helper = false;
	
	if not can_display_helper:
		push_error("INVALID CUSTOM SCENE, switching to default...");
		_help_bar = load(HelpBar.ProjSettings.DefaultValues.SCENE);
		helper = _help_bar.instantiate();
	
	helper.set_settings_overrides(data["settings_overrides"]);
	cur_scene.add_child(helper);
	helper.set_edition(keyboard, tip, str(text));
	help_bar_path = helper.get_path();
	helper.position = usable_rect.position;
	helper.text_changed.connect(_on_help_bar_text_changed);
	helper.text_submitted.connect(_on_help_bar_text_submitted);
	
	var _screen_center: Vector2 = screen / 2.0;
	
	match anchor:
		HelpBar.Anchors.FULL_RECT:
			helper.size = Vector2(screen.x, screen.y - kbd_size_y);
			helper.position = Vector2(
				_screen_center.x - helper.size.x / 2.0,
				0.0
			);
		
		HelpBar.Anchors.CENTER_WIDE:
			helper.size = Vector2(screen.x, (screen.y - kbd_size_y) / 2.0);
			helper.position = Vector2(
				_screen_center.x - helper.size.x / 2.0,
				helper.size.y / 2.0,
			);
		
		HelpBar.Anchors.BOTTOM_WIDE:
			helper.size = Vector2(screen.x, (screen.y - kbd_size_y) / 2.0);
			helper.position = Vector2(
				_screen_center.x - helper.size.x / 2.0,
				helper.size.y,
			);
		
		HelpBar.Anchors.TOP_WIDE:
			helper.size = Vector2(screen.x, (screen.y - kbd_size_y) / 2.0);
			helper.position = Vector2(
				_screen_center.x - helper.size.x / 2.0,
				0,
			);
	
	helper.deletion_requested.connect(_delete_help_bar);
	help_bar_state_changed.emit(true);


func _on_help_bar_text_changed(text: Variant) -> void:
	match help_bar_requester_class:
		"SpinBox":
			get_node(help_bar_requester).value = int(text);
		
		"LineEdit":
			get_node(help_bar_requester).text = str(text);


func _on_help_bar_text_submitted(text: String) -> void:
	match help_bar_requester_class:
		"LineEdit":
			get_node(help_bar_requester).text_submitted.emit(text);
	
	_delete_help_bar();


func _delete_help_bar() -> void:
	get_node(help_bar_path).delete();
	help_bar_state_changed.emit(false);
	help_bar_requested = false;
	help_bar_path = "";
	help_bar_requester = "";
	queue_free();


## Provides information indented to be used by the user or plugin scripts.
class HelpBar:
	enum  VirtualKeyboardType {
		## Default text virtual keyboard.
		KEYBOARD_TYPE_DEFAULT = 0,
		## Multiline virtual keyboard.
		KEYBOARD_TYPE_MULTILINE = 1,
		## Virtual number keypad, useful for PIN entry.
		KEYBOARD_TYPE_NUMBER = 2,
		## Virtual number keypad, useful for entering fractional numbers.
		KEYBOARD_TYPE_NUMBER_DECIMAL = 3,
		## Virtual phone number keypad.
		KEYBOARD_TYPE_PHONE = 4,
		## Virtual keyboard with additional keys to assist with typing email addresses.
		KEYBOARD_TYPE_EMAIL_ADDRESS = 5,
		## Virtual keyboard for entering a password. On most platforms, this should disable autocomplete and autocapitalization.
		## Note: This is not supported on Web. Instead, this behaves identically to KEYBOARD_TYPE_DEFAULT.
		KEYBOARD_TYPE_PASSWORD = 6,
		## Virtual keyboard with additional keys to assist with typing URLs.
		KEYBOARD_TYPE_URL = 7,
	};
	const Anchors := {
		FULL_RECT = "Full Rect",
		CENTER_WIDE = "Center wide",
		BOTTOM_WIDE = "Bottom wide",
		TOP_WIDE = "Top wide",
	};
	const ANCHORS_HINT := "Top wide,Center wide,Bottom wide,Full Rect";
	const Anims := {
		NONE = "None",
		BOUNCE = "Bounce",
		FADE = "Fade",
		FADE_DOWN = "Fade Down",
		FADE_LEFT = "Fade Left",
		FADE_RIGHT = "Fade Right",
		FADE_UP = "Fade Up",
		POP = "Pop",
		SCALE = "Scale",
		SCALE_X = "Scale X",
		SCALE_Y = "Scale Y",
	};
	const REQUESTER_PROPERTY := "requester";
	const MANDATORY_METHODS := [
		"set_edition",
	];
	const MANDATORY_SIGNALS := [
		"text_submitted", "text_changed", "deletion_requested",
	];
	const ENTER_ANIMS_HINT := "None,Bounce,Fade,Fade Down,Fade Left,Fade Right,Fade Up,Pop,Scale,Scale X,Scale Y";
	const EXIT_ANIMS_HINT := "None,Bounce,Fade,Fade Down,Fade Left,Fade Right,Fade Up,Pop,Scale,Scale X,Scale Y";
	const MetaProperties := {
		TIP = "mobile_help_bar_tip",
		ANCHOR = "mobile_help_bar_anchor",
		KEYBOARD = "mobile_help_bar_keyboard",
		ENABLED = "mobile_help_bar_enabled",
	};
	
	const FAST_SETTINGS := [
		ProjSettings.Paths.SCENE,
		ProjSettings.Paths.HIDE_ON_EXTERNAL_EVENTS,
		ProjSettings.Paths.BACKGROUND,
		ProjSettings.Paths.FONT,
		ProjSettings.Paths.ENTER_ANIMATION,
		ProjSettings.Paths.CUSTOM_ENTER_ANIMATION,
		ProjSettings.Paths.EXIT_ANIMATION,
		ProjSettings.Paths.CUSTOM_EXIT_ANIMATION,
		ProjSettings.Paths.TIP_BACKGROUND,
		ProjSettings.Paths.TIP_FONT,
		ProjSettings.Paths.LINE_EDIT_NORMAL_BACKGROUND,
		ProjSettings.Paths.LINE_EDIT_FOCUS_BACKGROUND,
		ProjSettings.Paths.LINE_EDIT_FONT_SIZE,
	];
	
	class AnimsSettings:
		const FadeIn := {
			duration = 0.5,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
		};
		
		const FadeOut := {
			duration = 0.5,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
		};
		
		const FadeUpIn := {
			duration = 0.7,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
			fadeDuration = 0.5,
			fadeDelay = 0.1,
		};
		
		const FadeUpOut := {
			duration = 0.7,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
			fadeDuration = 0.5,
			fadeDelay = 0.1,
		};
		
		const FadeLeftIn := {
			duration = 0.5,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
			fadeDuration = 0.5,
			fadeDelay = 0.2,
		};
		
		const FadeLeftOut := {
			duration = 0.5,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
			fadeDuration = 0.5,
			fadeDelay = 0.2,
		};
		
		const FadeRightIn := {
			duration = 0.5,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
			fadeDuration = 0.5,
			fadeDelay = 0.2,
		};
		
		const FadeRightOut := {
			duration = 0.5,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
			fadeDuration = 0.5,
			fadeDelay = 0.2,
		};
		
		const FadeDownIn := {
			duration = 0.7,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
			fadeDuration = 0.5,
			fadeDelay = 0.1,
		};
		
		const FadeDownOut := {
			duration = 0.7,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
			fadeDuration = 0.5,
			fadeDelay = 0.1,
		};
		
		const Pop := {
			pivot = Vector2(50.0, 50.0),# percentages
		};
		
		const Bounce := {
			pivot = Vector2(50.0, 50.0),# percentages
		};
		
		const Scale := {
			pivot = Vector2(50.0, 50.0),# percentages
		};
		
		const ScaleX := {
			pivot = Vector2(50.0, 100.0),# percentages
		};
		
		const ScaleY := {
			pivot = Vector2(100.0, 50.0),# percentages
		};
	
	class ProjSettings:
		const SAVE_PATH := "mobile/help_bar/";
		const CONFIG_PATH := "%sconfiguration/" % SAVE_PATH;
		const DISPLAY_PATH := "%sdisplay/" % SAVE_PATH;
		const TIP_PATH := "%stip/" % SAVE_PATH;
		const LINE_EDIT_PATH := "%sline_edit/" % SAVE_PATH;
		
		const Paths := {
			SCENE = "%sscene" % CONFIG_PATH,
			HIDE_ON_EXTERNAL_EVENTS = "%shide_on_external_events" % CONFIG_PATH,
			ENTER_SOUND = "%senter_sound" % CONFIG_PATH,
			EXIT_SOUND = "%sexit_sound" % CONFIG_PATH,
			AUDIO_BUS = "%saudio_bus" % CONFIG_PATH,
			ANCHOR = "%sanchor" % DISPLAY_PATH,
			BACKGROUND = "%sbackground" % DISPLAY_PATH,
			FONT = "%sfont" % DISPLAY_PATH,
			ENTER_ANIMATION = "%senter_animation" % DISPLAY_PATH,
			CUSTOM_ENTER_ANIMATION = "%scustom_enter_animation" % DISPLAY_PATH,
			EXIT_ANIMATION = "%sexit_animation" % DISPLAY_PATH,
			CUSTOM_EXIT_ANIMATION = "%scustom_exit_animation" % DISPLAY_PATH,
			TIP_BACKGROUND = "%stip_background" % TIP_PATH,
			TIP_FONT = "%stip_font" % TIP_PATH,
			LINE_EDIT_NORMAL_BACKGROUND = "%snormal_background" % LINE_EDIT_PATH,
			LINE_EDIT_FOCUS_BACKGROUND = "%sfocus_background" % LINE_EDIT_PATH,
			LINE_EDIT_FONT_SIZE = "%sfont_size" % LINE_EDIT_PATH,
		};
		
		const DefaultValues := {
			SCENE = "res://addons/mobile/help_bar/help_bar.tscn",
			HIDE_ON_EXTERNAL_EVENTS = false,
			ENTER_SOUND = "",
			EXIT_SOUND = "",
			AUDIO_BUS = "Master",
			ANCHOR = Anchors.FULL_RECT,
			BACKGROUND = preload("themes/help_bar_background.tres"),
			FONT = preload("themes/help_bar_font.tres"),
			ENTER_ANIMATION = "Fade",
			CUSTOM_ENTER_ANIMATION = "",
			EXIT_ANIMATION = "Fade",
			CUSTOM_EXIT_ANIMATION = "",
			TIP_FONT = "",
			TIP_BACKGROUND = preload("themes/help_bar_tip_background.tres"),
			LINE_EDIT_NORMAL_BACKGROUND = preload("themes/help_bar_line_edit_normal_bg.tres"),
			LINE_EDIT_FOCUS_BACKGROUND = preload("themes/help_bar_line_edit_focus_bg.tres"),
			LINE_EDIT_FONT_SIZE = 40,
		};
		
		const CONFIG: Array[Dictionary] = [
			{
				"path": Paths.SCENE,
				"default_value": DefaultValues.SCENE,
				"value": DefaultValues.SCENE,
				"infos": {
					"name": Paths.SCENE,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.tscn",
				},
			},
			{
				"path": Paths.HIDE_ON_EXTERNAL_EVENTS,
				"default_value": DefaultValues.HIDE_ON_EXTERNAL_EVENTS,
				"value": DefaultValues.HIDE_ON_EXTERNAL_EVENTS,
				"infos": {
					"name": Paths.HIDE_ON_EXTERNAL_EVENTS,
					"type": TYPE_BOOL,
				},
			},
			{
				"path": Paths.ENTER_SOUND,
				"default_value": DefaultValues.ENTER_SOUND,
				"value": DefaultValues.ENTER_SOUND,
				"infos": {
					"name": Paths.ENTER_SOUND,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.wav,*.mp3,*.ogg",
				},
			},
			{
				"path": Paths.EXIT_SOUND,
				"default_value": DefaultValues.EXIT_SOUND,
				"value": DefaultValues.EXIT_SOUND,
				"infos": {
					"name": Paths.EXIT_SOUND,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.wav,*.mp3,*.ogg",
				},
			},
			{
				"path": Paths.AUDIO_BUS,
				"default_value": DefaultValues.AUDIO_BUS,
				"value": DefaultValues.AUDIO_BUS,
				"infos": {
					"name": Paths.AUDIO_BUS,
					"type": TYPE_STRING,
				},
			},
			
			{
				"path": Paths.ANCHOR,
				"default_value": DefaultValues.ANCHOR,
				"value": DefaultValues.ANCHOR,
				"infos": {
					"name": Paths.ANCHOR,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": ANCHORS_HINT,
				},
			},
			{
				"path": Paths.BACKGROUND,
				"default_value": DefaultValues.BACKGROUND,
				"value": DefaultValues.BACKGROUND,
				"infos": {
					"name": Paths.BACKGROUND,
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "StyleBox",
				},
			},
			{
				"path": Paths.FONT,
				"default_value": DefaultValues.FONT,
				"value": DefaultValues.FONT,
				"infos": {
					"name": Paths.FONT,
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "LabelSettings",
				},
			},
			{
				"path": Paths.ENTER_ANIMATION,
				"default_value": DefaultValues.ENTER_ANIMATION,
				"value": DefaultValues.ENTER_ANIMATION,
				"infos": {
					"name": Paths.ENTER_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": ENTER_ANIMS_HINT,
				},
			},
			{
				"path": Paths.CUSTOM_ENTER_ANIMATION,
				"default_value": DefaultValues.CUSTOM_ENTER_ANIMATION,
				"value": DefaultValues.CUSTOM_ENTER_ANIMATION,
				"infos": {
					"name": Paths.CUSTOM_ENTER_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.gd,*.txt",
				},
			},
			{
				"path": Paths.EXIT_ANIMATION,
				"default_value": DefaultValues.EXIT_ANIMATION,
				"value": DefaultValues.EXIT_ANIMATION,
				"infos": {
					"name": Paths.EXIT_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": EXIT_ANIMS_HINT,
				},
			},
			{
				"path": Paths.CUSTOM_EXIT_ANIMATION,
				"default_value": DefaultValues.CUSTOM_EXIT_ANIMATION,
				"value": DefaultValues.CUSTOM_EXIT_ANIMATION,
				"infos": {
					"name": Paths.CUSTOM_EXIT_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.gd,*.txt",
				},
			},
			{
				"path": Paths.TIP_BACKGROUND,
				"default_value": DefaultValues.TIP_BACKGROUND,
				"value": DefaultValues.TIP_BACKGROUND,
				"infos": {
					"name": Paths.TIP_BACKGROUND,
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "StyleBox",
				},
			},
			{
				"path": Paths.TIP_FONT,
				"default_value": DefaultValues.TIP_FONT,
				"value": DefaultValues.TIP_FONT,
				"infos": {
					"name": Paths.TIP_FONT,
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "LabelSettings",
				},
			},
			{
				"path": Paths.LINE_EDIT_NORMAL_BACKGROUND,
				"default_value": DefaultValues.LINE_EDIT_NORMAL_BACKGROUND,
				"value": DefaultValues.LINE_EDIT_NORMAL_BACKGROUND,
				"infos": {
					"name": Paths.LINE_EDIT_NORMAL_BACKGROUND,
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "StyleBox",
				},
			},
			{
				"path": Paths.LINE_EDIT_FOCUS_BACKGROUND,
				"default_value": DefaultValues.LINE_EDIT_FOCUS_BACKGROUND,
				"value": DefaultValues.LINE_EDIT_FOCUS_BACKGROUND,
				"infos": {
					"name": Paths.LINE_EDIT_FOCUS_BACKGROUND,
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "StyleBox",
				},
			},
			{
				"path": Paths.LINE_EDIT_FONT_SIZE,
				"default_value": DefaultValues.LINE_EDIT_FONT_SIZE,
				"value": DefaultValues.LINE_EDIT_FONT_SIZE,
				"infos": {
					"name": Paths.LINE_EDIT_FONT_SIZE,
					"type": TYPE_INT,
				},
			},
		];


class Tooltip:
	const Anims := {
		NONE = "None",
		BOUNCE = "Bounce",
		FADE = "Fade",
		FADE_DOWN = "Fade Down",
		FADE_LEFT = "Fade Left",
		FADE_RIGHT = "Fade Right",
		FADE_UP = "Fade Up",
		POP = "Pop",
		SCALE = "Scale",
		SCALE_X = "Scale X",
		SCALE_Y = "Scale Y",
	};
	const Positions := {
		ABOVE = "Above",
		BELOW = "Below",
		LEFT = "Left",
		RIGHT = "Right",
	};
	const RequesterIndicatorAnims := {
		NONE = "None",
		BOUNCE = "Bounce",
		FADE = "Fade",
		POP = "Pop",
		SCALE = "Scale",
	};
	const MetaProperties := {
		DISPLAY = "tooltip_on_mobile",
	};
	const TEXT_H_ALIGNMENTS := {
		LEFT = "Left",
		CENTER = "Center",
		RIGHT = "Right",
		FILL = "Fill",
	};
	const TEXT_V_ALIGNMENTS := {
		TOP = "Top",
		CENTER = "Center",
		BOTTOM = "Bottom",
		FILL = "Fill",
	};
	const REQUESTER_PROPERTY := "requester";
	const REQUESTER_INDICATOR_ANIMS_HINT := "None,Bounce,Fade,Pop,Scale";
	const POSITIONS_HINT := "Above,Below,Left,Right";
	const ENTER_ANIMS_HINT := "None,Bounce,Fade,Fade Down,Fade Left,Fade Right,Fade Up,Pop,Scale,Scale X,Scale Y";
	const EXIT_ANIMS_HINT := "None,Bounce,Fade,Fade Down,Fade Left,Fade Right,Fade Up,Pop,Scale,Scale X,Scale Y";
	const TEXT_H_ALIGNMENTS_HINT := "Left,Center,Right,Fill";
	const TEXT_V_ALIGNMENTS_HINT := "Top,Center,Bottom,Fill";
	
	const FAST_SETTINGS := [
		ProjSettings.Paths.SCENE,
		ProjSettings.Paths.HIDE_AFTER_SEC,
		ProjSettings.Paths.HIDE_ON_SCREEN_DRAG,
		ProjSettings.Paths.HIDE_ON_NEXT_TOUCH_EVENT,
		ProjSettings.Paths.DISPLAY_ON_SINGLE_TOUCH,
		ProjSettings.Paths.MARGIN,
		ProjSettings.Paths.INDICATOR_MARGIN,
		ProjSettings.Paths.ENTER_SOUND,
		ProjSettings.Paths.EXIT_SOUND,
		ProjSettings.Paths.AUDIO_BUS,
		ProjSettings.Paths.DEFAULT_POSITION,
		ProjSettings.Paths.DISPLAY_REQUESTER_INDICATOR,
		ProjSettings.Paths.REQUESTER_INDICATOR_ANIMATION,
		ProjSettings.Paths.TEXT_HORIZONTAL_ALIGNMENT,
		ProjSettings.Paths.TEXT_VERTICAL_ALIGNMENT,
		ProjSettings.Paths.BACKGROUND,
		ProjSettings.Paths.FONT,
		ProjSettings.Paths.ENTER_ANIMATION,
		ProjSettings.Paths.CUSTOM_ENTER_ANIMATION,
		ProjSettings.Paths.EXIT_ANIMATION,
		ProjSettings.Paths.CUSTOM_EXIT_ANIMATION,
	];
	
	class AnimsSettings:
		const FadeIn := {
			duration = 0.5,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
		};
		
		const FadeOut := {
			duration = 0.5,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
		};
		
		const FadeUpIn := {
			duration = 0.7,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
			fadeDuration = 0.5,
			fadeDelay = 0.1,
		};
		
		const FadeUpOut := {
			duration = 0.7,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
			fadeDuration = 0.5,
			fadeDelay = 0.1,
		};
		
		const FadeLeftIn := {
			duration = 0.5,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
			fadeDuration = 0.5,
			fadeDelay = 0.2,
		};
		
		const FadeLeftOut := {
			duration = 0.5,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
			fadeDuration = 0.5,
			fadeDelay = 0.2,
		};
		
		const FadeRightIn := {
			duration = 0.5,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
			fadeDuration = 0.5,
			fadeDelay = 0.2,
		};
		
		const FadeRightOut := {
			duration = 0.5,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
			fadeDuration = 0.5,
			fadeDelay = 0.2,
		};
		
		const FadeDownIn := {
			duration = 0.7,# in seconds
			fromAlpha = 0.0,
			toAlpha = 1.0,
			fadeDuration = 0.5,
			fadeDelay = 0.1,
		};
		
		const FadeDownOut := {
			duration = 0.7,# in seconds
			fromAlpha = 1.0,
			toAlpha = 0.0,
			fadeDuration = 0.5,
			fadeDelay = 0.1,
		};
		
		const Pop := {
			pivot = Vector2(50.0, 50.0),# percentages
		};
		
		const Bounce := {
			pivot = Vector2(50.0, 50.0),# percentages
		};
		
		const Scale := {
			pivot = Vector2(50.0, 50.0),# percentages
		};
		
		const ScaleX := {
			pivot = Vector2(50.0, 100.0),# percentages
		};
		
		const ScaleY := {
			pivot = Vector2(100.0, 50.0),# percentages
		};
	
	class ProjSettings:
		const SAVE_PATH := "mobile/tooltip/";
		const CONFIG_PATH := "%sconfiguration/" % SAVE_PATH;
		const DISPLAY_PATH := "%sdisplay/" % SAVE_PATH;
		
		const Paths := {
			SCENE = "%sscene" % CONFIG_PATH,
			TOOLTIP_DELAY_SEC = "%stooltip_delay_sec" % CONFIG_PATH,
			HIDE_AFTER_SEC = "%shide_after_sec" % CONFIG_PATH,
			SAFE_DELETION_TIME_SEC = "%ssafe_deletion_time_sec" % CONFIG_PATH,
			DELAY_BEFORE_EXIT_SEC = "%sdelay_before_exit_sec" % CONFIG_PATH,
			HIDE_ON_SCREEN_DRAG = "%shide_on_screen_drag" % CONFIG_PATH,
			HIDE_ON_NEXT_TOUCH_EVENT = "%shide_on_next_touch_event" % CONFIG_PATH,
			DISPLAY_ON_SINGLE_TOUCH = "%sdisplay_on_single_touch" % CONFIG_PATH,
			MAX_TOOLTIP = "%smax_tooltip" % CONFIG_PATH,
			MARGIN = "%smargin" % CONFIG_PATH,
			INDICATOR_MARGIN = "%sindicator_margin" % CONFIG_PATH,
			ENTER_SOUND = "%senter_sound" % CONFIG_PATH,
			EXIT_SOUND = "%sexit_sound" % CONFIG_PATH,
			AUDIO_BUS = "%saudio_bus" % CONFIG_PATH,
			DEFAULT_POSITION = "%sdefault_position" % DISPLAY_PATH,
			DISPLAY_REQUESTER_INDICATOR = "%sdisplay_requester_indicator" % DISPLAY_PATH,
			REQUESTER_INDICATOR_ANIMATION = "%srequester_indicator_animation" % DISPLAY_PATH,
			TEXT_HORIZONTAL_ALIGNMENT = "%stext_horizontal_alignment" % DISPLAY_PATH,
			TEXT_VERTICAL_ALIGNMENT = "%stext_vertical_alignment" % DISPLAY_PATH,
			BACKGROUND = "%sbackground" % DISPLAY_PATH,
			FONT = "%sfont" % DISPLAY_PATH,
			ENTER_ANIMATION = "%senter_animation" % DISPLAY_PATH,
			CUSTOM_ENTER_ANIMATION = "%scustom_enter_animation" % DISPLAY_PATH,
			EXIT_ANIMATION = "%sexit_animation" % DISPLAY_PATH,
			CUSTOM_EXIT_ANIMATION = "%scustom_exit_animation" % DISPLAY_PATH,
		};
		
		const DefaultValues := {
			SCENE = "res://addons/mobile/tooltip/tooltip.tscn",
			TOOLTIP_DELAY_SEC = 0.5,
			HIDE_AFTER_SEC = -1,
			SAFE_DELETION_TIME_SEC = 0.5,
			DELAY_BEFORE_EXIT_SEC = 1.0,
			HIDE_ON_SCREEN_DRAG = false,
			HIDE_ON_NEXT_TOUCH_EVENT = true,
			DISPLAY_ON_SINGLE_TOUCH = false,
			MAX_TOOLTIP = 1,
			MARGIN = 10,
			INDICATOR_MARGIN = 0,
			ENTER_SOUND = "",
			EXIT_SOUND = "",
			AUDIO_BUS = "Master",
			DEFAULT_POSITION = Positions.ABOVE,
			DISPLAY_REQUESTER_INDICATOR = true,
			REQUESTER_INDICATOR_ANIMATION = "Fade",
			TEXT_HORIZONTAL_ALIGNMENT = TEXT_H_ALIGNMENTS.LEFT,
			TEXT_VERTICAL_ALIGNMENT = TEXT_V_ALIGNMENTS.TOP,
			BACKGROUND = preload("themes/tooltip_backgroud.tres"),
			FONT = preload("themes/tooltip_font.tres"),
			ENTER_ANIMATION = "Fade",
			CUSTOM_ENTER_ANIMATION = "",
			EXIT_ANIMATION = "Fade",
			CUSTOM_EXIT_ANIMATION = "",
		};
		
		const CONFIG: Array[Dictionary] = [
			{
				"path": Paths.SCENE,
				"default_value": DefaultValues.SCENE,
				"value": DefaultValues.SCENE,
				"infos": {
					"name": Paths.SCENE,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.tscn",
				},
			},
			{
				"path": Paths.TOOLTIP_DELAY_SEC,
				"default_value": DefaultValues.TOOLTIP_DELAY_SEC,
				"value": DefaultValues.TOOLTIP_DELAY_SEC,
				"infos": {
					"name": Paths.TOOLTIP_DELAY_SEC,
					"type": TYPE_FLOAT,
					"hint": PROPERTY_HINT_RANGE,
					"hint_string": "0,5,0.01",
				},
			},
			{
				"path": Paths.HIDE_AFTER_SEC,
				"default_value": DefaultValues.HIDE_AFTER_SEC,
				"value": DefaultValues.HIDE_AFTER_SEC,
				"infos": {
					"name": Paths.HIDE_AFTER_SEC,
					"type": TYPE_FLOAT,
					"hint": PROPERTY_HINT_RANGE,
					"hint_string": "-1,30,0.01",
				},
			},
			{
				"path": Paths.SAFE_DELETION_TIME_SEC,
				"default_value": DefaultValues.SAFE_DELETION_TIME_SEC,
				"value": DefaultValues.SAFE_DELETION_TIME_SEC,
				"infos": {
					"name": Paths.SAFE_DELETION_TIME_SEC,
					"type": TYPE_FLOAT,
					"hint": PROPERTY_HINT_RANGE,
					"hint_string": "0.0,1.0,0.01",
				},
			},
			{
				"path": Paths.DELAY_BEFORE_EXIT_SEC,
				"default_value": DefaultValues.DELAY_BEFORE_EXIT_SEC,
				"value": DefaultValues.DELAY_BEFORE_EXIT_SEC,
				"infos": {
					"name": Paths.DELAY_BEFORE_EXIT_SEC,
					"type": TYPE_FLOAT,
					"hint": PROPERTY_HINT_RANGE,
					"hint_string": "1,30,0.01",
				},
			},
			{
				"path": Paths.HIDE_ON_SCREEN_DRAG,
				"default_value": DefaultValues.HIDE_ON_SCREEN_DRAG,
				"value": DefaultValues.HIDE_ON_SCREEN_DRAG,
				"infos": {
					"name": Paths.HIDE_ON_SCREEN_DRAG,
					"type": TYPE_BOOL,
				},
			},
			{
				"path": Paths.HIDE_ON_NEXT_TOUCH_EVENT,
				"default_value": DefaultValues.HIDE_ON_NEXT_TOUCH_EVENT,
				"value": DefaultValues.HIDE_ON_NEXT_TOUCH_EVENT,
				"infos": {
					"name": Paths.HIDE_ON_NEXT_TOUCH_EVENT,
					"type": TYPE_BOOL,
				},
			},
			{
				"path": Paths.DISPLAY_ON_SINGLE_TOUCH,
				"default_value": DefaultValues.DISPLAY_ON_SINGLE_TOUCH,
				"value": DefaultValues.DISPLAY_ON_SINGLE_TOUCH,
				"infos": {
					"name": Paths.DISPLAY_ON_SINGLE_TOUCH,
					"type": TYPE_BOOL,
				},
			},
			{
				"path": Paths.MAX_TOOLTIP,
				"default_value": DefaultValues.MAX_TOOLTIP,
				"value": DefaultValues.MAX_TOOLTIP,
				"infos": {
					"name": Paths.MAX_TOOLTIP,
					"type": TYPE_INT,
					"hint": PROPERTY_HINT_RANGE,
					"hint_string": "1,10,1",
				},
			},
			{
				"path": Paths.MARGIN,
				"default_value": DefaultValues.MARGIN,
				"value": DefaultValues.MARGIN,
				"infos": {
					"name": Paths.MARGIN,
					"type": TYPE_INT,
				},
			},
			{
				"path": Paths.INDICATOR_MARGIN,
				"default_value": DefaultValues.INDICATOR_MARGIN,
				"value": DefaultValues.INDICATOR_MARGIN,
				"infos": {
					"name": Paths.INDICATOR_MARGIN,
					"type": TYPE_INT,
				},
			},
			{
				"path": Paths.ENTER_SOUND,
				"default_value": DefaultValues.ENTER_SOUND,
				"value": DefaultValues.ENTER_SOUND,
				"infos": {
					"name": Paths.ENTER_SOUND,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.wav,*.mp3,*.ogg",
				},
			},
			{
				"path": Paths.EXIT_SOUND,
				"default_value": DefaultValues.EXIT_SOUND,
				"value": DefaultValues.EXIT_SOUND,
				"infos": {
					"name": Paths.EXIT_SOUND,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.wav,*.mp3,*.ogg",
				},
			},
			{
				"path": Paths.AUDIO_BUS,
				"default_value": DefaultValues.AUDIO_BUS,
				"value": DefaultValues.AUDIO_BUS,
				"infos": {
					"name": Paths.AUDIO_BUS,
					"type": TYPE_STRING,
				},
			},
			{
				"path": Paths.DEFAULT_POSITION,
				"default_value": DefaultValues.DEFAULT_POSITION,
				"value": DefaultValues.DEFAULT_POSITION,
				"infos": {
					"name": Paths.DEFAULT_POSITION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": POSITIONS_HINT,
				},
			},
			{
				"path": Paths.DISPLAY_REQUESTER_INDICATOR,
				"default_value": DefaultValues.DISPLAY_REQUESTER_INDICATOR,
				"value": DefaultValues.DISPLAY_REQUESTER_INDICATOR,
				"infos": {
					"name": Paths.DISPLAY_REQUESTER_INDICATOR,
					"type": TYPE_BOOL,
				},
			},
			{
				"path": Paths.REQUESTER_INDICATOR_ANIMATION,
				"default_value": DefaultValues.REQUESTER_INDICATOR_ANIMATION,
				"value": DefaultValues.REQUESTER_INDICATOR_ANIMATION,
				"infos": {
					"name": Paths.REQUESTER_INDICATOR_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": REQUESTER_INDICATOR_ANIMS_HINT,
				},
			},
			{
				"path": Paths.TEXT_HORIZONTAL_ALIGNMENT,
				"default_value": DefaultValues.TEXT_HORIZONTAL_ALIGNMENT,
				"value": DefaultValues.TEXT_HORIZONTAL_ALIGNMENT,
				"infos": {
					"name": Paths.TEXT_HORIZONTAL_ALIGNMENT,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": TEXT_H_ALIGNMENTS_HINT,
				},
			},
			{
				"path": Paths.TEXT_VERTICAL_ALIGNMENT,
				"default_value": DefaultValues.TEXT_VERTICAL_ALIGNMENT,
				"value": DefaultValues.TEXT_VERTICAL_ALIGNMENT,
				"infos": {
					"name": Paths.TEXT_VERTICAL_ALIGNMENT,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": TEXT_V_ALIGNMENTS_HINT,
				},
			},
			{
				"path": Paths.BACKGROUND,
				"default_value": DefaultValues.BACKGROUND,
				"value": DefaultValues.BACKGROUND,
				"infos": {
					"name": Paths.BACKGROUND,
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "StyleBoxTexture,StyleBoxFlat",
				},
			},
			{
				"path": Paths.FONT,
				"default_value": DefaultValues.FONT,
				"value": DefaultValues.FONT,
				"infos": {
					"name": Paths.FONT,
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "LabelSettings",
				},
			},
			{
				"path": Paths.ENTER_ANIMATION,
				"default_value": DefaultValues.ENTER_ANIMATION,
				"value": DefaultValues.ENTER_ANIMATION,
				"infos": {
					"name": Paths.ENTER_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": ENTER_ANIMS_HINT,
				},
			},
			{
				"path": Paths.CUSTOM_ENTER_ANIMATION,
				"default_value": DefaultValues.CUSTOM_ENTER_ANIMATION,
				"value": DefaultValues.CUSTOM_ENTER_ANIMATION,
				"infos": {
					"name": Paths.CUSTOM_ENTER_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.gd,*.txt",
				},
			},
			{
				"path": Paths.EXIT_ANIMATION,
				"default_value": DefaultValues.EXIT_ANIMATION,
				"value": DefaultValues.EXIT_ANIMATION,
				"infos": {
					"name": Paths.EXIT_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": EXIT_ANIMS_HINT,
				},
			},
			{
				"path": Paths.CUSTOM_EXIT_ANIMATION,
				"default_value": DefaultValues.CUSTOM_EXIT_ANIMATION,
				"value": DefaultValues.CUSTOM_EXIT_ANIMATION,
				"infos": {
					"name": Paths.CUSTOM_EXIT_ANIMATION,
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_FILE,
					"hint_string": "*.gd,*.txt",
				},
			},
		];
