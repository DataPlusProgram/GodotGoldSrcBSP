extends Area


var targetName
var oneshot = false
func _ready():
	targetName = get_meta("target")
	if has_meta("trigger_once"):
		oneshot = true
		
	
	


func _physics_process(delta):
	for i in get_overlapping_bodies():
		if i.is_in_group("hlTrigger"):
			

			get_tree().call_group(targetName,"activate")
			queue_free()
		
	pass

