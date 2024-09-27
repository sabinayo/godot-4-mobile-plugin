@tool
extends EditorProperty;

const SIGNALS_MANAGER: PackedScene = preload("../signals_manager/signals_manager.tscn");
const SIGNALS_MANAGER_FUNC := "_on_help_bar_gui_input";
const EDITOR_SCENE: PackedScene = preload("help_bar_settings.tscn");

var updating := false;

var _editor;
var _editor_data := {};
var _signals_manager;
var _help_bar_was_enabled := false;
var _virtual_keyboard_enabled := true;


func _init() -> void:
	_editor = EDITOR_SCENE.instantiate();
	add_child(_editor);
	add_focusable(_editor);
	set_bottom_editor(_editor);
	_editor.setting_changed.connect(_on_setting_changed);


func _check_for_mobile_connector() -> void:
	var edited_scene_root = get_tree().edited_scene_root;
	var obj = get_edited_object();
	
	if obj.has_meta(Mobile.SIGNALS_MANAGER_META):
		var meta: String = obj.get_meta(Mobile.SIGNALS_MANAGER_META);
		var stored_node = obj.get_node_or_null(meta);
		
		if stored_node == null:
			if edited_scene_root.has_node(Mobile.SIGNALS_MANAGER):
				_signals_manager = edited_scene_root.get_node(Mobile.SIGNALS_MANAGER);
			
			else:
				_signals_manager = SIGNALS_MANAGER.instantiate();
				edited_scene_root.add_child(_signals_manager, false, INTERNAL_MODE_BACK);
				_signals_manager.owner = edited_scene_root;
			
			obj.set_meta(
				Mobile.SIGNALS_MANAGER_META,
				str(obj.get_path_to(_signals_manager))
			);
		
		else:
			_signals_manager = stored_node;
	
	elif edited_scene_root.has_node(Mobile.SIGNALS_MANAGER):
		_signals_manager = edited_scene_root.get_node(Mobile.SIGNALS_MANAGER);
		obj.set_meta(
			Mobile.SIGNALS_MANAGER_META,
			str(obj.get_path_to(_signals_manager))
		);
	
	else:
		_signals_manager = SIGNALS_MANAGER.instantiate();
		edited_scene_root.add_child(_signals_manager, false, INTERNAL_MODE_BACK);
		_signals_manager.owner = edited_scene_root;
		obj.set_meta(
			Mobile.SIGNALS_MANAGER_META,
			str(obj.get_path_to(_signals_manager))
		);


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint(): return;
	
	var obj = get_edited_object();
	var v_kbd_enabled = obj.get("virtual_keyboard_enabled");

	if (
		v_kbd_enabled == null
		or v_kbd_enabled == _virtual_keyboard_enabled
	): return;

	var setting: String = Mobile.HelpBar.MetaProperties.ENABLED;

	_virtual_keyboard_enabled = v_kbd_enabled;

	if _virtual_keyboard_enabled:
		if _help_bar_was_enabled:
			_editor.update_setting(setting, _virtual_keyboard_enabled);

	else:
		obj.set_meta(setting, _virtual_keyboard_enabled);
		_editor.update_setting(setting, _virtual_keyboard_enabled);


func _on_setting_changed(property: String, value: Variant) -> void:
	if updating: return;
	
	var obj = get_edited_object();
	
	match property:
		Mobile.HelpBar.MetaProperties.ENABLED:
			_help_bar_was_enabled = value;
			_editor_data = _editor.get_data();
			
			if value:
				var v_kbd_enabled = obj.get("virtual_keyboard_enabled");
				var settings: Array = Mobile.HelpBar.MetaProperties.values();
				
				if v_kbd_enabled != null and not v_kbd_enabled:
					obj.set_meta(Mobile.HelpBar.MetaProperties.KEYBOARD, false);
					_editor_data[Mobile.HelpBar.MetaProperties.KEYBOARD] = false;
				
				for setting in settings:
					if (
						setting == Mobile.HelpBar.MetaProperties.KEYBOARD
						and obj.get("virtual_keyboard_type") != null 
					):
						_editor.disable_setting(Mobile.HelpBar.MetaProperties.KEYBOARD);
						continue;
					
					# Keep previous data if one
					if not obj.has_meta(setting):
						obj.set_meta(setting, _editor.get_setting(setting));
				
				_editor_data[Mobile.HelpBar.REQUESTER_PROPERTY] = str(_signals_manager.get_path_to(obj));
				var _func := Callable(_signals_manager, SIGNALS_MANAGER_FUNC).bind(_editor_data);
				
				if not obj.gui_input.is_connected(_func):
					obj.connect("gui_input", _func, CONNECT_PERSIST);
					obj.notify_property_list_changed();
			
			else:
				var _func := Callable(_signals_manager, SIGNALS_MANAGER_FUNC).bind(_editor_data);
				
				if obj.gui_input.is_connected(_func):
					obj.gui_input.disconnect(_func);
					obj.notify_property_list_changed();
	
	obj.set_meta(property, value);
	emit_changed(property, value);


func _update_property() -> void:
	_check_for_mobile_connector();
	var obj = get_edited_object();
	var settings: Array = Mobile.HelpBar.MetaProperties.values();
	var v_kbd_enabled = obj.get("virtual_keyboard_enabled");
	
	if v_kbd_enabled != null:
		_editor.disable_setting(Mobile.HelpBar.MetaProperties.KEYBOARD);
		
		if not v_kbd_enabled:
			obj.set_meta(Mobile.HelpBar.MetaProperties.KEYBOARD, false);
			_editor_data[Mobile.HelpBar.MetaProperties.KEYBOARD] = false;
	
	updating = true;
	
	for setting in settings:
		if not obj.has_meta(setting):
			obj.set_meta(setting, _editor.get_setting(setting));
		
		else:
			var val: Variant = obj.get_meta(setting);
			_editor_data[setting] = val;
			_editor.update_setting(setting, val);
	
	_editor_data = _editor.get_data();
	_editor.set_fast_settings_data({
		"edited_object": str(_signals_manager.get_path_to(obj)),
		"signals_manager": str(_signals_manager.get_path()),
		"overrides": _signals_manager.get_meta("help_bar_overrides")
	});
	_editor_data[Mobile.HelpBar.REQUESTER_PROPERTY] = str(_signals_manager.get_path_to(obj));
	var _func := Callable(_signals_manager, SIGNALS_MANAGER_FUNC).bind(_editor_data);
	
	if obj.get_meta(Mobile.HelpBar.MetaProperties.ENABLED):
		if not obj.gui_input.is_connected(_func):
			obj.gui_input.connect(_func, CONNECT_PERSIST);
			obj.notify_property_list_changed();
		
		else:# case of duplicated nodes(signal connected without bind arguments)
			obj.gui_input.disconnect(_func);
			obj.gui_input.connect(_func, CONNECT_PERSIST);
			obj.notify_property_list_changed();
	
	updating = false;
