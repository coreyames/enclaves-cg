extends Control

var cardset: Array[Card]
var card_scene: Resource = preload("res://Card.tscn")

func _ready() -> void:
	cardset = load_cards("res://cards.json")
	if cardset.size() < 1:
		return
	add_child(cardset[0])
	return

func load_cards(path: String) -> Array[Card]:
	var file_text: String = FileAccess.get_file_as_string(path)
	var _cardset: Array[Card] = []
	if !FileAccess.get_open_error() == Error.OK:
		return []
	var parsed: Array = JSON.parse_string(file_text)
	for card in parsed:
		var new_card: Card = card_scene.instantiate()
		new_card.card_json = card
		_cardset.append(new_card)
	return _cardset

	
