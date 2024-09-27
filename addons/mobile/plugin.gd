@tool
extends EditorPlugin;

const DATA_DIR := "user://mobile";
const SAVE := "%s/settings.cfg" % DATA_DIR;
const SAVE_SECTION := "ProjectSettings";

var _settings: Array[Dictionary];
var _inspector_plugin: EditorInspectorPlugin = preload("tools/mobile_inspector_plugin.gd").new();


func _enter_tree() -> void:
	if !DirAccess.dir_exists_absolute(DATA_DIR):
		DirAccess.make_dir_absolute(DATA_DIR);
	
	_settings = Mobile.HelpBar.ProjSettings.CONFIG.duplicate();
	_settings.append_array(Mobile.Tooltip.ProjSettings.CONFIG.duplicate());
	add_inspector_plugin(_inspector_plugin);
	var tool_icon: Texture2D = preload("icons/tools.svg");
	
	add_custom_type(
		"MobileTooltipFastSettings", "Resource",
		preload("tooltip/tooltip_fast_settings.gd"),
		tool_icon
	);
	add_custom_type(
		"MobileHelpBarFastSettings", "Resource",
		preload("tooltip/tooltip_fast_settings.gd"),
		tool_icon
	);
	
	if FileAccess.file_exists(SAVE):
		var cfg := ConfigFile.new();
		var err: int = cfg.load(SAVE);
		
		if err != OK: return;
		
		for key in cfg.get_section_keys(SAVE_SECTION):
			ProjectSettings.set_setting(
				key, cfg.get_value(SAVE_SECTION, key)
			);
	
	add_settings();


func _exit_tree() -> void:
	remove_inspector_plugin(_inspector_plugin);
	remove_custom_type("MobileTooltipFastSettings");
	
	var cfg := ConfigFile.new();
	
	for setting in _settings:
		if ProjectSettings.has_setting(setting["path"]):
			cfg.set_value(
				SAVE_SECTION, setting["path"],
				ProjectSettings.get_setting(setting["path"]),
			);
			ProjectSettings.set_setting(setting["path"], null);
	
	cfg.save(SAVE);
	ProjectSettings.save();


func add_settings() -> void:
	for setting in _settings:
		if !ProjectSettings.has_setting(setting["path"]):
			ProjectSettings.set_setting(setting["path"], setting["value"]);
		
		ProjectSettings.add_property_info(setting["infos"]);
		ProjectSettings.set_initial_value(setting["path"], setting["default_value"]);
	
	ProjectSettings.save();
