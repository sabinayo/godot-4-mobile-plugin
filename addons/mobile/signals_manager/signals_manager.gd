@tool
extends Node;

# TooltipFastSettings used by the signals manager.
const TOOLTIP_FAST_SETTINGS: PackedStringArray = [
	Mobile.Tooltip.ProjSettings.Paths.TOOLTIP_DELAY_SEC,
	Mobile.Tooltip.ProjSettings.Paths.SCENE,
	Mobile.Tooltip.ProjSettings.Paths.HIDE_ON_NEXT_TOUCH_EVENT,
	Mobile.Tooltip.ProjSettings.Paths.HIDE_ON_SCREEN_DRAG,
	Mobile.Tooltip.ProjSettings.Paths.HIDE_AFTER_SEC,
	Mobile.Tooltip.ProjSettings.Paths.DISPLAY_ON_SINGLE_TOUCH,
];

const TOOLTIP_GLOBAL_SETTNGS: PackedStringArray = [
	Mobile.Tooltip.ProjSettings.Paths.MAX_TOOLTIP,
	Mobile.Tooltip.ProjSettings.Paths.SAFE_DELETION_TIME_SEC,
];

var displayed_tooltip: int = 0;
var tooltip_requesters := {};
var help_bar_displayed := false;
var cant_hide_tooltip_on_next_touch_event := false;

var _max_tooltip: int;
var _hide_tooltip_on_screen_drag: bool;
var _hide_tooltip_on_next_touch_event: bool;
var _finger_on_tooltip_requester := false;
var _display_tooltip_on_single_touch: bool;
var _tooltip_safe_deletion_time: float;
var _tooltip_time_before_deletion: float;
var _mobile_tooltip: PackedScene;
var _tooltip_delay: float;
var _requester_was_disabled: bool;


func _on_renamed() -> void:
	if name != Mobile.SIGNALS_MANAGER:
		name = Mobile.SIGNALS_MANAGER;


func _ready() -> void:
	if not Engine.is_editor_hint():
		var settings = TOOLTIP_GLOBAL_SETTNGS.duplicate() + TOOLTIP_FAST_SETTINGS.duplicate();
		
		for setting in settings:
			var key: String = setting.get_slice("/", setting.get_slice_count("/") - 1);
			
			_set_tooltip_setting(
				setting, ProjectSettings.get_setting(
					setting,
					Mobile.Tooltip.ProjSettings.DefaultValues[key.to_upper()]
				)
			);
	
	elif not renamed.is_connected(_on_renamed):
		renamed.connect(_on_renamed);


func _input(event: InputEvent) -> void:
	if (
		not cant_hide_tooltip_on_next_touch_event
		and not Engine.is_editor_hint()
		and event is InputEventScreenTouch
		and _hide_tooltip_on_next_touch_event
		and not tooltip_requesters.is_empty()
	):
		_delete_tooltip(true);
		cant_hide_tooltip_on_next_touch_event = false;


func update_fast_setting(
	property: String, value: Variant, node: String, obj_path: String,
	fast_setting_type: String
) -> void:
	var meta := "";
	
	match fast_setting_type:
		"MobileHelpBarFastSettings": meta = "help_bar_overrides";
		
		"MobileTooltipFastSettings": meta = "tooltip_overrides";
	
	var data: Dictionary = get_meta(meta);
	
	if not data.has(obj_path):
		data[obj_path] = {};
	
	# Useless to store default value so erase it
	if ProjectSettings.get_setting(property) == value:
		data[obj_path].erase(property);
	
	else:
		data[obj_path][property] = value;
	
	set_meta(meta, data);


func _on_help_bar_gui_input(event: InputEvent, data: Dictionary) -> void:
	if (
		not help_bar_displayed
		and event is InputEventScreenTouch
		and data.has(Mobile.HelpBar.MetaProperties.ENABLED)
	):
		var settings_overrides := {};
		var meta_data: Dictionary = get_meta("help_bar_overrides");
		var requester: String = data[Mobile.HelpBar.REQUESTER_PROPERTY];
		
		if meta_data.has(requester):
			var keys = meta_data[requester].keys();
			
			for key in keys:
				settings_overrides[key] = meta_data[requester][key];
		
		data["settings_overrides"] = settings_overrides;
		data[Mobile.HelpBar.REQUESTER_PROPERTY] = get_node(requester).get_path();
		var mobile: Node = Mobile.new();
		add_child(mobile);
		mobile.help_bar_state_changed.connect(_on_help_bar_state_changed);
		mobile.display_help_bar(data);


