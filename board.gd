extends Control

var deck: Stack2D
var disc: Stack2D
var cardset: Array[Card]      = []
var decklist: Array[Card]     = []
var hand: Array[Card]         = []
var hand_slots: Array[Card2D] = []
var max_hand_size: int        = 5
var hand_slots_dict: Dictionary[Card2D, Vector2] = {}
var current_detail: Card
var mouse_in_player_region: bool = false
var grabbed_card2d: Card2D
var grabbed_card2d_start_position: Vector2

const card_2d_scene: PackedScene   = preload("res://Card2D.tscn")
const base_card_scene: PackedScene = preload("res://Card.tscn")
const plan_card_scene: PackedScene = preload("res://PlanCard.tscn")
const type_to_scene: Dictionary = {
	"Base": base_card_scene,
	"Plan": plan_card_scene
}
var values: Dictionary[String, int] 

func _ready() -> void:
	deck = $Deck
	disc = $Discard
	disc.input_pickable = false
	
	# load active cardset
	cardset = load_cards("res://cards.json")
	if cardset.size() < 1:
		print("failed loading cardset")
		return
	
	# load list and copy to active deck
	decklist = load_decklist("res://decklist.json")
	if decklist.size() < 1:
		print("failed loading decklist")
		return

	deck.contents = decklist.duplicate()
	deck.shuffle()
	deck.refresh_stack_count()
	
	# setup value tracker and tie to ui
	values.water      = 0
	values.food       = 0
	values.specialist = 0
	values.utility    = 0
	values.despair    = 0
	values.stability  = 100
	$StabilityValue.set_value(values.stability)
	$FoodValue.value_changed.connect(_on_update_food_value)
	$WaterValue.value_changed.connect(_on_update_water_value)
	$SpecialistValue.value_changed.connect(_on_update_specialist_value)
	$UtilityValue.value_changed.connect(_on_update_utility_value)
	$DespairValue.value_changed.connect(_on_update_despair_value)
	$StabilityValue.value_changed.connect(_on_update_stability_value)
	
	# slot references
	hand_slots = [
		$HandZone/Slot1,
		$HandZone/Slot2,
		$HandZone/Slot3,
		$HandZone/Slot4,
		$HandZone/Slot5
	]
	
	hand_slots_dict = {
		$HandZone/Slot1: $HandZone/Slot1.global_position, 
		$HandZone/Slot2: $HandZone/Slot2.global_position,
		$HandZone/Slot3: $HandZone/Slot3.global_position,
		$HandZone/Slot4: $HandZone/Slot4.global_position,
		$HandZone/Slot5: $HandZone/Slot5.global_position,
	}
	
	max_hand_size = hand_slots_dict.size()
	
	for i: int in range(max_hand_size-2):
		drawn_card_to_hand(deck.draw_no_emit())

	SignalBus.card_hovered.connect(_on_card_hovered)
	$PlayerRegion.mouse_entered.connect(_on_mouse_entered_player_region)
	$PlayerRegion.mouse_exited.connect(_on_mouse_exited_player_region)
	SignalBus.card2d_grabbed.connect(_on_card2d_grabbed)
	SignalBus.card2d_dropped.connect(_on_card2d_dropped)
	SignalBus.card_draw.connect(_on_card_draw)
	
	return
	
func _on_card_draw(_card: Card) -> void:
	if hand.size() >= max_hand_size:
		print("hand full! can't draw")
	else:
		drawn_card_to_hand(_card)	
	return
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_tree().quit()
	return

# load entire list of available cards
func load_cards(path: String) -> Array[Card]:
	var file_text: String = FileAccess.get_file_as_string(path)
	var _cardset: Array[Card] = []
	if !FileAccess.get_open_error() == Error.OK:
		return []
	var parsed_json_dict: Dictionary = JSON.parse_string(file_text)
	var parsed_cards_dict: Dictionary  = parsed_json_dict["cards"]
	for type: String in parsed_cards_dict:
		if type != "Plan": continue
		var cards_json: Array = parsed_cards_dict[type]
		var card_type_scene: PackedScene = type_to_scene[type]
		for card_json: Dictionary in cards_json:
			var new_card: Card = card_type_scene.instantiate()
			new_card.card_json = card_json
			new_card.load_card()
			_cardset.append(new_card)
	return _cardset

