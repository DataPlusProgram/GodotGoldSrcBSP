extends Node


var targetNodePaths = []
var targetNodes
var breakSound = null
var unbreakable = false
var targetName = null
var matSound ={
	0: "debris/bustglass1.wav",
	1: "debris/bustcrate3.wav",
	2: "debris/bustmetal2.wav",
	3: "debris/bustflesh1.wav",
	4: "debris/bustconcrete1.wav",
	5: "debris/bustceiling.wav",
	6: "debris/bustflesh1.wav",
	7: "",
	8: "debris/bustconcrete1.wav",
}

func _ready():
	targetNodes = get_meta("targetNodes")
	
	
	var nodePath = "Geometry/"+targetNodes
	var materialType = get_meta("materialType")
	if materialType == 7:
		unbreakable = true

	targetNodes = get_parent().get_parent().get_node(nodePath)
	targetNodes.set_meta("breakable",self)
	if has_meta("targetName"):
		targetName = get_meta("targetName")
	breakSound = get_parent().get_parent().createAudioPlayer3DfromName(matSound[materialType])
	breakSound.translation = targetNodes.translation
	breakSound.unit_size =  10
	add_child(breakSound)
	
func takeDamage():
	activate()

func activate():
	if unbreakable == true:
		return
	if targetNodes!= null:
		if breakSound!= null:
			breakSound.play()
	
		targetNodes.queue_free()
		
	if targetName != null:
			for i in get_tree().get_nodes_in_group(targetName):
				i.activate()