func _on_help_bar_state_changed(displayed: bool) -> void:
	help_bar_displayed = displayed;


func _on_tooltip_gui_input(event: InputEvent, data: Dictionary) -> void:
	if event is InputEventScreenTouch:
		cant_hide_tooltip_on_next_touch_event = false;
		_finger_on_tooltip_requester = event.pressed;
		
		var tooltip_requester = data[Mobile.Tooltip.REQUESTER_PROPERTY];
		var already_requester: bool = tooltip_requesters.has(tooltip_requester);
		
		_load_tooltip_fast_settings_from(tooltip_requester);
		
		if (
			not event.pressed
			or already_requester
			or displayed_tooltip >= _max_tooltip
		):
			if already_requester:
				_delete_tooltip(false, tooltip_requester);
			
			return;
		
		if already_requester: return;
		
		if not _display_tooltip_on_single_touch:
			var timer: SceneTreeTimer = get_tree().create_timer(_tooltip_delay);
			timer.timeout.connect(_on_tooltip_delay_ended.bind(
				tooltip_requester, event.position
			));
		
		else:
			_on_tooltip_delay_ended(tooltip_requester, event.position);
	
	elif event is InputEventScreenDrag:
		var tooltip_requester = data[Mobile.Tooltip.REQUESTER_PROPERTY];
		
		if (
			tooltip_requesters.has(tooltip_requester)
			and tooltip_requesters[tooltip_requester]["hide_on_screen_drag"]
		):
			_delete_tooltip(false, tooltip_requester);


func _load_tooltip_fast_settings_from(requester: String) -> void:
	var meta_data: Dictionary = get_meta("tooltip_overrides");
	
	if meta_data.has(requester):
		var keys = meta_data[requester].keys();
		
		for key in keys:
			if TOOLTIP_FAST_SETTINGS.has(key):
				var value = meta_data[requester][key];
				_set_tooltip_setting(key, value);


func _set_tooltip_setting(setting: String, value: Variant) -> void:
	match setting:
		Mobile.Tooltip.ProjSettings.Paths.TOOLTIP_DELAY_SEC:
			_tooltip_delay = value;
		
		Mobile.Tooltip.ProjSettings.Paths.SCENE:
			_mobile_tooltip = load(value);
		
		Mobile.Tooltip.ProjSettings.Paths.HIDE_ON_NEXT_TOUCH_EVENT:
			_hide_tooltip_on_next_touch_event = value;
		
		Mobile.Tooltip.ProjSettings.Paths.HIDE_ON_SCREEN_DRAG:
			_hide_tooltip_on_screen_drag = value;
		
		Mobile.Tooltip.ProjSettings.Paths.DISPLAY_ON_SINGLE_TOUCH:
			_display_tooltip_on_single_touch = value;
		
		Mobile.Tooltip.ProjSettings.Paths.SAFE_DELETION_TIME_SEC:
			_tooltip_safe_deletion_time = value;
		
		Mobile.Tooltip.ProjSettings.Paths.HIDE_AFTER_SEC:
			_tooltip_time_before_deletion = value;
		
		Mobile.Tooltip.ProjSettings.Paths.MAX_TOOLTIP: _max_tooltip = value;


func _delete_tooltip(all := true, tooltip_requester := "") -> void:
	if all:
		var requesters: Array = tooltip_requesters.keys();
		
		for requester in requesters:
			_delete(tooltip_requesters[requester]["path"], requester);
	
	else:
		_delete(tooltip_requesters[tooltip_requester]["path"], tooltip_requester);


func _delete(tooltip_path: String, requester: String) -> void:
	if tooltip_requesters.has(requester):
		tooltip_requesters[requester]["deleting"] = true;
	
	var tooltip = get_node_or_null(tooltip_path);
	
	if tooltip != null:
		var safe_for_deletion: bool = tooltip_requesters[requester]["safe_for_deletion"];
		
		if not safe_for_deletion:
			tooltip.delete(true);
			await tooltip.delay_before_exit_ended;
		
		else:
			tooltip.delete(false);
		
		displayed_tooltip -= 1;
	
	var requester_node = get_node(requester);
	
	if requester_node is BaseButton:
		requester_node.disabled = _requester_was_disabled;
	
	tooltip_requesters.erase(requester);


