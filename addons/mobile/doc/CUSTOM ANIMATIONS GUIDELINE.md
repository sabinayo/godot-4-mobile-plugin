
# Custom Animation Guideline

A guide to writing custom animations for the help bar node or tooltip node.

## Notes
- Animation code must be written in the [animate](https://github.com/sabinayo/godot-4-mobile-plugin/blob/master/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md#void-animateobj-control-virtual) function to work correctly.

- When using custom animation, you will need to play the sound (if any) manually in your code. To do this, simply call the [_play_sound()](https://github.com/sabinayo/godot-4-mobile-plugin/blob/master/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md#void-_play_soundsound_path-string-const) or [_play_sound_from_project_settings()](https://github.com/sabinayo/godot-4-mobile-plugin/blob/master/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md#methods) function.
- All custom animations must emit the [animation_finished](https://github.com/sabinayo/godot-4-mobile-plugin/blob/master/doc/CUSTOM%20ANIMATIONS%20GUIDELINE.md#signals) signal once the animation has been completed. This ensures that the node to be animated is correctly deleted if the custom animation is used for the output animation.

Base implementation of custom animation:


```gdscript
extends MobileCustomAnimation;

func animate(obj: Control) -> void:
	# Animation code here.
	pass;
```
Sound usage in custom animation:
```gdscript
extends MobileCustomAnimation;

func animate(obj: Control) -> void:
	# Animation code here.
	
	# Play sound defined in ProjectSettings.
	_play_sound_from_project_settings(_SoundStates.ENTER, _AnimationFallBacks.HELP_BAR);
	
	# Play a sound not absolutely defined in ProjectSettings
	_play_sound("path/to/sound");
```

### Methods
#### `void animate(obj: Control) virtual`
Virtual method used to animate a help bar node or a tooltip node. `obj` is the node to animate.

#### `void _play_sound(sound_path: String) const`
Plays a sound located at `sound_path`.

#### _play_sound_from_project_settings
```gdscript
void _play_sound_from_project_settings(
	sound_state := _SoundStates.ENTER,
	fall_back := _AnimationFallBacks.HELP_BAR
) const
```
Plays the sound specified in [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html). If no sound is found, then the sound located in `fall_back` in [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html) will be used instead. `sound_state` specifies where the sound should be selected in either "Enter Sound" or "Exit Sound".

### Signals
`animation_finished()`
All custom animation must emit this signal once the animation is ended. This ensure that the node to animate is properly deleted if the custom animation is used for exit animation.

### Sample

The code below make a help bar or a tooltip appear from left to right with some fade animation in 0.5s using a [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html) node.

```gdscript
extends MobileCustomAnimation;

func animate(obj: Control) -> void:
	var time := 0.5;
	var tween := create_tween();
	_play_sound_from_project_settings(_SoundStates.ENTER, _AnimationFallBacks.HELP_BAR);
	var destination: Vector2 = obj.global_position;
	
	obj.global_position -= Vector2(obj.size.x, 0.0);
	obj.modulate.a = 0;
	tween.set_ease(Tween.EASE_OUT);
	tween.set_trans(Tween.TRANS_SINE);
	tween.set_parallel();
	
	tween.tween_property(obj, "position", destination, time);
	tween.tween_property(obj, "modulate:a", 1.0, time);
	
	tween.finished.connect(emit_signal.bind("animation_finished"));
	_play_sound_from_project_settings(_SoundStates.EXIT, _AnimationFallBacks.HELP_BAR);
```


In addition, you can use the constants of animation founded in `res://addons/mobile/mobile.gd` to improve your animations.
