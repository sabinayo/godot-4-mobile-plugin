@tool
extends EditorInspectorPlugin;

const TOOLTIP_ENABLER: GDScript = preload("../tooltip/tooltip_enabler.gd");
const HELP_BAR_ENABLER: GDScript = preload("../help_bar/help_bar_enabler.gd");


func _can_handle(object) -> bool: return object is Control;


func _parse_begin(object: Object) -> void:
	match object.get_class():
		"SpinBox", "LineEdit":
			var props := PackedStringArray(Mobile.HelpBar.MetaProperties.values());
			add_property_editor_for_multiple_properties(
				"HelpBar", props, HELP_BAR_ENABLER.new()
			);


func _parse_group(object: Object, group: String) -> void:
	match group:
		"Tooltip":
			add_property_editor("", TOOLTIP_ENABLER.new());
