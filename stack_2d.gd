class_name Stack2D extends Card2D

const card_scene: PackedScene = preload("res://Card.tscn")
var contents: Array[Card] = []
var was_empty: bool = true
var stack_contents_grabbed: bool = false
var last_removed_idx: int = -1
var click_timer: Timer
var check_double_click: bool = true

func _ready() -> void:
	SignalBus.card2d_dropped.connect(_on_new_card2_dropped)
	click_timer = Timer.new()
	click_timer.wait_time = Settings.DOUBLE_CLICK_THRESHOLD
	click_timer.one_shot = true
	click_timer.timeout.connect(_on_click_timer_single_click)
	modulate = Color(0, 0, 0, 1)
	add_child(click_timer)
	return

func _input(event: InputEvent) -> void:
	if !card || contents.size() == 0:
		can_grab = false
	
	if event is InputEventMouseButton && event.is_action_pressed("select"):
		if check_double_click:
			check_double_click = false
			can_grab = true
			click_timer.start()
			input_event.connect(_on_do_double_click)
	elif event is InputEventMouseButton && event.is_action_released("select"):
		can_grab = false
	return

func _on_do_double_click(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	print(event)
	if event is InputEventMouseButton && event.button_index == 1 && event.is_action_pressed("select"):
		if event.double_click:
			print('double?')
			input_event.disconnect(_on_do_double_click)
			SignalBus.card_draw.emit(draw())
			check_double_click = true
			can_grab = false
			click_timer.stop()
	return
	
func _on_click_timer_single_click() -> void:
	if !check_double_click && can_grab:
		var new_card2d: Card2D = Card2D.new()
		new_card2d.card = draw()
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
	return

#prevent immediate grab ability when go voer
func _mouse_enter() -> void:
	pass

# int return val is OK or Err
func insert_card(_card: Card, from_top: int = 0) -> int:
	var ok_or_err: int = contents.insert(from_top, _card)
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
	if from_top >= 0: 
		remove_display_card()
		add_card(contents[0])
	if emit: SignalBus.card_draw.emit(taken_card)
	return taken_card
	
func draw() -> Card:
	if contents.size() < 1:
		print("deck empty! can't draw")
		return null
	return take_card(0)
	
func draw_no_emit() -> Card:
	if contents.size() < 1:
		print("deck empty! can't draw")
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
	can_grab = true
	stack_contents_grabbed = false
	return
	
func remove_display_card() -> void:
	remove_card()
	return
	
