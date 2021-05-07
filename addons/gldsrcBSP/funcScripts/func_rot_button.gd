extends Area


var targetNodes = []
var targetName = ""
var sound 
var timer = null
var cooldown = false


var active = false
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
	targetName = get_meta("target")
	sound = get_node_or_null("sound")
	dim = get_meta("dim")#Vector3(dimX,dimY,dimZ)
	origin = get_meta("origin")
	scaleFactor = get_meta("scaleFactor")
	axis = get_meta("axis")
	var targetNodesPath = get_meta("targetNodePaths")

	
	for i in targetNodesPath:
		var gp= get_parent().get_parent()
		targetNodes.append(gp.get_node("Geometry").get_node(i))


func _physics_process(delta):
	
	for c in get_overlapping_bodies():
		if c.is_in_group("hlTrigger"):
			active = true
			activate()
	if !active:
		return
	
	for i in targetNodes:
		if abs(axis.x) == 1:
			i.rotation_degrees.x += axis.x*2
		if abs(axis.y) == 1:
			i.rotation_degrees.y += axis.y*2
			
		if abs(axis.z) == 1:
			i.rotation_degrees.z += axis.z*2

	
func toggle(state):
	activate()

func activate():
	
	for i in get_tree().get_nodes_in_group(targetName):
		if "locked" in i:
			i.locked = false
		i.activate()

func coolDownOver():
	cooldown = false
	timer.queue_free()
	timer = null
