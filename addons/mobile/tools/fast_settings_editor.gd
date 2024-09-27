@tool
extends EditorResourcePicker;

var _signals_manager_path := "";
var _obj_path := "";


func _init(_base_type: String) -> void: base_type = _base_type;


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL;
	size_flags_vertical = Control.SIZE_EXPAND_FILL;
	size_flags_stretch_ratio = 0.5;
	
	resource_selected.connect(_on_resource_selected, CONNECT_DEFERRED);


func _on_resource_selected(resource: Resource, inspect: bool) -> void:
	var _func := Callable(get_node(_signals_manager_path), "update_fast_setting");
	_func = _func.bind(str(get_path()), _obj_path, base_type);
	
	if !resource.property_changed.is_connected(_func):
		resource.property_changed.connect(_func, CONNECT_DEFERRED);
	
	var p = EditorPlugin.new();
	p.get_editor_interface().edit_resource(resource);


func set_data(data: Dictionary) -> void:
	_obj_path = data["edited_object"];
	_signals_manager_path = data["signals_manager"];
	
	if data["overrides"].has(_obj_path):
		if base_type == "MobileTooltipFastSettings":
			edited_resource = MobileTooltipFastSettings.new();
		
		elif base_type == "MobileHelpBarFastSettings":
			edited_resource = MobileHelpBarFastSettings.new();
		
		var keys = data["overrides"][_obj_path];
		
		for key in keys:
			var meta: String = key.get_slice("/", key.get_slice_count("/") - 1);
			var value = data["overrides"][_obj_path][key];
			
			edited_resource.set_meta(meta, value);
		
		resource_changed.emit(edited_resource);