func _on_tooltip_delay_ended(
	tooltip_requester: String, event_position: Vector2
) -> void:
	if (
		not _display_tooltip_on_single_touch
		and not _finger_on_tooltip_requester
	): return;
	
	var node = get_node_or_null(tooltip_requester);
	
	if (
		node == null
		or tooltip_requesters.has(tooltip_requester)
	): return;
	
	var text: String = node.get_tooltip();
	
	if text == "": return;
	
	if node is BaseButton:
		_requester_was_disabled = node.disabled;
		node.disabled = true;
	
	var tooltip = _mobile_tooltip.instantiate();
	
	if not tooltip or not tooltip.has_method("set_mobile_tooltip"):
		push_error("Attempt to display tooltip with a custom scene which hasn't\
		 the function \"set_mobile_tooltip(text: String)\". Disable \"Display On Mobile\"\
		at: %s or add the function \"set_mobile_tooltip(text: String)\" to your custom scene." % tooltip_requester);
		_mobile_tooltip = load(Mobile.Tooltip.ProjSettings.DefaultValues.SCENE);
		tooltip = _mobile_tooltip.instantiate();
	
	displayed_tooltip += 1;
	
	var settings_overrides := {};
	var meta_data: Dictionary = get_meta("tooltip_overrides");
	
	if meta_data.has(tooltip_requester):
		settings_overrides = meta_data[tooltip_requester].duplicate();
	
	var data := {
		"text": text,
		"requester": node.get_path(),
		"event_position": event_position,
		"settings_overrides": settings_overrides,
	};
	
	tooltip.set_mobile_tooltip(data);
	get_tree().current_scene.add_child(tooltip);
	
	var cur_tooltip_hide_on_screen_drag;
	
	if settings_overrides.has(
		Mobile.Tooltip.ProjSettings.Paths.HIDE_ON_SCREEN_DRAG
	):
		cur_tooltip_hide_on_screen_drag = true;
	
	else:
		cur_tooltip_hide_on_screen_drag = ProjectSettings.get_setting(
			Mobile.Tooltip.ProjSettings.Paths.HIDE_ON_SCREEN_DRAG,
			Mobile.Tooltip.ProjSettings.DefaultValues.HIDE_ON_SCREEN_DRAG,
		);
	
	tooltip_requesters[tooltip_requester] = {
		"path": tooltip.get_path(),
		"displayed": true,
		"deleting": false,
		"safe_for_deletion": false,
		"hide_on_screen_drag": cur_tooltip_hide_on_screen_drag,
	};
	
	if _tooltip_time_before_deletion > 0:
		get_tree().create_timer(_tooltip_time_before_deletion).timeout.connect(
			_on_tooltip_deletion_timer_timeaput.bind(tooltip_requester)
		);
	
	if _tooltip_safe_deletion_time != 0.0:
		get_tree().create_timer(_tooltip_safe_deletion_time).timeout.connect(
			_on_tooltip_safe_deletion_timer_timeout.bind(tooltip_requester)
		);
	
	for setting in TOOLTIP_FAST_SETTINGS:
		var key: String = setting.get_slice("/", setting.get_slice_count("/") - 1);
		
		_set_tooltip_setting(
			setting, ProjectSettings.get_setting(
				setting,
				Mobile.Tooltip.ProjSettings.DefaultValues[key.to_upper()]
			)
		);
	
	cant_hide_tooltip_on_next_touch_event = true;


func _on_tooltip_deletion_timer_timeaput(tooltip_requester: String) -> void:
	if (
		not tooltip_requesters.has(tooltip_requester)
		or tooltip_requesters[tooltip_requester]["deleting"]
	): return;
	
	tooltip_requesters[tooltip_requester]["deleting"] = true;
	_delete_tooltip(false, tooltip_requester);


func _on_tooltip_safe_deletion_timer_timeout(tooltip_requester: String) -> void:
	if not tooltip_requesters.has(tooltip_requester): return;
	
	tooltip_requesters[tooltip_requester]["safe_for_deletion"] = true;


