extends Spatial


var active = false
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
var rotAmount = deg2rad(90)
var origin = Vector3.ZERO
var rotInc = 0
var locked = false
var local = {}
var axis = Vector3.ZERO
var moveSound
func _ready():
	
	dim = get_meta("dim")#Vector3(dimX,dimY,dimZ)
	origin = get_meta("origin")
	scaleFactor = get_meta("scaleFactor")
	rotAmount = deg2rad(get_meta("rotAmount"))
	moveSound = get_node_or_null("moveSound")
	axis = get_meta("axis")

	
	
	if has_meta("lip"):  lip = get_meta("lip")
	var targetNodesPath = get_meta("targetNodePaths")
	for i in targetNodesPath:
		var gp= get_parent().get_parent()
		targetNodes.append(gp.get_node("Geometry").get_node(i))
	if has_meta("angles"):
		rot = get_meta("angles")
		var yaw = deg2rad(rot.x)
		var pitch = deg2rad(rot.y)
		var roll = deg2rad(rot.z)
		
		dir.y = -cos(yaw)*sin(pitch)*sin(roll)-sin(yaw)*cos(roll)
		dir.x = -sin(yaw)*sin(pitch)*sin(roll)+cos(yaw)*cos(roll)
		dir.z =  cos(pitch)*sin(roll)
		
	
	var initialRot = get_meta("initialRot")

	
	for i in targetNodes:
		local[i] = i.translation-origin
		if initialRot.x >0: 
			i.rotation_degrees.x = -initialRot.x
			get_node("interactionBox").rotation_degrees.x = -initialRot.x
		if initialRot.y >0: 
			i.rotation_degrees.y = initialRot.y
			get_node("interactionBox").rotation_degrees.y = initialRot.y
		if initialRot.z >0: 
			i.rotation_degrees.z = initialRot.z
			get_node("interactionBox").rotation_degrees.z = initialRot.z
		#print(i.name)
		
		
	
		
#func rotateRoundPoint(node,point):
#	var x_axis = Vector3(1, 0, 0)
#	var pivot_radius = start_position - point
#	pivot_transform = Transform(transform.basis, point)
#	transform = pivot_transform.rotated(x_axis, delta).translated(point)

func _physics_process(delta):
	
	
	
	collisions()
	if !active:
		return
	#thetha = 0
	if rotInc < rotAmount:
		for i in targetNodes:

			if axis.x != 0: 
				i.rotation_degrees.x += axis.x
		
			if axis.y != 0: 
				i.rotation_degrees.y += axis.y
			
			if axis.z != 0:
				i.rotation_degrees.z += axis.z
			

			pass
		rotInc +=  deg2rad(1)
		get_node("interactionBox").translation = Vector3.ZERO
		
		if axis.x == 1: 
			get_node("interactionBox").rotation_degrees.x += 0.001
		
		if axis.y == 1: 
			get_node("interactionBox").rotation_degrees.y += 0.001
			
		if axis.z == 1:
			get_node("interactionBox").rotation_degrees.z += 0.001
	
		get_node("interactionBox").translation = origin
		#print(rotInc)


	

func collisions():
	for c in get_node("interactionBox").get_overlapping_bodies():
		if c.get_class() == "StaticBody":
			if !targetNodes.find(c.get_parent()):
				pass
				#print(c.name)
		
		if c.is_in_group("hlTrigger"):
			active = true


	
func activate():
	if active == false:#and locked == false:
		if moveSound:
			moveSound.play()
		active = true
