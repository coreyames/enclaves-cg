class_name ValuePanel extends Panel

signal value_changed(old_value: int, new_value: int)

var value: int

func _ready() -> void:
	value = 0
	$Value.text = str(value)
	$Increase.connect("input_event", _on_click_increase)
	$Decrease.connect("input_event", _on_click_decrease)
	return

func _on_click_increase(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("select"):
		var old: int = value
		value += 1
		value_changed.emit(old, value)
		$Value.text = str(value)
	return

func _on_click_decrease(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("select"):
		var old: int = value
		value -= 1
		value_changed.emit(old, value)
		$Value.text = str(value)
	return

func set_value(new_value: int) -> void:
	var old: int = value
	value = new_value
	value_changed.emit(old, value)
	$Value.text = str(value)
	return
