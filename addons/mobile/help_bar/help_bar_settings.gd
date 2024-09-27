@tool
extends VBoxContainer;

signal setting_changed(property: String, value: Variant);
signal overrides_erased();

const FAST_SETTINGS_SCENE: GDScript = preload("../tools/fast_settings_editor.gd");

var _props := {
	Mobile.HelpBar.MetaProperties.TIP: {
		"updating": false, "node": "VBox/HBox/tip",
		"value": "text",
	},
	Mobile.HelpBar.MetaProperties.KEYBOARD: {
		"updating": false, "node": "VBox/HBox2/keyboard",
		"value": "selected",
	},
	Mobile.HelpBar.MetaProperties.ANCHOR: {
		"updating": false, "node": "VBox/HBox3/anchor",
		"value": "selected",
	},
	Mobile.HelpBar.MetaProperties.ENABLED: {
		"updating": false, "node": "HBox/enable",
		"value": "button_pressed",
	},
};
var _data := {};
var _update_text := true;
var _fast_settings: EditorResourcePicker;


func _ready() -> void:
	if not Engine.is_editor_hint(): return;
	
	_fast_settings = FAST_SETTINGS_SCENE.new("MobileHelpBarFastSettings");
	$VBox/HBox5.add_child(_fast_settings);
	
	_fast_settings.resource_changed.connect(
		func (resource: Resource) -> void:
			%custom_settings_editor_enabler.disabled = resource == null;
			%custom_settings_editor_enabler.set_pressed_no_signal(resource != null);
	, CONNECT_DEFERRED);


func set_fast_settings_data(data: Dictionary) -> void:
	_data = data.duplicate();
	_fast_settings.set_data(data);


func _on_tip_text_changed(new_text: String) -> void:
	_update_text = _props[Mobile.HelpBar.MetaProperties.TIP]["updating"];
	setting_changed.emit(Mobile.HelpBar.MetaProperties.TIP, new_text);


func _on_size_selected(index: int) -> void:
	setting_changed.emit(Mobile.HelpBar.MetaProperties.ANCHOR, index);


func _on_keyboard_type_selected(index: int) -> void:
	setting_changed.emit(Mobile.HelpBar.MetaProperties.KEYBOARD, index);


func _on_enable_toggled(button_pressed: bool) -> void:
	setting_changed.emit(Mobile.HelpBar.MetaProperties.ENABLED, button_pressed);
	$VBox.visible = button_pressed;


func disable_setting(setting: String) -> void:
	get_node(_props[setting]["node"]).get_parent().hide();


func get_setting(setting: String) -> Variant:
	return get_node(_props[setting]["node"]).get(_props[setting]["value"]);


func update_setting(setting: String, value: Variant) -> void:
	if not _props.has(setting): return;
	
	_props[setting]["updating"] = true;
	var node = get_node(_props[setting]["node"]);
	
	match node.get_class():
		"LineEdit":
			if _props[setting]["value"] == "text":
				if _update_text:
					node.text = value;# prevent "text_changed" signal emission
			
			else:
				node.set_indexed(_props[setting]["value"], value);
		
		_:
			node.set_indexed(_props[setting]["value"], value);
	
	_props[setting]["updating"] = false;


func get_data() -> Dictionary:
	var data := {};
	var settings: Array = Mobile.HelpBar.MetaProperties.values();
	
	for setting in settings:
		data[setting] = get_setting(setting);
	
	return data;


func _on_custom_settings_editor_enabler_pressed() -> void:
	var edited_obj: NodePath = _data["edited_object"];
	var meta_data: Dictionary = _data["overrides"];
	
	if meta_data.has(edited_obj):
		meta_data.erase(edited_obj);
	
	_fast_settings.edited_resource = null;
	%custom_settings_editor_enabler.disabled = true;
