extends MobileCustomAnimation;


func animate(obj: Control) -> void:
	var time := 0.5;
	var tween := create_tween();
	var destination: Vector2 = obj.global_position - Vector2(obj.size.x, 0.0);
	
	obj.modulate.a = 1.0;
	tween.set_ease(Tween.EASE_OUT);
	tween.set_trans(Tween.TRANS_SINE);
	tween.set_parallel();
	
	tween.tween_property(obj, "position", destination, time);
	tween.tween_property(obj, "modulate:a", 0.0, time);
	
	tween.finished.connect(emit_signal.bind("animation_finished"));
