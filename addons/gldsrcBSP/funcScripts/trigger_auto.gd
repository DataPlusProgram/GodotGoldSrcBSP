extends Node


var targetName
var oneshot = false



func _ready():
	var delay = get_meta("delay")
	targetName = get_meta("target")
	
	var timer = Timer.new()
	timer.wait_time = int(delay)
	timer.one_shot = true
	timer.autostart = true
	timer.connect("timeout",self,"activate")
	add_child(timer)
	


func activate():
	get_tree().call_group(targetName,"activate")
	queue_free()

