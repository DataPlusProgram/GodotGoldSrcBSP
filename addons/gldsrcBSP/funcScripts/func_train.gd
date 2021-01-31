extends Spatial

var targetNodes = []
var pathName = []
var pathPosArr = []
var refArr = {}
func _ready():
	var targetNodesPath = get_meta("targetNodePaths")
	var pathName = get_meta("path")
	for i in targetNodesPath:
		var gp= get_parent()
		targetNodes.append(gp.get_node("Geometry").get_node(i))
	
	
	var ref = targetNodes[0].translation
	
	for i in targetNodes:
		
		var firstPosNode =  get_parent().find_node(pathName[0],true,false)
		i.translation -= ref
		refArr[i] = i.translation 
		i.translation +=  firstPosNode.translation

		
	pathName.pop_front()
	
	for i in pathName:
		var destination = get_parent().find_node(i,true,false)
		if destination != null:
			pathPosArr.append(destination.translation)
		
		
	

func setOrigin(node,origin):
	for c in  node.get_children():
		if "translation" in c:
			c.translation = node.translation
						
	node.translation = origin

func _physics_process(delta):
	for n in targetNodes:
		n.translation = n.translation.linear_interpolate(pathPosArr[0]+refArr[n],0.0001)
