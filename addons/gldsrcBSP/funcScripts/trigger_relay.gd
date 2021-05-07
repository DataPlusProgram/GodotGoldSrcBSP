extends Spatial


var targetName
var target
var delay
var state
func _ready():
	targetName = get_meta("target")
	target = get_meta("targetName")
	delay = get_meta("delay")
	state = bool(get_meta("state"))
	
	
func toggle():
	get_tree().call_group(targetName,"setState",state)
