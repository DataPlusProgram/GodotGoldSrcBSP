extends Spatial


var active = false
var targetNodes = []
var scaleFactor 
var inc = Vector3.ZERO
var lip = 0
var rot = Vector3(0,0,0)
var dir = Vector3.ZERO
var rotAmount = deg2rad(90)
var origin = Vector3.ZERO
var rotDir = 1
var rotInc = 0
var locked = false
var local = {}
var axis = Vector3.ZERO
var moveSound
func _ready():
	
	origin = get_meta("origin")
	scaleFactor = get_meta("scaleFactor")
	rotAmount = deg2rad(get_meta("rotAmount"))
	moveSound = get_node_or_null("moveSound")
	axis = get_meta("axis")

	if has_meta("rotDir"):
		rotDir = get_meta("rotDir")
	
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

func _physics_process(delta):
	
	collisions()
	if !active:
		return
	#thetha = 0
	if rotInc < rotAmount:
		for i in targetNodes:

			if axis.x != 0: 
				i.rotation_degrees.x += axis.x* rotDir
		
			if axis.y != 0: 
				i.rotation_degrees.y += axis.y* rotDir
			
			if axis.z != 0:
				i.rotation_degrees.z += axis.z* rotDir
			

			pass
		rotInc +=  deg2rad(1)
		get_node("interactionBox").translation = Vector3.ZERO
		
		if axis.x == 1: 
			get_node("interactionBox").rotation_degrees.x += 0.001* rotDir
		
		if axis.y == 1: 
			get_node("interactionBox").rotation_degrees.y += 0.001* rotDir
			
		if axis.z == 1:
			get_node("interactionBox").rotation_degrees.z += 0.001 * rotDir
	
		get_node("interactionBox").translation = origin



	

func collisions():
	for c in get_node("interactionBox").get_overlapping_bodies():
		if c.get_class() == "StaticBody":
			if !targetNodes.find(c.get_parent()):
				pass

		
		if c.is_in_group("hlTrigger"):
			active = true
			if moveSound:
				moveSound.play()


func setState(state):
	toggle()

func toggle():
	if active == false:#and locked == false:
		if moveSound:
			moveSound.play()
		active = true
