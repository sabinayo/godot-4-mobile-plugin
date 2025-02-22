﻿# Godot Mobile Plugin
A plugin used to display a help bar and tooltip on mobile devices. The help bar is displayed when the user is about to write text in the application.

## Notes
When you activate `HelpBar` or `Tooltip` on a node, the signal connection is valid only for that node and not for nodes duplicated from it. If you duplicate several nodes at once with `HelpBar` or `Tooltip` enabled, you need to click on each duplicated node for the connections to work as expected.

## Installation
Download the plugin from the [Godot Asset Library](https://godotengine.org/asset-library/asset/3375) or  download it from [Github](https://github.com/sabinayo/godot-4-mobile-plugin/) and copy the "addons/mobile" folder into your Godot project directory.
	Activate the plugin inside Project > Project settings > Plugins.


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

You can use predifined animations when help bar or tooltip appears or disappears. You can also use custom animations. Custom animations are user-coded animations and must be written according the [Custom Animations Guideline](https://github.com/sabinayo/godot-4-mobile-plugin/blob/main/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md).
You can use `.gd` or `.txt` files to write your code.

## Documentation

- [Help Bar](https://github.com/sabinayo/godot-4-mobile-plugin/blob/main/doc/HELP%20BAR%20SETTINGS.md)
- [Tooltip](https://github.com/sabinayo/godot-4-mobile-plugin/blob/main/doc/TOOLTIP%20SETTINGS.md)
- [Custom Animation Guidelines](https://github.com/sabinayo/godot-4-mobile-plugin/blob/main/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md)
