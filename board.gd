extends Control

var cardset: Array[Card]  = []
var decklist: Array[Card] = []
var deck: Array[Card]     = []
var discard: Array[Card]  = []
const card_2d_scene: PackedScene   = preload("res://card2D.tscn")
const base_card_scene: PackedScene = preload("res://Card.tscn")
const plan_card_scene: PackedScene = preload("res://PlanCard.tscn")
const type_to_scene: Dictionary = {
	"Base": base_card_scene,
	"Plan": plan_card_scene
}

var values: Dictionary[String, int] 

func _ready() -> void:
	cardset = load_cards("res://cards.json")
	if cardset.size() < 1:
		print("failed loading cardset")
		return
	
	# TESTING card holder	
	var new_card_2d: Node2D = card_2d_scene.instantiate()
	new_card_2d.add_card(cardset[0])
	add_child(new_card_2d)
	
	# TODO load_deck()
	# TODO create decklist format 

	#"hide" deck and when empty, the discard
	$Deck/Card.flip()
	$Discard/Card.flip()
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
	
	
	return

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
	
func _on_update_water_value(value: int) -> void:
	values.water = value
	return

func _on_update_food_value(value: int) -> void:
	values.food = value
	return
	
func _on_update_specialist_value(value: int) -> void:
	values.specialist = value
	return

func _on_update_utility_value(value: int) -> void:
	values.utility = value
	return
	
func _on_update_despair_value(value: int) -> void:
	values.despair = value
	return

func _on_update_stability_value(value: int) -> void:
	values.stability = value
	return

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_tree().quit()
	return
