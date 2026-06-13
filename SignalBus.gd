extends Node

signal card_hovered(card: Card)

func emit_card_hovered(card: Card) -> void:
	card_hovered.emit(card)
