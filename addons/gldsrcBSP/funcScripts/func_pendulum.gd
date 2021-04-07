extends Spatial


var active = true
var targetNodes = []
var scaleFactor 
var BBMax : Vector3
var BBMin  : Vector3
var dimX
var dimY
var dimZ
var dim
var inc = Vector3.ZERO
var lip = 0
var rot = Vector3(0,0,0)
var dir = Vector3.ZERO
var rotAmount = 90
var origin = Vector3.ZERO
var rotInc = 0
var axis = Vector3(0,1,0)
func _ready():
	
	dim = get_meta("dim")#Vector3(dimX,dimY,dimZ)
	origin = get_meta("origin")
	scaleFactor = get_meta("scaleFactor")
	axis = get_meta("axis")
	var targetNodesPath = get_meta("targetNodePaths")

	
	for i in targetNodesPath:
		var gp= get_parent().get_parent()
		targetNodes.append(gp.get_node("Geometry").get_node(i))


func _physics_process(delta):
	
	if !active:
		return
	
	for i in targetNodes:
		if axis.x == 1:
			i.rotation_degrees.x += 2
		if axis.y == 1:
			i.rotation_degrees.y += 2
			
		if axis.z == 1:
			i.rotation_degrees.z += 2
	

