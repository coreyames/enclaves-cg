class_name Card2D extends Area2D

var card: Card
var grabbed: bool = false
var can_grab: bool = false
var never_grab: bool = false
var shape_ref: Shape2D

func _ready() -> void:
	SignalBus.card2d_dropped.connect(_on_card_dropped_here)
	shape_ref = $CollisionShape2D.shape
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
		can_grab = !(true && never_grab)
		SignalBus.card_hovered.emit(card)
	else:
		SignalBus.slot_hovered.emit(self)
	return

func _mouse_exit() -> void:
	can_grab = false
	SignalBus.slot_exited.emit()
	return

func _on_card_dropped_here(_dropped_at: Vector2, _card: Card, _undo: bool) -> void:
	if !shape_ref:
		return
	var rect: Rect2 = shape_ref.get_rect()
	var cpt: Vector2 = global_position
	var new_rect: Rect2 = Rect2(cpt, rect.size)
	if new_rect.has_point(_dropped_at):
		if !card && _card:
			var _card_parent: Card2D = _card.get_parent()
			if _card_parent:
				_card_parent.remove_card()
			add_card(_card)	
	return

func _input(event: InputEvent) -> void:
	if !card: return
	if event is InputEventMouseButton:
		if event.is_action_pressed("select"):
			if can_grab: 
				card.mouse_default_cursor_shape = Control.CURSOR_DRAG
				grabbed = true
				z_index = 2
				SignalBus.card2d_grabbed.emit(self)
		elif event.is_action_released("select") && grabbed:
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			grabbed = false
			z_index = 1
			SignalBus.card2d_dropped.emit(event.global_position, card, false)
	elif event is InputEventMouseMotion && grabbed:
		var mouse_delta: Vector2 = event.relative
		position += mouse_delta
		pass
