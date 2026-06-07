class_name Card extends PanelContainer

var card_json: Dictionary
var title: String
var img_path: String
var success: String
var failure: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Title/Image.texture.resource_path = img_path
	$Title.text = title
	$VSplitContainer/SuccessBox.text = success
	$VSplitContainer/FailureBox.text = failure
	return
	
func load_card() -> bool:
	title = card_json["title"]
	img_path = card_json["img_path"]
	success = card_json["success"]
	failure = card_json["failure"]
	if !title || !img_path || !success || !failure:
		return false
	return true
