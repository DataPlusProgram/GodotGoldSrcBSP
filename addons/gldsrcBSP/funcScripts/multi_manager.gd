extends Node


var targetGroups

func _ready():
	targetGroups = get_meta("targetGroups")
	
func setState(state):
	toggle()

func toggle():
	for group in targetGroups:
		for i in get_tree().get_nodes_in_group(group["name"]):
			if i!=self and i.get_class() != "Node":
				var script = load("res://addons/gldsrcBSP/funcScripts/trigger_auto.gd")
				var timer = Node.new()
				
				timer.set_meta("delay",group["delay"])
				timer.set_meta("target",group["name"])
				timer.set_script(script)
				add_child(timer)
				#i.activate()