# dupe cards from cardset to create decklist for use in game
func load_decklist(path: String) -> Array[Card]:
	var file_text: String = FileAccess.get_file_as_string(path)
	var _decklist: Array[Card] = []
	if !FileAccess.get_open_error() == Error.OK:
		return []
	var parsed_json_dict: Dictionary = JSON.parse_string(file_text)
	var parsed_plan_ids: Array = parsed_json_dict["Plans"]
	for id: int in parsed_plan_ids:
		var card: Card = from_cardset_by_id(id)
		if card:
			var dupe_card: Card = card.duplicate() 
			dupe_card.load_card()
			_decklist.append(dupe_card)
		else:
			print("unable to find card by id %d" % [id])
	return _decklist

# for building decklist from ids	
func from_cardset_by_id(id: int) -> Card:
	var find_func: Callable = func(card: Card) -> bool:
		return card.id == id
	var idx: int = cardset.find_custom(find_func)
	if idx < 0:
		return null
	return cardset[idx]
	
# draw a card and update the hand
func drawn_card_to_hand(drawn_card: Card) -> bool:
	if drawn_card:
		if drawn_card.face_down:
			drawn_card.flip()
		hand.append(drawn_card)
		
		update_hand_zone()
	return true

# card draw results in hand "rerender"
func update_hand_zone() -> void:
	for slot: Card2D in hand_slots: 
		slot.remove_card()
	var idx: int = 0
	for card: Card in hand:
		hand_slots[idx].add_card(card)
		if hand_slots[idx].card.face_down:
			hand_slots[idx].card.flip()
		idx += 1
	return

# dupe to replace card in detail view on mouseover
func _on_card_hovered(card: Card) -> void:
	if grabbed_card2d:
		return
	var dupe_card: Card = card.duplicate() 
	dupe_card.load_card()
	if $DetailView/Detail.card:
		$DetailView/Detail.remove_card()
	$DetailView/Detail.add_card(dupe_card)
	return
			
func _on_card2d_grabbed(card2d: Card2D) -> void:
	grabbed_card2d_start_position = card2d.global_position
	grabbed_card2d = card2d
	return
	
func _on_card2d_dropped(_dropped_at: Vector2, _card: Card) -> void:
	var new_card2d: Card2D = card_2d_scene.instantiate()
	
	if !mouse_in_player_region:
		if grabbed_card2d_start_position:
			grabbed_card2d.global_position = grabbed_card2d_start_position
			grabbed_card2d = null
			grabbed_card2d_start_position = Vector2.INF
			return
	if has_node(grabbed_card2d.get_path()):
		new_card2d.card = plan_card_scene.instantiate()
		new_card2d.input_pickable = true
		new_card2d.scale = Vector2.ONE
		new_card2d.global_position = grabbed_card2d.global_position
		new_card2d.card.card_json = grabbed_card2d.card.card_json
		new_card2d.card.load_card()
		add_child(new_card2d)
		new_card2d.add_card(new_card2d.card)
		if grabbed_card2d.get_parent() == $HandZone:
			grabbed_card2d.global_position = hand_slots_dict[grabbed_card2d]
			grabbed_card2d.remove_card()
		else:
			grabbed_card2d.queue_free()
	else:
		print('???')
		
	var card_ref: Card2D
	if new_card2d.get_parent() != null:
		card_ref = new_card2d
	else: 
		card_ref = grabbed_card2d
	
	if card_ref.global_position.y < $PlayerRegion.global_position.y:
		card_ref.global_position.y = $PlayerRegion.global_position.y + 10
	elif card_ref.global_position.y + 160 > $DeckResourceArea.global_position.y:
		card_ref.global_position.y = $DeckResourceArea.global_position.y - 160
	
	if card_ref.global_position.x + 120 > $DetailView.global_position.x:
		card_ref.global_position.x = $DetailView.global_position.x - 120
		if card_ref.global_position.y + 160 > $DetailView.global_position.y:
			card_ref.global_position.y = $DetailView.global_position.y - 160 
		
	grabbed_card2d = null
	grabbed_card2d_start_position = Vector2.INF
	return
			
# simple responses to ui updates
func _on_update_water_value(_old: int, value: int) -> void:
	values.water = value
	return
func _on_update_food_value(_old: int, value: int) -> void:
	values.food = value
	return
func _on_update_specialist_value(_old: int, value: int) -> void:
	values.specialist = value
	return
func _on_update_utility_value(_old: int, value: int) -> void:
	values.utility = value
	return
func _on_update_despair_value(_old: int, value: int) -> void:
	values.despair = value
	return
func _on_update_stability_value(_old: int, value: int) -> void:
	values.stability = value
	return 
func _on_mouse_entered_player_region() -> void:
	mouse_in_player_region = true
	return
func _on_mouse_exited_player_region() -> void:
	mouse_in_player_region = false
	return
