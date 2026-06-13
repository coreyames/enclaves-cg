class_name Card extends PanelContainer

var card_json: Dictionary
var title: String
var id: int
var img_path: String
var cost: String
var costs: Vector3i
var types: Array

var face_down: bool

func _ready() -> void:
	$Title/Image.texture.resource_path = img_path
	$Title.text = title
		
	if cost: 
		costs = parse_cost(cost)
		$Title/FoodCost/Value.text = ""
		$Title/WaterCost/Value.text = ""
		$Title/GeneralCost/Value.text = ""
		if costs[0] > 0:
			$Title/FoodCost/Value.text = str(costs[0])
		if costs[1] > 0:
			$Title/WaterCost/Value.text = str(costs[1])
		if costs[2] > 0:
			$Title/GeneralCost/Value.text = str(costs[2])
			
	if types:
		handle_types(types)
	return
	
func load_card() -> bool:
	if card_json.has("id"):
		id = card_json["id"]
	if card_json.has("title"):
		title = card_json["title"]
	if card_json.has("img_path"):
		img_path = card_json["img_path"]
	if card_json.has("cost"):
		cost = card_json["cost"]
	if card_json.has("types"):
		types = card_json["types"]
	
	if !(id && title && img_path && cost && types):
		return false
	return true

func parse_cost(cost_string: String) -> Vector3i:
	var split: PackedStringArray = cost_string.split(":")
	return Vector3(split[0].to_int(),split[1].to_int(),split[2].to_int())
	
func handle_types(types_array: Array) -> bool:
	var num_types: int = types_array.size()
	if num_types < 1: return false
	elif num_types > 3: return false
	$Title/MainType.text = "[i]Card[/i]\n[i]%s[/i]" % [types_array[0]]
	var sub1: String = ""
	var sub2: String = ""
	if types_array.size() >= 2:
		sub1 = types_array[1]
	if types_array.size() == 3:
		sub2 = types_array[2]
	$Title/Subtypes.text = "[i]%s[/i]\n[i]%s[/i]" % [sub1, sub2]
	return true

func flip() -> void:
	face_down = !face_down
	if face_down: 
		modulate = Color(0, 0, 0, 1)
	else:
		modulate = Color(1, 1, 1, 1)
