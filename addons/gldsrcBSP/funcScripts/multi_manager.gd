extends Node


var targetGroups

func _ready():
	targetGroups = get_meta("targetGroups")
	


func activate():
	for group in targetGroups:
		for i in get_tree().get_nodes_in_group(group):
			if i!=self and i.get_class() != "Node":
				i.activate()
