# Godot Mobile Plugin
A plugin used to display a help bar and tooltip(s) on mobile devices. The help bar is displayed when the user is about to write text in the application.

## Notes
When you activate `HelpBar` or `Tooltip` on a node, the signal connection only applies to that node and not to any nodes that have been duplicated from it. If you duplicate several nodes with `HelpBar` or `Tooltip` enabled, you need to click on each duplicate for the signal connections to be recreated and work as expected.

## Installation
Download the plugin from the [Godot Asset Library](https://godotengine.org/asset-library/asset/3375) or  download it from [Github](https://github.com/sabinayo/godot-4-mobile-plugin/releases) and copy the `addons` folder into your Godot project directory. Activate the plugin at `Project > Project settings > Plugins`.

To test the plugin directly on your PC, go to `Project > Project Settings` and enable `enable_touch_from_mouse`.  
![Enable touch emulation with mouse in godot project](https://raw.githubusercontent.com/sabinayo/godot-4-mobile-plugin/refs/heads/main/screenshots/test_plugin_with_pc.png)  
Then load the demo scene located at `addons/mobile/examples/demo.tscn`.
By default, only a device with a virtual keyboard can display the help bar. In order to test this on your PC, you can comment the restrictor in the `display_help_bar` method of the `mobile.gd` script, as mentioned below.
```gdscript
func display_help_bar(data: Dictionary) -> void:
# Comment this part to test the help bar with your PC
if !DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
	return
```

## How to use

- **Help bar**: Select a [LineEdit](https://docs.godotengine.org/fr/4.x/classes/class_lineedit.html) or [SpinBox](https://docs.godotengine.org/fr/4.x/classes/class_spinbox.html) node and enable `HelpBar`in the inspector. Then, edit settings as you want.

- **Tooltip**: Select any [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) node in the scene dock and look at the `Tooltip` property in the inspector. Then above `Tooltip Text` check `Display on Mobile`.

## Help bar
Display a help bar on android devices with a [LineEdit](https://docs.godotengine.org/fr/4.x/classes/class_lineedit.html) node and optionally
a tip to guide the user.

Compatibles nodes are [LineEdit](https://docs.godotengine.org/fr/4.x/classes/class_lineedit.html) nodes and [SpinBox](https://docs.godotengine.org/fr/4.x/classes/class_spinbox.html) nodes


![Help bar screenshot](https://raw.githubusercontent.com/sabinayo/godot-4-mobile-plugin/refs/heads/main/screenshots/help_bar_and_keyboard.png)
 

## Tooltip

Display a tooltip on mobile devices. Optionally, some settings can be edited in order to improve tooltip display.

If you intend to use a node inheriting from BaseButton in order to display a tooltip, make sure that the node has its [action_mode](https://docs.godotengine.org/en/stable/classes/class_basebutton.html#class-basebutton-property-action-mode) property set to [BaseButton.ACTION_MODE_BUTTON_RELEASE](https://docs.godotengine.org/en/stable/classes/class_basebutton.html#enum-basebutton-actionmode).

![tooltip screenshot](https://raw.githubusercontent.com/sabinayo/godot-4-mobile-plugin/refs/heads/main/screenshots/tooltip.png)

## Additional notes

You can use predifined animations when help bar or tooltip appears or disappears. You can also use custom animations written in gdscript. Be aware that custom animations have to be written according the [Custom Animations Guideline](https://github.com/sabinayo/godot-4-mobile-plugin/blob/main/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md).

## Documentation

- [Help Bar](https://github.com/sabinayo/godot-4-mobile-plugin/blob/main/doc/HELP%20BAR%20SETTINGS.md)
- [Tooltip](https://github.com/sabinayo/godot-4-mobile-plugin/blob/main/doc/TOOLTIP%20SETTINGS.md)
- [Custom Animation Guidelines](https://github.com/sabinayo/godot-4-mobile-plugin/blob/main/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md)
