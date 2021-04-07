extends Area

func _ready():
	self.connect("body_entered",self,"_on_ladder_body_entered")
	self.connect("body_exited",self,"_on_ladder_body_exited")
	


func _on_ladder_body_entered(body):
	
	if body.is_in_group("hlTrigger"):
		if body.has_method("enterWater"):
			body.enterLadder()



func _on_ladder_body_exited(body):
	
	if body.is_in_group("hlTrigger"):
		if body.has_method("exitWater"):
			body.exitLadder()

