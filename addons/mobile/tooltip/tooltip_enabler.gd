@tool
extends EditorProperty;

const SIGNALS_MANAGER: PackedScene = preload("../signals_manager/signals_manager.tscn");
const SIGNALS_MANAGER_FUNC := "_on_tooltip_gui_input";
const EDITOR_SCENE: PackedScene = preload("tooltip_settings.tscn");

var updating := false;
var _signals_manager;
var _signals_manager_local_path := "";
var _editor;
var _property: String = Mobile.Tooltip.MetaProperties.DISPLAY;



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


func _init() -> void:
	_editor = EDITOR_SCENE.instantiate();
	add_child(_editor);
	add_focusable(_editor);
	set_bottom_editor(_editor);
	_editor.setting_changed.connect(_on_setting_changed, CONNECT_DEFERRED);


func _ready() -> void: label = "Mobile Tooltip";


func _get_tooltip(at_position: Vector2) -> String: return "tooltip_on_mobile";


func _on_setting_changed(property: String, value: Variant) -> void:
	if updating: return;
	
	match property:
		Mobile.Tooltip.MetaProperties.DISPLAY:
			var obj = get_edited_object();
			var data := {Mobile.Tooltip.REQUESTER_PROPERTY: str(_signals_manager.get_path_to(obj))};
			var _func := Callable(_signals_manager, SIGNALS_MANAGER_FUNC).bind(data);
			
			if value:
				if not obj.gui_input.is_connected(_func):
					obj.gui_input.connect(_func, CONNECT_PERSIST);
					obj.notify_property_list_changed();
			
			elif obj.gui_input.is_connected(_func):
				obj.gui_input.disconnect(_func);
				obj.notify_property_list_changed();
	
	get_edited_object().set_meta(property, value);
	emit_changed(property, value);


func _update_property() -> void:
	_check_for_mobile_connector();
	updating = true;
	
	var obj = get_edited_object();
	_editor.set_fast_settings_data({
		"edited_object": str(_signals_manager.get_path_to(obj)),
		"signals_manager": str(_signals_manager.get_path()),
		"overrides": _signals_manager.get_meta("tooltip_overrides")
	});
	var settings: Array = Mobile.Tooltip.MetaProperties.values();
	
	for setting in settings:
		if not obj.has_meta(setting):
			obj.set_meta(setting, _editor.get_setting(setting));
		
		else:
			var val: Variant = obj.get_meta(setting);
			_editor.update_setting(setting, val);
	
	# Connect signal, for duplicated node
	var data := {Mobile.Tooltip.REQUESTER_PROPERTY: str(_signals_manager.get_path_to(obj))};
	var _func := Callable(_signals_manager, SIGNALS_MANAGER_FUNC).bind(data);
	
	if obj.get_meta(Mobile.Tooltip.MetaProperties.DISPLAY):
		if not obj.gui_input.is_connected(_func):
			obj.gui_input.connect(_func, CONNECT_PERSIST);
			obj.notify_property_list_changed();
		
		else:# case of duplicated nodes(signal connected without bind arguments)
			obj.gui_input.disconnect(_func);
			obj.gui_input.connect(_func, CONNECT_PERSIST);
			obj.notify_property_list_changed();
	
	updating = false;
