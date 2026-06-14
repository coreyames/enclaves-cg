extends Control

var cardset: Array[Card]      = []
var decklist: Array[Card]     = []
var deck: Array[Card]         = []
var discard: Array[Card]      = []
var hand: Array[Card]         = []
var hand_slots: Array[Card2D] = []
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
	deck = decklist.duplicate()
	
	# deck hidden and also discard when empty
	$Deck/Card.flip()
	$Discard/Card.flip()
	
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
		$HandZone/Slot5,
	]

	# draw hand
	#for i: int in range(hand_slots.size()):
	for i: int in range(hand_slots.size()-1):
		draw_card_to_hand()

	SignalBus.card_hovered.connect(_on_card_hovered)
	$PlayerRegion.mouse_entered.connect(_on_mouse_entered_player_region)
	$PlayerRegion.mouse_exited.connect(_on_mouse_exited_player_region)
	SignalBus.card2d_grabbed.connect(_on_card2d_grabbed)
	SignalBus.card2d_dropped.connect(_on_card2d_dropped)
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
func draw_card_to_hand() -> bool:
	if deck.size() < 1:
		print("deck empty! can't draw")
		return false
	elif hand.size() >= 5:
		print("hand full! can't draw")
		return false
	hand.append(deck.pop_front())
	update_hand_zone()
	return true

# card draw results in hand "rerender"
func update_hand_zone() -> void:
	for slot: Card2D in hand_slots: 
		slot.remove_card()
	var idx: int = 0
	for card: Card in hand:
		hand_slots[idx].add_card(card)
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
	
func _on_card2d_dropped(dropped_at: Vector2) -> void:
	if !mouse_in_player_region:
		if grabbed_card2d_start_position:
			grabbed_card2d.global_position = grabbed_card2d_start_position
	elif grabbed_card2d.get_parent() == $HandZone:
		grabbed_card2d.get_parent().remove_child(grabbed_card2d)
		add_child(grabbed_card2d)
		grabbed_card2d.global_position = dropped_at		
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
