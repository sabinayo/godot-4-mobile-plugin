

# Tooltip settings
> path: Project->Project Settings-> Mobile -> Tooltip

![Tooltip settings screenshot](https://github.com/sabinayo/godot-4-mobile-plugin/blob/a235d7adc5809b740e3336a3c585e01f05634c2d/screenshots/tooltip-settings.png)

## Important

Settings modified in [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html) are applied in all instance of the default tooltip scene.
You can also edit some of these settings for a single tooltip. To do so, create a new `MobileTooltipFastSettings` or load one. Settings modified inside a `MobileTooltipFastSettings` overrides those defined in [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html).

![MobileTooltipFastSettings creation and edition.](https://github.com/sabinayo/godot-4-mobile-plugin/blob/a235d7adc5809b740e3336a3c585e01f05634c2d/screenshots/create-and-edit-mtfs.gif)

## Configuration

### scene
>default: `res://addons/mobile/tooltip/tooltip.tscn`
>
>path: `mobile/tooltip/scene`

***WARNING: Changing parameters when using a custom scene has no effect on it; You will have to manage the modified parameters yourself. If you use a custom scene, you'll have to script your own tooltip logic***.

You can override the default scene used to display tooltip by specifing
one in the [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html).

 You must implement the function below in your custom scene.
 The type of the scene doesn't matter.

```gdscript
func set_mobile_tooltip(data: Dictionary)
```

data keys:
- `text`: the [tooltip_text](https://docs.godotengine.org/en/stable/classes/class_control.html#class-control-property-tooltip-text) of the tooltip requester.
-  `requester`: absolute path to the tooltip requester.
-  `event_position`: position of the finger in global coordinates.
-  `settings_overrides`: custom settings for a single tooltip.

 
### Tooltip Delay(sec)
>default: `0.5`
>
>path: `mobile/tooltip/configuration/tooltip_delay_sec`

Default delay for tooltips (in seconds).


### Safe deletion time (sec)
>default: `0.5`
>
>path: `mobile/tooltip/configuration/safe_deletion_time_sec`

Time (in seconds) after which tooltip deletion is considered safe, after the tooltip has been displayed. If tooltip deletion is requested before this time has elapsed (just after the tooltip has been displayed), tooltip deletion is not safe, and animation errors may occur with some tooltip animations.


### Hide After (sec)
>default: `-1`
>
>path: `mobile/tooltip/configuration/hide_after_sec`

If more than `0`, the tooltip will be hidden after the specified time (in seconds).


### Delay Before Exit (sec)
>default: `1`
>
>path: `mobile/tooltip/configuration/delay_before_exit_sec`

Delay (in seconds) before tooltip removal begins. Applies only when the tooltip is displayed and is almost immediately requested to be removed.


### Hide on Screen Drag
>default: `false`
>
>path: `mobile/tooltip/hide_on_screen_drag`

When enabled, the displayed tooltip will disappear when the user touch outside of the tooltip requester area, with an [InputEventScreenDrag](https://docs.godotengine.org/en/stable/classes/class_inputeventscreendrag.html).


### Hide on Next Touch Event
>default: `true`
>
>path: `mobile/tooltip/hide_on_next_touch_event`

**Important**: Only works if `mobile/tooltip/display_on_single_touch` is set to `true`.
If enabled, hides the displayed tooltip if the player touch again the screen.


### Display on Single Touch
>default: `false`
>
>path: `mobile/tooltip/display_on_single_touch`

If enabled, tooltip will appear when user touch a node once. Tooltip will appear after the time specified in `Tooltip Delay(sec)`.


### Max tooltip
>default: `1`
>
>path: `mobile/tooltip/max_tooltip`

Specify the number of tooltips which can be displayed at the same time.
If more than 1, user can display many tooltips at the same time by selecting
many [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) nodes. For example, if the player leaves two finger on two
differents [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) nodes, each tooltip of these nodes will be displayed.
By default, only the last selected [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) node will display tooltip.


### Margin
>default: `10`
>
>path: `mobile/tooltip/configuration/margin`

Set the margin(vertical or horizontal) between the tooltip node and it's requester.

### Indicator Margin
>default: `0`
>
>path: `mobile/tooltip/configuration/indicator_margin`

Set the margin(vertical or horizontal) between the tooltip indicator and the tooltip.


### Enter Sound
>path: `mobile/tooltip/configuration/enter_sound`

Specify the sound played when the tooltip appears.


### Exit Sound
>path: `mobile/tooltip/configuration/exit_sound`

Specify the sound played when the tooltip disappears.


### Audio Bus
>default: `Master`
>
>path: `mobile/tooltip/configuration/audio_bus`

Bus on which the [Tooltip Enter Sound]() and [Tooltip Exit Sound]() will be played.


## Display

### Default position
>default: `Above`
>
>path: `mobile/tooltip/display/default_position`

Tooltip position relative to the tooltip requester.

The following options are availables: `Above, Below, Left, Right`.

Position evolution if the tooltip can't be displayed at the specified position:

| Default Position | Evolution |
|--|--|
| `Above` | `Below -> Left -> Right -> Above` |
| `Below` | `Above -> Left -> Right -> Below` |
| `Left` | `Right -> Above -> Below -> Left` |
| `Right` | `Left -> Above -> Below -> Right` |


### Display Requester Indicator
>default: `true`
>
>path: `mobile/tooltip/display/display_requester_indicator`

If enabled, this option tells the user which node is currently displaying the tooltip.

![tooltip requester indicator](https://github.com/sabinayo/godot_mobile_plugin/blob/main/screenshots/tooltip_settings.png)

### Requester Indicator Animation
>default: `Fade`
>
>path: `mobile/tooltip/display/requester_indicator_animation`

Indicator animation played when the tooltip node appears.

The following animation are availables : `None, Bounce, Fade, Pop, Scale`.


### Text Horizontal Alignment
>default: `Left`
>
>path: `mobile/tooltip/display/text_horizontal_alignment`

Control's the text horizontal alignment.

The following options are availables: `Left, Center, Right, Fill`.
See [HorizontalAlignment](https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html#enum-globalscope-horizontalalignment) constants for further explanation.


### Text Vertical Alignment
>default: `Top`
>
>path: `mobile/tooltip/display/text_vertical_alignment`

Control's the text vertical alignment.

The following options are availables: `Top, Center, Bottom, Fill`.
See [VerticalAlignment](https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html#enum-globalscope-verticalalignment) constants for further explanation.


### Background
>path: `mobile/tooltip/display/background`

Background [StyleBox](https://docs.godotengine.org/en/stable/classes/class_stylebox.html) for the tooltip.


### Font
>path: `mobile/tooltip/display/font`

The [LabelSettings](https://docs.godotengine.org/en/stable/classes/class_labelsettings.html) of the tooltip node.


### Enter Animation
>default: `Fade`
>
>path: `mobile/tooltip/display/enter_animation`

Animation played when the tooltip appears.

The following animation are availables : `None, Bounce, Fade, Fade Down, Fade Left, Fade Right, Fade Up, Pop, Scale, Scale X, Scale Y`.


### Custom Enter Animation
>path: `mobile/tooltip/display/custom_enter_animation`

Custom animation when the tooltip appears. If set, tooltip instance will use this animation regardless of the value of [Enter Animation](https://github.com/sabinayo/godot-4-mobile-plugin/blob/5b68dca382182a0c33937180fe32d368b43ccc0f/doc/TOOLTIP%20SETTINGS.md#enter-animation). See [README](https://github.com/sabinayo/godot-4-mobile-plugin/blob/388473c7f16c0910cccc9eed615d0dda51a6235f/README.md#additional-notes) and [CUSTOM ANIMATIONS GUIDELINE](https://github.com/sabinayo/godot-4-mobile-plugin/blob/388473c7f16c0910cccc9eed615d0dda51a6235f/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md) for more informations.


### Exit Animation
>default: `Fade`
>
>path: `mobile/tooltip/display/exit_animation`

Animation played before tooltip disappear.

The following animation are availables : `None, Bounce, Fade, Fade Down, Fade Left, Fade Right, Fade Up, Pop, Scale, Scale X, Scale Y`.


### Custom Exit Animation
>path: `mobile/tooltip/display/custom_exit_animation`

Custom animation when the tooltip disappears. If set, tooltip instance will use this animation regardless of the value of [Exit Animation](https://github.com/sabinayo/godot-4-mobile-plugin/blob/master/doc/TOOLTIP%20SETTINGS.md#exit-animation). See [README](https://github.com/sabinayo/godot-4-mobile-plugin/blob/388473c7f16c0910cccc9eed615d0dda51a6235f/README.md#additional-notes) and [CUSTOM ANIMATIONS GUIDELINE](https://github.com/sabinayo/godot-4-mobile-plugin/blob/388473c7f16c0910cccc9eed615d0dda51a6235f/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md) for more informations.

