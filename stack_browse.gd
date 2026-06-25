class_name StackBrowse extends PanelContainer

const PLAN_CARD_SCENE: PackedScene = preload('res://PlanCard.tscn')
const CARD2D_SCENE: PackedScene = preload("res://Card2D.tscn")
const POPUP_CARD_START_POS: Vector2 = Vector2(20,20)

@onready var buttonref: Button = $Button

func load_stack(contents: Array[Card]) -> void:
	var place_pos: Vector2 = POPUP_CARD_START_POS
	for c: Card in contents:
		var dupe: Card = PLAN_CARD_SCENE.instantiate()
		dupe.card_json = c.card_json
		dupe.load_card()
		var c2: Card2D = CARD2D_SCENE.instantiate()
		add_child(c2)
		c2.add_card(dupe)
		c2.position = place_pos
		place_pos += Vector2(20,0)
	return	
