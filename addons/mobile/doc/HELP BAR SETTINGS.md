
# Help bar settings
> path: Project->Project Settings-> Mobile -> Help Bar

![Help bar settings screenshot.](https://github.com/sabinayo/godot-4-mobile-plugin/blob/5456fa9559a4fdd46a8bca60f498b1c7022bddea/screenshots/help-bar-settings.png)

## Important

Settings modified in [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html) are applied in all instance of the default help bar scene.
You can also edit some of these settings for a single help bar. To do so, create a new `MobileHelpBarFastSettings` or load one. Settings modified inside a `MobileHelpBarFastSettings` overrides those defined in [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html).

![MobileHelpBarFastSettings creation and edition.](https://github.com/sabinayo/godot-4-mobile-plugin/blob/fb59f7ff2061feb60e45aead29c54987997f8cce/screenshots/create-and-edit-mhbfs.gif)

## Configuration

### **scene**
>default: `res://addons/mobile/help_bar/help_bar.tscn`
>
>path: `mobile/help_bar/scene`

***WARNING: Changing parameters when using a custom scene has no effect on it; You will have to manage the modified parameters yourself***.

You can override the default scene used to display help bar by specifing one in
the project's settings.

To replace the default scene, the following conditions must be met:

1. Your custom scene must extend [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) or any child of a [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) node.
	The new scene's script must contain at least the same functions and signals as the default scene's script. You can handle these functions as you want.
	
	```gdscript
	# Custom scene requirements.
 	extends Control

	signal text_changed(text: String)
	signal text_submitted(text: String)

	func set_edition(keyboard: int, tip: String, text: String) -> void:
		pass
	```

 2. Your custom scene must contains the following [Unique Nodes](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_unique_nodes.html):
	- `label` a [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) node.
	- `topic` a [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) node.
	- `edition` a [LineEdit](https://docs.godotengine.org/fr/4.x/classes/class_lineedit.html) node.
	
	You can place these node anywhere.
	
	>These nodes are used to display, in the help bar scene, information supplied by the user in the inspector during editing.


### Hide on external events
>default: `false`
>
>path: `mobile/help_bar/configuration/hide_on_external_events`

If enabled, the help bar is hidden when the user clicks outside the help bar area.


## Display

### Anchor
>default: `Full Rect`
>
>path: `mobile/help_bar/display/anchor`

Position of help bar relative to free space when keyboard is visible.

The following options are available : `Top wide, Center wide, Bottom wide, Full Rect`.


### Background
>path: `mobile/help_bar/display/background`

Background [StyleBox](https://docs.godotengine.org/en/stable/classes/class_stylebox.html) for the panel of help bar node.


### Font
>path: `mobile/help_bar/display/font`

The [LabelSettings](https://docs.godotengine.org/en/stable/classes/class_labelsettings.html) used for the help bar including [LineEdit](https://docs.godotengine.org/en/stable/classes/class_lineedit.html) node and tip's [Label](https://docs.godotengine.org/en/stable/classes/class_label.html).


### Enter Animation
>default: `Fade`
>
>path: `mobile/help_bar/display/enter_animation`

Animation played when the help bar node appears.

The following animation are availables : `None, Bounce, Fade, Fade Down, Fade Left, Fade Right, Fade Up, Pop, Scale, Scale X, Scale Y`.


### Custom Enter Animation
>path: `mobile/help_bar/display/custom_enter_animation`

Custom animation when the help bar appears. If set, help bar instance will use this animation regardless of the value of [Enter Animation](https://github.com/sabinayo/godot-4-mobile-plugin/blob/master/doc/HELP%20BAR%20SETTINGS.md#enter-animation). See [README](https://github.com/sabinayo/godot-4-mobile-plugin/blob/388473c7f16c0910cccc9eed615d0dda51a6235f/README.md#additional-notes) and [CUSTOM ANIMATIONS GUIDELINE](https://github.com/sabinayo/godot-4-mobile-plugin/blob/388473c7f16c0910cccc9eed615d0dda51a6235f/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md) for more informations.


### Exit Animation
>default: `Fade`
>
>path: `mobile/help_bar/display/exit_animation`

Animation played before the help bar node disappear.

The following animation are availables : `None, Bounce, Fade, Fade Down, Fade Left, Fade Right, Fade Up, Pop, Scale, Scale X, Scale Y`.


### Custom Exit Animation
>path: `mobile/help_bar/display/custom_exit_animation`

Custom animation when the help bar disappears. If set, help bar instance will use this animation regardless of the value of [Exit Animation](https://github.com/sabinayo/godot-4-mobile-plugin/blob/master/doc/HELP%20BAR%20SETTINGS.md#exit-animation). See [README](https://github.com/sabinayo/godot-4-mobile-plugin/blob/388473c7f16c0910cccc9eed615d0dda51a6235f/README.md#additional-notes) and [CUSTOM ANIMATIONS GUIDELINE](https://github.com/sabinayo/godot-4-mobile-plugin/blob/388473c7f16c0910cccc9eed615d0dda51a6235f/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md) for more informations.


## Tip

### Tip Background
>path: `mobile/help_bar/tip/tip_background`

Background [StyleBox](https://docs.godotengine.org/en/stable/classes/class_stylebox.html) for the tip's [Label](https://docs.godotengine.org/en/stable/classes/class_label.html).


### Tip Font
>path: `mobile/help_bar/tip/tip_font`

The [LabelSettings](https://docs.godotengine.org/en/stable/classes/class_labelsettings.html) used for the Tip's text. Overrides the font defined by `mobile/help_bar/display/font`.


## Line Edit

### Line Edit Normal Background
>path: `mobile/help_bar/line_edit/normal_background`

Default background for the [LineEdit](https://docs.godotengine.org/en/stable/classes/class_lineedit.html) used in the help bar scene.


### Line Edit Focus Background
>path: `mobile/help_bar/line_edit/focus_background`

Background used when the [LineEdit](https://docs.godotengine.org/en/stable/classes/class_lineedit.html) has GUI focus.


### Line Edit Font Size
>default: `40`
>
>path: `mobile/help_bar/line_edit/font_size`

Font size of the [LineEdit](https://docs.godotengine.org/en/stable/classes/class_lineedit.html)'s text.


