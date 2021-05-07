extends Spatial

var targetNodes = []
var pathName = []
var pathPosArr = []
var refArr = {}
var triggers = []
var scaleFactor
var initialRot = 0
var moveSound : AudioStreamPlayer3D = null

onready var path = null#get_parent().find_node("testo",true,false)
onready var pathFollow : PathFollow =null# path.get_child(0)
func _ready():
	var targetNodesPath = get_meta("targetNodePaths")
	var pathName = get_meta("path")
	
	for i in targetNodesPath:
		var gp= get_parent()
		targetNodes.append(gp.get_node("Geometry").get_node(i))
	
	scaleFactor = get_meta("scaleFactor")
	
	if has_meta("pathName"):
		var nameStr= get_meta("pathName")
		path =  get_parent().find_node(nameStr,true,false)
		pathFollow = path.get_child(0)
		
	var ref = targetNodes[0].translation
	
	var triggerTargets = path.get_meta_list()
	for t in triggerTargets:
		var pos = path.get_meta(t)
		if typeof(pos) == TYPE_VECTOR3:
			triggers.append({"name":t,"position":pos})
	
	for i in pathName:#name of each path node
		var destination = get_parent().find_node(i,true,false)
		if destination != null:
			pathPosArr.append(destination.translation)
	
	moveSound = get_node("moveSound")
	


	for i in targetNodes:#for all target faces set origin to ref and add path translation
		var firstPosNode =  get_parent().find_node(pathName[0],true,false)
		i.translation -= ref
		refArr[i] = i.translation 
		i.translation +=  pathPosArr[0]

	
	translation = pathPosArr[0]
	
	if pathPosArr.size() > 2:
		var a : Vector2 =  Vector2(pathPosArr[0].x,pathPosArr[0].z)
		var b : Vector2 =  Vector2(pathPosArr[1].x,pathPosArr[1].z)
		var diff = (b-a).normalized()
		initialRot = atan2(diff.y,diff.x)

		
		
	pathPosArr.pop_front()


func setOrigin(node,origin):
	for c in  node.get_children():
		if "translation" in c:
			c.translation = node.translation
						
	node.translation = origin

func _physics_process(delta):
	
	
	pathFollow.offset += delta*100*scaleFactor
	
	translation = pathFollow.translation
	
	for i in triggers:
		if pathFollow.translation.distance_to(i["position"]) < 10:
			get_tree().call_group(i["name"],"activate")
			triggers.erase(i)
			

	for n in targetNodes:
		n.translation = pathFollow.translation
		n.rotation = pathFollow.rotation - Vector3(0,initialRot,0)
	


	if moveSound != null:
		if !moveSound.playing:
			if moveSound.stream != null:
				moveSound.stream.loop_mode = AudioStreamSample.LOOP_FORWARD

				moveSound.unit_db = 10
				moveSound.play()


