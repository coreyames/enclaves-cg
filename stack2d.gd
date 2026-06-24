class_name Stack2D extends Card2D

signal contents_changed 

const card_scene: PackedScene = preload("res://Card.tscn")
var contents: Array[Card] = []
var was_empty: bool = true
var stack_contents_grabbed: bool = false
var last_removed_idx: int = -1
var click_timer: Timer
var check_double_click: bool = true
var handref: Array[Card]
var max_hand_size: int = 5
var top_face_down: bool = true

func _ready() -> void:
	SignalBus.card2d_dropped.connect(_on_card2d_dropped_here)
	SignalBus.card2d_dropped.connect(_on_new_card2_dropped)
	click_timer = Timer.new()
	click_timer.wait_time = Settings.DOUBLE_CLICK_THRESHOLD
	click_timer.one_shot = true
	click_timer.timeout.connect(_on_click_timer_single_click)
	handref = get_parent().hand
	contents_changed.connect(_on_contents_changed)
	add_child(click_timer)
	for c: Node in get_children():
		if c is CollisionShape2D:
			shape_ref = c.shape
	return

func _input(event: InputEvent) -> void:
	if !card || contents.size() == 0:
		can_grab = false
	
	if event is InputEventMouseButton && event.is_action_pressed("select"):
		var rect: Rect2 = $CollisionShape2D.shape.get_rect()
		var pt: Vector2 = get_viewport().get_mouse_position()
		var cpt: Vector2 = global_position
		var new_rect: Rect2 = Rect2(cpt, rect.size)

		if !new_rect.has_point(pt):
			return
		if check_double_click:
			check_double_click = false
			can_grab = true
			click_timer.start()
			input_event.connect(_on_do_double_click)
	elif event is InputEventMouseButton && event.is_action_released("select"):
		can_grab = false
	return

func _on_do_double_click(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.button_index == 1 && event.is_action_pressed("select"):
		if event.double_click:
			input_event.disconnect(_on_do_double_click)
			SignalBus.card_draw.emit(draw_no_emit())
			check_double_click = true
			can_grab = false
			click_timer.stop()
	return
	
func _on_click_timer_single_click() -> void:
	if !check_double_click && can_grab && contents.size() > 0:
		var new_card2d: Card2D = Card2D.new()
		var drawn_card: Card = draw_no_emit(true)
		if drawn_card:
			new_card2d.card = drawn_card.duplicate() 
			last_removed_idx = 0
			new_card2d.card.load_card() 
			new_card2d.add_card(new_card2d.card)			
			can_grab = false
			stack_contents_grabbed = true
			new_card2d.grabbed = true
			new_card2d.can_grab = false
			get_tree().current_scene.add_child(new_card2d)
			new_card2d.global_position = global_position
			new_card2d.card.mouse_default_cursor_shape = Control.CURSOR_DRAG
			SignalBus.card2d_grabbed.emit(new_card2d)
		
	input_event.disconnect(_on_do_double_click)
	check_double_click = true
	can_grab = false
	return
	
func _mouse_exit() -> void:
	can_grab = false
	SignalBus.slot_exited.emit()
	return

#prevent immediate grab ability when go voer
func _mouse_enter() -> void:
	pass

# int return val is OK or Err
func insert_card(_card: Card, from_top: int = 0) -> int:
	var ok_or_err: int = contents.insert(from_top, _card)
	if ok_or_err == OK:
		contents_changed.emit()
	if from_top == 0:
		remove_display_card()
		add_card(_card)
	return ok_or_err
	
func take_card(from_top: int, emit: bool = true) -> Card:
	var taken_card: Card
	if contents.size() < 1 || abs(from_top) >= contents.size(): return null
	taken_card = contents.pop_at(from_top)
	if contents.size() < 1:
		remove_display_card()
	elif from_top >= 0: 
		remove_display_card()
		add_card(contents[0])
		if card.face_down != top_face_down:
			card.flip()
	if emit: SignalBus.card_draw.emit(taken_card)
	contents_changed.emit()
	return taken_card
	
func draw(ignore_hand_limit: bool = false) -> Card:
	if contents.size() < 1:
		print("deck empty! can't draw")
		return null
	if !ignore_hand_limit && handref.size() >= max_hand_size:
		print("hand full! can't draw")
		return null
	return take_card(0)
	
func draw_no_emit(ignore_hand_limit: bool = false) -> Card:
	if contents.size() < 1:
		print("deck empty! can't draw")
		return null
	if !ignore_hand_limit && handref.size() >= max_hand_size:
		print("hand full! can't draw")
		return null
	return take_card(0, false)

func set_top_card(_card: Card) -> void:
	var idx: int = contents.find(_card)
	if idx < 0:
		insert_card(_card)
	elif idx >= 0:
		set_top_card_from_idx(idx)
	return

func set_top_card_from_idx(idx: int = 0) -> void:
	var taken_card: Card = take_card(idx, false)
	remove_display_card()
	insert_card(taken_card)
	return
	
func set_card_face_down(val: bool) -> void:
	if card && !card.face_down == val:
		card.flip()
	return

func set_bottom_card(_card: Card) -> void:
	var idx: int = contents.find(_card)
	if idx < 0:
		contents.push_back(_card)	
	elif idx > 0:
		set_bottom_card_idx(idx)
	return
	
func set_bottom_card_idx(idx: int) -> void:
	var _card: Card = take_card(idx)
	contents.push_back(_card)
	return

func shuffle() -> void:
	contents.shuffle()
	set_top_card_from_idx()
	return
	
func _on_new_card2_dropped(_at: Vector2, held_card: Card = null, undo: bool = false) -> void:
	if undo && held_card:
		insert_card(held_card, last_removed_idx)
	elif !held_card:
		return
	can_grab = true
	stack_contents_grabbed = false
	var card2d: Card2D = held_card.get_parent()
	card2d.grabbed = false 
	return
	
func _on_card2d_dropped_here(_dropped_at: Vector2, _card: Card = null, _undo: bool = false) -> void:
	if !shape_ref:
		return
	var rect: Rect2 = shape_ref.get_rect()
	var cpt: Vector2 = global_position
	var new_rect: Rect2 = Rect2(cpt, rect.size)
	if new_rect.has_point(_dropped_at):
		if _card:
			var _card_parent: Card2D = _card.get_parent()
			if _card_parent:
				_card_parent.remove_card()
				if _card_parent not in get_tree().current_scene.hand_slots:
					_card_parent.queue_free()
				else:
					handref.erase(_card)					
			insert_card(_card)
			set_top_card(_card)
	return
	
func _on_contents_changed() -> void:
	$StackMenu.text = "%d" % [contents.size()]
	return
	
func refresh_stack_count() -> void:
	_on_contents_changed()
	return
	
func remove_display_card() -> void:
	remove_card()
	return
	
