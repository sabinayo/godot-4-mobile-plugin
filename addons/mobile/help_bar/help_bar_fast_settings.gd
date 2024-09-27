@tool
class_name MobileHelpBarFastSettings;

extends Resource;

signal property_changed(property: String, value: Variant);

var props: PackedStringArray;


func _init() -> void:
	var _settings: Array[Dictionary] = Mobile.HelpBar.ProjSettings.CONFIG.duplicate();
	
	for setting in _settings:
		if not Mobile.HelpBar.FAST_SETTINGS.has(setting["path"]): continue;
		
		var path := Array(setting["path"].split("/", false));
		
		props.append("%s/%s" % [path[-2], path[-1]]);
		var value = ProjectSettings.get_setting(setting["path"], setting["default_value"]);
		
		if value is Resource:
			value.changed.connect(
				Callable(self, "_on_internal_resource_changed").bind(
					setting["path"], setting["default_value"]
				)
			);
		
		set_meta(path[-1], value);


func _on_internal_resource_changed(property: StringName, value: Variant) -> void:
	property_changed.emit(Mobile.HelpBar.ProjSettings.SAVE_PATH + property, value);
	set_meta(property.get_slice("/", 1), value);


func _get(property: StringName) -> Variant:
	var prop: String = property.get_slice("/", 1);
	
	if has_meta(prop):
		var value = get_meta(prop);
		
		if (
			value is Resource
			and not value.changed.is_connected(_on_internal_resource_changed)
		):
			value.changed.connect(
				Callable(self, "_on_internal_resource_changed").bind(
					property, value
				)
			);
		
		return get_meta(prop);
	
	return null;


func _set(property: StringName, value: Variant) -> bool:
	var prop: String = property.get_slice("/", 1);
	
	if has_meta(prop):
		if (
			value is Resource
			and not value.changed.is_connected(_on_internal_resource_changed)
		):
			value.changed.connect(
				Callable(self, "_on_internal_resource_changed").bind(
					property, value
				)
			);
		
		property_changed.emit(Mobile.HelpBar.ProjSettings.SAVE_PATH + property, value);
		set_meta(prop, value);
		
		return true;
	
	return false;


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = [];
	var _settings: Array[Dictionary] = Mobile.HelpBar.ProjSettings.CONFIG.duplicate();
	
	for setting in _settings:
		if not Mobile.HelpBar.FAST_SETTINGS.has(setting["path"]): continue;
		
		var path := Array(setting["path"].split("/", false));
		
		properties.append({
			"name": "%s/%s" % [path[-2], path[-1]],
			"type": setting["infos"]["type"],
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": setting["infos"].get("hint", ""),
			"hint_string": setting["infos"].get("hint_string", "")
		});
	
	return properties;


func _property_can_revert(property: StringName) -> bool:
	return props.has(property);


func _property_get_revert(property: StringName) -> Variant:
	var prop: String = property.get_slice("/", 1);
	var begin_prop: String = property.get_slice("/", 0);
	
	return ProjectSettings.get_setting(
		Mobile.HelpBar.ProjSettings.CONFIG_PATH + prop,
		ProjectSettings.get_setting(
			Mobile.HelpBar.ProjSettings.DISPLAY_PATH + prop,
			ProjectSettings.get_setting(
				Mobile.HelpBar.ProjSettings.TIP_PATH + prop,
				ProjectSettings.get_setting(
					Mobile.HelpBar.ProjSettings.LINE_EDIT_PATH + prop,
				)
			)
		)
	);
