extends Node

@warning_ignore_start("unused_signal")
signal card_hovered(card: Card)
signal card2d_grabbed(card2D: Card)
signal card2d_dropped(dropped_at: Vector2, card: Card, undo: bool)
signal card_draw(card: Card)
