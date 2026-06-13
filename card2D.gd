class_name Card2D extends Area2D

var card: Card
var grabbed: bool = false
var can_grab: bool = false

func _ready() -> void:
	return

func add_card(_card: Card) -> void:
	card = _card
	if card: add_child(card)
	return
	
func remove_card() -> void:
	if card: remove_child(card)
	card = null
	return
	
func _mouse_enter() -> void:
	if card:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		can_grab = true
		SignalBus.card_hovered.emit(card)
	return

func _mouse_exit() -> void:
	can_grab = false
	return

func _input(event: InputEvent) -> void:
	if !card: return
	if event is InputEventMouseButton:
		if event.is_action_pressed("select"):
			if can_grab: 
				card.mouse_default_cursor_shape = Control.CURSOR_DRAG
				grabbed = true
		elif event.is_action_released("select"):
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			grabbed = false
	elif event is InputEventMouseMotion && grabbed:
		var mouse_delta: Vector2 = event.relative
		position += mouse_delta
		pass
