extends Node


var targetNodePaths = []
var targetNodes

func _ready():
	pass 


func activate():
	for i in targetNodes:
		i.queue_free()
