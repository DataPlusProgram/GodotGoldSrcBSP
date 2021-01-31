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
var destScaler = Vector3(0,0,0)
var destination = Vector3.ZERO
var speed = 300
var locked = false
var angle
var moveSound 
var lockedSound
var target = null
var open = false
func _ready():
	
	dim = get_meta("dim")#Vector3(dimX,dimY,dimZ)
	scaleFactor = get_meta("scaleFactor")
	if has_meta("lip"):  lip = get_meta("lip")
	if has_meta("locked"): locked = true
	var targetNodesPath = get_meta("targetNodePaths")
	
	moveSound = get_node_or_null("moveSound")
	lockedSound = get_node_or_null("lockedSound")
	
	if has_meta("target"):
		target = get_meta("target")
	
	for i in targetNodesPath:
		var gp= get_parent().get_parent()
		targetNodes.append(gp.get_node("Geometry").get_node(i))
	if has_meta("speed"):
		speed = get_meta("speed")*2
	#speed = get_meta("speed")*2

	if has_meta("angles"):
		rot = get_meta("angles")
		var yaw = deg2rad(rot.x)
		var pitch = deg2rad(rot.y)
		var roll = deg2rad(rot.z)
		
		dir.y = -cos(yaw)*sin(pitch)*sin(roll)-sin(yaw)*cos(roll)
		dir.x = -sin(yaw)*sin(pitch)*sin(roll)+cos(yaw)*cos(roll)
		dir.z = cos(pitch)*sin(roll)

		dir.y *= -1
		dir.x *= -1
		
		if abs(roll) >=0.01 and abs(yaw) >= 0.01:
			dir.y = -dir.z
			dir.z = 0
	
		LineDraw.drawLine(Vector3.ZERO,dir)
	
		if abs(dir.x) > 0.01: 
			destScaler.x = 1
		if abs(dir.y) > 0.01: 
			destScaler.y = 1
		if abs(dir.z) > 0.01: 
			destScaler.z = 1
		
		
		destination = (dim*destScaler) - (destScaler*lip)

		
	elif has_meta("angle"):
		angle = get_meta("angle")

		dir = angle
		destination = angle*dim

	

func _physics_process(delta):
	collisions()
	if !active:
		return


	#print(translation)
	if abs(inc.y) >= abs(destination.y):
		if abs(inc.x) >= abs(destination.x):
			if abs(inc.z) >= abs(destination.z):
					return
	
	
	for i in targetNodes:
		if abs(inc.x) < abs(destination.x): 
			i.translation.x += dir.x * 0.00015*speed
			inc.x += dir.x*0.00015*speed
	
		if abs(inc.y) < abs(destination.y): 
			i.translation.y += dir.y * 0.00015*speed
			inc.y += dir.y*0.00015*speed
		
		if abs(inc.z) < abs(destination.z): 
			i.translation.z += dir.z * 0.00015*speed
			inc.z += dir.z*0.00015*speed
			
	
	#inc += dir*0.00015*speed
	
	
	
func collisions():
	for c in get_node("interactionBox").get_overlapping_bodies():
		if c.is_in_group("hlTrigger"):
			open()
		

var flag = false

func open():
	#if open == true:
	#	return
		
#	open = true 
	
	
	if active == false and locked == false:
		active = true
		if target != null:
			for i in get_tree().get_nodes_in_group(target):
				i.activate()
		if moveSound != null:
			moveSound.play()
	
	elif locked == true:
		if lockedSound != null:
			if !lockedSound.playing:
				lockedSound.play()

func activate():
	locked = false
	
	
	if active == false: #and (locked == false and fromTrigger == false):
		active = true
		
		if target != null:
			for i in get_tree().get_nodes_in_group(target):
				i.activate()
		
		if moveSound != null:
			moveSound.play()
