@tool
extends VBoxContainer;

signal setting_changed(which: String);

const FAST_SETTINGS_SCENE: GDScript = preload("../tools/fast_settings_editor.gd");

var _obj_path: String;
var _signals_manager_path: String;
var _props := {
	Mobile.Tooltip.MetaProperties.DISPLAY: {
		"updating": false, "node": "HBox/enable",
		"value": "button_pressed",
	},
};

var settings: EditorResourcePicker;


func _ready() -> void:
	if not Engine.is_editor_hint(): return;
	
	settings = FAST_SETTINGS_SCENE.new("MobileTooltipFastSettings");
	$VBox/HBox.add_child(settings);
	
	settings.resource_changed.connect(
		func (resource: Resource) -> void:
			%custom_settings_editor_enabler.disabled = resource == null;
			%custom_settings_editor_enabler.set_pressed_no_signal(resource != null);
	, CONNECT_DEFERRED);


func set_fast_settings_data(data: Dictionary) -> void:
	settings.set_data(data);
	_obj_path = data["edited_object"];
	_signals_manager_path = data["signals_manager"];


func _on_enable_toggled(button_pressed: bool) -> void:
	var prop: String = Mobile.Tooltip.MetaProperties.DISPLAY;
	
	if !_props[prop]["updating"]:
		setting_changed.emit(prop, button_pressed);
	
	$VBox.visible = button_pressed;


func _on_custom_settings_editor_enabler_pressed() -> void:
	var _signals_manager = get_node(_signals_manager_path);
	var meta_data: Dictionary = _signals_manager.get_meta("tooltip_overrides");
	
#	if err != OK:
#		fast_settings.edited_resource = null;
#		%custom_settings_editor_enabler.disabled = true;
#		return;
	
	if meta_data.has(_obj_path):
		meta_data.erase(_obj_path);
		_signals_manager.set_meta("", meta_data);
	
	settings.edited_resource = null;
	%custom_settings_editor_enabler.disabled = true;


func disable_setting(setting: String) -> void:
	get_node(_props[setting]["node"]).get_parent().hide();


func get_setting(setting: String) -> Variant:
	return get_node(_props[setting]["node"]).get(_props[setting]["value"]);


func update_setting(setting: String, value: Variant) -> void:
	if not _props.has(setting): return;
	
	_props[setting]["updating"] = true;
	var node = get_node(_props[setting]["node"]);
	node.set_indexed(_props[setting]["value"], value);
	_props[setting]["updating"] = false;


func get_data() -> Dictionary:
	var data := {};
	var settings: Array = Mobile.HelpBar.MetaProperties.values();
	
	for setting in settings:
		data[setting] = get_setting(setting);
	
	return data;

