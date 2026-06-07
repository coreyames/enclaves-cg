extends Control

var cardset: Array[Card]
var card_scene: PackedScene = preload("res://Card.tscn")
var card_2d_scene: PackedScene = preload("res://card2D.tscn")

func _ready() -> void:
	cardset = load_cards("res://cards.json")
	if cardset.size() < 1:
		return
	var new_card_2d: Node2D = card_2d_scene.instantiate()
	new_card_2d.add_card(cardset[0])
	add_child(new_card_2d)
	return

func load_cards(path: String) -> Array[Card]:
	var file_text: String = FileAccess.get_file_as_string(path)
	var _cardset: Array[Card] = []
	if !FileAccess.get_open_error() == Error.OK:
		return []
	var parsed_dict: Dictionary = JSON.parse_string(file_text)
	var parsed: Array = parsed_dict["cards"]
	for card in parsed:
		var new_card: Card = card_scene.instantiate()
		new_card.card_json = card
		new_card.load_card()
		_cardset.append(new_card)
	return _cardset

	
