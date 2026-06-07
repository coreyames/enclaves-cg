extends Area2D

var card: Card
var grabbed: bool = false

func _ready() -> void:
	return

func add_card(_card: Card) -> void:
	card = _card
	if card: add_child(card)
	return
	
func _mouse_enter() -> void:
	if card:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return

func _input(event: InputEvent) -> void:
	if !card: return
	if event is InputEventMouseButton:
		if event.is_action_pressed("select"):
			card.mouse_default_cursor_shape = Control.CURSOR_DRAG
			grabbed = true
		elif event.is_action_released("select"):
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			grabbed = false
	elif event is InputEventMouseMotion && grabbed:
		var mouse_delta: Vector2 = event.relative
		position += mouse_delta
		pass
