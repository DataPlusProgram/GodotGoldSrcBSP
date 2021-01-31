tool
extends Node

var scaleFactor = 0.05
#var renderModeFaces = []
var cornerPaths = {}
var trackPaths = {}

const DOORSOUNDS = {
	1: "doormove1.wav",
	2: "doormove2.wav",
	3: "doormove3.wav",
	4: "doormove4.wav",
	5: "doormove5.wav",
	6: "doormove6.wav",
	7: "doormove7.wav",
	8: "doormove8.wav",
	9: "doormove9.wav",
	10: "doormove10.wav"
}


const LOCKSOUNDS = {
	2: "button2.wav",
	8: "button8.wav",
	10: "button10.wav",
	11: "button11.wav",
	12: "latchlocked1.wav",
}

const BUTTONSOUNDS = {
	1: "button1.wav",
	2: "button2.wav",
	3: "button3.wav",
	4: "button4.wav",
	5: "button5.wav",
	6: "button6.wav",
	7: "button7.wav",
	8: "button8.wav",
	9: "button9.wav",
	10:"button10.wav",
	11:"button11.wav",
	14:"lightswitch2.wav"
}


enum RENDERMODE {
	color = 1
	texture = 2
	glow = 3
	solid = 4
	additive = 5
}

func _ready():
	
	set_meta("hidden",true)
	scaleFactor = get_parent().scaleFactor

func parseEntityData(entityDict,wadDict):
	
	if entityDict.has("WAD"):
		allWADparse(entityDict["WAD"],wadDict)
		
	elif entityDict.has("CLASSNAME"):
		var className = entityDict["CLASSNAME"]
		
		
		if entityDict.has("RENDERMODE"):
			parseRenderMode(entityDict)
		
		
		if className == "INFO_PLAYER_START":
			if get_parent().playerSpawnSet == true:
				return
			
			var info = parseInfoPlayerStart(entityDict)
			
			get_parent().playerSpawnSet = true
			if info!= null:
				get_parent().playerSpawn = info
		
		
		
		elif className == "LIGHT":
			if get_parent().lights:
				parseLight(entityDict)
		
		elif className == "FUNC_DOOR":
			get_parent().postFuncBrushes.append(entityDict)
		
		elif className == "FUNC_BUTTON":
			get_parent().postFuncBrushes.append(entityDict)
			
		elif className == "FUNC_WALL":
			get_parent().postFuncBrushes.append(entityDict)
		
		elif className == "FUNC_DOOR_ROTATING":
			get_parent().postFuncBrushes.append(entityDict)
		
		elif className == "INFODECAL":
			parseDecal(entityDict)
	
		elif className == "TRIGGER_ONCE":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "TRIGGER_MULTIPLE":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "TRIGGER_AUTO":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "TRIGGER_TRANSITION":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "TRIGGER_AUTOSAVE":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "FUNC_BREAKABLE":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "TRIGGER_TELEPORT":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "TRIGGER_HURT":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "FUNC_PUSHABLE":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "FUNC_ROTATING":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "MULTI_MANAGER":
			get_parent().postPostFuncBrushes.append(entityDict)
		elif className == "PATH_CORNER":
			parsePathCorner(entityDict)
		elif className == "FUNC_TRAIN":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "FUNC_TRACKTRAIN":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "PATH_TRACK":
			parsePathTrack(entityDict)
		elif className == "FUNC_ILLUSIONARY":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "TRIGGER_CHANGELEVEL":
			get_parent().postFuncBrushes.append(entityDict)
			#parseTriggerChangeLevel(entityDict)
		elif className == "AMBIENT_GENERIC":
			parseAmbientGeneric(entityDict)
		elif className == "FUNC_LADDER":
			parseTriggerTransition(entityDict)
		
		


func allWADparse(data,wadDict):
	data+=("DECALS.WAD")
	data = data.replace("\\QUIVER\\VALVE\\","")
	var baseDir = wadDict["baseDirectory"]
	var wadList = data.split(";",false)
	for i in wadList:
		i = i.replace("\\","/")
		i = i.substr(i.find_last("/")+1)
		var parsedWad = WADparse(baseDir + i.to_lower())
		if parsedWad != null:
			wadDict[i] = parsedWad


func WADparse(path):
	var file = load("res://addons/gldsrcBSP/DFile.gd").new()
	
	if file.loadFile(path) == false:
		print("wad not found:",path)
		return null
	var imageDict = {}
	var magic = file.get_String(4)
	var numDirectories = file.get_32()
	var directoriesOffset = file.get_32()
	
	file.seek(directoriesOffset)
	
	var allOffsets = []
	var textures = []
	for d in numDirectories:
		var offset = file.get_32()
		#var pos = file.pos
		#var textureParsed = parseFile(file,offset)
		#if textureParsed != null:
		#	textures.append(textureParsed)
		var prepos = file.pos
		var parsedFile = parseFile(file,offset)
		parsedFile["name"]
		imageDict[parsedFile["name"]] = parsedFile

	return(imageDict)
	
	
func parseFile(file,offset):
	var fileDict = {}
	fileDict["offset"] = offset
	fileDict["diskSize"] = file.get_32()
	fileDict["size"] = file.get_32()
	var type = file.get_8()
	fileDict["type"] = type
	fileDict["compression"] = file.get_8()
	fileDict["file"] = file
	file.get_16()#padding
	fileDict["name"] = file.get_String(16)
	return(fileDict)
	#if type != 0x43:
	#	return null
		
	#return parseTexture(file,fileDict["offset"],fileDict["size"])

func parseInfoPlayerStart(dict):
	var retDict = {}
	
	retDict["position"] = textToVector3(dict["ORIGIN"])#Vector3(x,y,z)*scaleFactor
	var pos = retDict["position"]
	if !dict.has("ANGLES") and !dict.has("ANGLES"):#lets just do player 1 for now
		retDict["rotation"] = Vector3.ZERO
		
	if dict.has("ANGLES"):
		retDict["rotation"] = textToVector3(dict["ANGLES"])#= Vector3(rx,ry,rz)*scaleFactor
	
	if dict.has("ANGLE"):
		var rotationTXT = dict["ANGLE"]
		var rot = float(rotationTXT)
		#retDict["rotation"] = Vector3(cos(rot),0,sin(rot))*scaleFactor
		retDict["rotation"] = Vector3(0,rot,0)
		

	return retDict

func parseLight(dict):
	var pos = textToVector3(dict["ORIGIN"])
	var text = dict["_LIGHT"]
	var axis = text.split(" ")
	var r = 1
	var g = 1
	var b = 1
	var a = 1

	
	if axis.size() > 1:
		r = int(axis[0])/255.0
		g = int(axis[1])/255.0
		b = int(axis[2])/255.0
		a = 1
	if axis.size() >3:
		a = int(axis[3])/255.0
	
		
	var brush
	var light = OmniLight.new()
	
	if dict.has("SPAWNFLAGS"):
		light.visible = false
	
	if dict.has("TARGETNAME"):
		light.add_to_group(dict["TARGETNAME"])
	
	light.light_color = Color(r,g,b)
	light.translation = pos
	light.omni_range = scaleFactor * get_parent().lightRangeMultiplier
	light.light_indirect_energy = 100*scaleFactor * get_parent().lightEnergyMultiplier
	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/light.gd")
	light.set_script(scriptRes)
	get_parent().lightNodes.add_child(light)
	
	

	
func textToVector3(text):
	var axis = text.split(" ")
	var rx = float(axis[0])
	var ry = float(axis[1])
	var rz = float(axis[2])
	
	return Vector3(-rx,rz,ry)*scaleFactor


func textToVector3i(text):
	var axis = text.split(" ")
	var rx = int(axis[0])
	var ry = int(axis[1])
	var rz = int(axis[2])
	
	return Vector3(-rx,rz,ry)*scaleFactor
	
func textToVector4i(text):
	var axis = text.split(" ")
	var rx = int(axis[0])
	var ry = int(axis[1])
	var rz = int(axis[2])
	var ri = int(axis[3])
	
	return Vector3(-rx,rz,ry)*scaleFactor

func sortEntityBrushesIntoNodes(dict):
	for brush in dict:
		if brush["faceArr"].size() > 6:
	#		print("brush model with more than 6 faces found")
			continue
			

		var targetFaces = brush["faceArr"]
		var faceMeshNodes = get_parent().faceMeshNodes
		var targetFaceNodes = [] 
		
		for f in targetFaces:
			if f > faceMeshNodes.size():
				continue
			
			targetFaceNodes.append(faceMeshNodes[f])
			
		
		var brushNode = Spatial.new()
		brush["node"] = brushNode
		for i in targetFaceNodes:
			var target = i.get_parent()
			target.get_parent().remove_child(target)
			brushNode.add_child(target)
			get_parent().brushNodes.add_child(brushNode)
			
		
		

	

func getModelInfoFromDict(dict):
	
	var modelIndexTxt = dict["MODEL"]
	modelIndexTxt = modelIndexTxt.trim_prefix("*")
	var modelIndex = int(modelIndexTxt)
	
	var bushModelInfo = get_parent().brushModels[modelIndex]
	
	return bushModelInfo
	
func parseDoor(dict):
	
	var faceMeshNodes = get_parent().faceMeshNodes
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"]
	var targetNodeArr = []
	
	var BBMin = bushModelInfo["BBMin"]
	var BBMax = bushModelInfo["BBMax"]
	var moveSound = 0
	var lockedSound = 0
	
	if dict.has("MOVESND"): moveSound = int(dict["MOVESND"])
	if dict.has("LOCKED_SOUND"): lockedSound = int(dict["LOCKED_SOUND"])
	
	#print(targetFaces)
	for i in targetFaces:
		if faceMeshNodes.has(i):
			#print(i)
			#print(faceMeshNodes[i].get_parent().name)
			if faceMeshNodes[i] != null:
				targetNodeArr.append(faceMeshNodes[i].get_parent().name)
	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_door.gd")
	var doorComponent = Spatial.new()
	
	doorComponent.set_meta("targetNodePaths",targetNodeArr)
	doorComponent.set_meta("scaleFactor",scaleFactor)
	
	
	if dict.has("TARGETNAME"):
		doorComponent.add_to_group(dict["TARGETNAME"])
		doorComponent.set_meta("locked",1)
	
	if dict.has("TARGET"):
		doorComponent.set_meta("target",dict["TARGET"])
	
	var dimAbs = BBMax - BBMin
	doorComponent.translate(BBMin + 0.5*dimAbs)

	doorComponent.set_meta("dim",Vector3(dimAbs.x,dimAbs.y,dimAbs.z))
	if dict.has("LIP"):
		doorComponent.set_meta("lip", int(dict["LIP"]) *scaleFactor)

	if dict.has("ANGLES"):
		var angs = textToVector3(dict["ANGLES"])
		doorComponent.set_meta("angles",angs/scaleFactor)

	if dict.has("ANGLE"):
		var angle = float(dict["ANGLE"])
		if angle ==-1:
			angle = Vector3.UP
			
		elif angle == -2:
			angle = Vector3.DOWN
		else:
			angle = Vector3(-cos(deg2rad(angle)),0,sin(deg2rad(angle)))

		
		doorComponent.set_meta("angle",angle)
		
	
	if moveSound != 0:
		var audioPlayer = get_parent().createAudioPlayer3DfromName("doors/"+ DOORSOUNDS[moveSound])
		audioPlayer.name = "moveSound"
		doorComponent.add_child(audioPlayer)
	
	if lockedSound != 0:
		var audioPlayer = get_parent().createAudioPlayer3DfromName("buttons/"+ LOCKSOUNDS[lockedSound])
		audioPlayer.name = "lockedSound"
		doorComponent.add_child(audioPlayer)
	
	if dict.has("SPEED"):
		doorComponent.set_meta("speed",float(dict["SPEED"]))
	doorComponent.add_child(createInteractionAreaNode(bushModelInfo,3))
	doorComponent.set_script(scriptRes)
	get_parent().get_node("BrushEntities").add_child(doorComponent)


func parseBreakable(dict):
	
	var faceMeshNodes = get_parent().faceMeshNodes
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"]
	var targetNodeArr = []
	
	
	for i in targetFaces:
		if i > faceMeshNodes.size():
			continue
		targetNodeArr.append(faceMeshNodes[i].get_parent().name)
	
		var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_breakable.gd")
		var breakableNode = Node.new()
		breakableNode.name = "func_breakable"
		breakableNode.set_script(scriptRes)
		get_parent().get_node("BrushEntities").add_child(breakableNode)
		
	#breakpoint

func parseButton(dict):
	
	var target = null
	
	if dict.has("TARGET"):
		target = dict["TARGET"]
	
	
	var sound = 0
	
	var bushModelInfo = getModelInfoFromDict(dict)
	

	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_button.gd")
	
	
	var interactionAreaNode = createInteractionAreaNode(bushModelInfo,3)
	
	if dict.has("SOUNDS"):
		if dict["SOUNDS"] != "0":
			sound = int(dict["SOUNDS"])
			if !BUTTONSOUNDS.has(sound):
				return
			var audioPlayer = get_parent().createAudioPlayer3DfromName("buttons/"+ BUTTONSOUNDS[sound])
			audioPlayer.name = "sound"
			interactionAreaNode.add_child(audioPlayer)
	
	interactionAreaNode.translation =(bushModelInfo["BBMin"] + 0.5*(bushModelInfo["BBMax"]-bushModelInfo["BBMin"]))
	interactionAreaNode.name = "func_button"
	interactionAreaNode.set_meta("target",target)
	interactionAreaNode.set_script(scriptRes)
	get_parent().get_node("BrushEntities").add_child(interactionAreaNode)



func parsePushable(dict):
	return
	var faceMeshNodes = get_parent().faceMeshNodes
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"] 
	var rigidBody = RigidBody.new()
	
	for i in targetFaces: #for every static body of model
		if faceMeshNodes.has(i):
			
			var meshNode : MeshInstance = faceMeshNodes[i]
			var bodyNode = meshNode.get_parent()
			
			#bodyNode.remove_child(meshNode)#we remove mesh from StaticBody
			var pos = bodyNode.translation
			for c in bodyNode.get_children():
				c.get_parent().remove_child(c)
				if c.get_class() != "MeshInstance":
					queue_free()
			bodyNode.queue_free()
			rigidBody.add_child(meshNode)#we add mesh to rigidBody
			meshNode.create_convex_collision()
			
			var collisionShape = meshNode.get_child(0).get_child(0)
			collisionShape.get_parent().remove_child(collisionShape)
			rigidBody.add_child(collisionShape)
			
			if get_parent().physicsPropsDontRotate:
				rigidBody.axis_lock_angular_x = true
				rigidBody.axis_lock_angular_y = true
				rigidBody.axis_lock_angular_z = true
			
			rigidBody.translation = pos
			rigidBody.gravity_scale = 10
			get_parent().add_child(rigidBody)
			#print(staticBody.name)
			#for c in staticBody.get_children():
			#	continue
				#print(c.name)
			#if(c.get_class() == "CollisionShape"):
			#	c.queue_free()
			#else:
				#c.get_parent().remove_child(c)
				#rigidBody.add_child(c)
		
		
			#pstaticBody.get_parent().remove_child(staticBody)
		
	#var collisionNode = CollisionShape.new()
	#var collisionShape = BoxShape.new()
	#collisionShape.extents = bushModelInfo["BBabs"]
	#collisionNode.shape = collisionShape
#	rigidBody.mode = RigidBody.MODE_KINEMATIC
	rigidBody.translation.y += scaleFactor
	rigidBody.name = "func_pushable"
	#get_parent().add_child(rigidBody)

func parseDoorRotating(dict):
	var faceMeshNodes = get_parent().faceMeshNodes
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"]
	var targetNodeArr = []
	var rotAmount = int(dict["DISTANCE"])
	var BBMin = (bushModelInfo["BBMin"])
	var BBMax = (bushModelInfo["BBMax"])
	var origin = Vector3.ZERO
	var axis = Vector3(0,1,0)
	var initialRot = Vector3(0,0,0)
	
	#print("door target face:", targetFaces)
	var moveSound = 0
	if dict.has("MOVESND"):
		moveSound = int(dict["MOVESND"])
	
	if dict.has("SPAWNFLAGS"):
		var flags = int(dict["SPAWNFLAGS"])
		if (flags & (1 << 6)) > 0 or (flags & (1 << 7)) > 0:
			axis = Vector3.ZERO
		
		if(flags & (1 << 6 )) > 0:
			initialRot = Vector3(90,0,0)
			axis += Vector3(1,0,0)
		
		if(flags & (1 << 7)) > 0:
			initialRot = Vector3(0,0,90)
			axis += Vector3(0,0,-1)
		
		
		if !dict.has("ORIGIN"):
			#print("func_door_rotating has no origin skipping...")
			return
		origin = textToVector3(dict["ORIGIN"])
	
	
	
	bushModelInfo["BBMax"]
	#print(targetFaces)
	for i in targetFaces:
		if faceMeshNodes.has(i):
			setOrigin(faceMeshNodes[i].get_parent(),origin)
			targetNodeArr.append(faceMeshNodes[i].get_parent().name)
	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_door_rotating.gd")
	var doorComponent = Spatial.new()
	var uniqueParents = getUniqeParents(targetNodeArr)
	
	
	if moveSound != 0:
		var audioPlayer = get_parent().createAudioPlayer3DfromName("doors/" + DOORSOUNDS[moveSound])
		audioPlayer.name = "moveSound"
		doorComponent.add_child(audioPlayer)
	
	doorComponent.set_meta("targetNodePaths",targetNodeArr)
	doorComponent.set_meta("scaleFactor",scaleFactor)
	doorComponent.set_meta("origin",origin)
	doorComponent.set_meta("rotAmount",rotAmount)
	doorComponent.set_meta("initialRot",initialRot)
	doorComponent.set_meta("axis",axis)
	if dict.has("TARGETNAME"):
		doorComponent.add_to_group(dict["TARGETNAME"])
	
	var dimAbs = BBMax - BBMin
	doorComponent.translate(BBMin + 0.5*dimAbs)

	doorComponent.set_meta("dim",Vector3(dimAbs.x,dimAbs.y,dimAbs.z))
	if dict.has("LIP"):
		doorComponent.set_meta("lip", int(dict["LIP"]) *scaleFactor)

	if dict.has("ANGLES"):
		var angs = textToVector3i(dict["ANGLES"])
		
		doorComponent.set_meta("angles",angs/scaleFactor)
	var interactionAreaNode = createInteractionAreaNode(bushModelInfo,3)
	interactionAreaNode.translation = origin
	doorComponent.add_child(interactionAreaNode)
	doorComponent.set_script(scriptRes)
	get_parent().get_node("BrushEntities").add_child(doorComponent)
	

func parseRotating(dict):
	
	var faceMeshNodes = get_parent().faceMeshNodes
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"]
	var targetNodeArr = []
	var BBMin = (bushModelInfo["BBMin"])
	var BBMax = (bushModelInfo["BBMax"])
	var origin = Vector3.ZERO
	var flags = int(dict["SPAWNFLAGS"])
	var axis = Vector3(0,1,0)
	
	if (flags & (1 << 2)) > 0 or (flags & (1 << 3)) > 0:
		axis = Vector3.ZERO
	
	if(flags & (1 << 2 )) > 0:
		axis += Vector3(1,0,0)
	
	if(flags & (1 << 3)) > 0:
		axis += Vector3(0,0,1)

	if !dict.has("ORIGIN"):
		print("func_door_rotating has no origin skipping...")
		return
	origin = textToVector3(dict["ORIGIN"])
	
	
	bushModelInfo["BBMax"]
	for i in targetFaces:
		if faceMeshNodes.has(i):
			setOrigin(faceMeshNodes[i].get_parent(),origin)

			targetNodeArr.append(faceMeshNodes[i].get_parent().name)
			
	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_rotating.gd")
	var doorComponent = Spatial.new()
	var uniqueParents = getUniqeParents(targetNodeArr)
	
	doorComponent.set_meta("targetNodePaths",targetNodeArr)
	doorComponent.set_meta("scaleFactor",scaleFactor)
	doorComponent.set_meta("origin",origin)
	doorComponent.set_meta("axis",axis)
	var dimAbs = BBMax - BBMin
	doorComponent.translate(BBMin + 0.5*dimAbs)

	doorComponent.set_meta("dim",Vector3(dimAbs.x,dimAbs.y,dimAbs.z))


	doorComponent.set_script(scriptRes)
	get_parent().get_node("BrushEntities").add_child(doorComponent)







func setOrigin(node,origin):
	for c in  node.get_children():
		if "translation" in c:
			c.translation = node.translation
						
	node.translation = origin
	

func parseWall(dict):
	pass
	#var faceMeshNodes = get_parent().faceMeshNodes
	#var bushModelInfo = getModelInfoFromDict(dict)
	#var targetFaces = bushModelInfo["faceArr"]
	#var targetNodeArr = []
	
	#var amount = dict["RENDERAMT"]
	
	#for i in targetFaces:
		#targetNodeArr.append(faceMeshNodes[i])
	#	var meshNode =  faceMeshNodes[i]
	#	var mat = SpatialMaterial.new() godot glitch
		
func parseDecal(dict):
	
	var sprite = Sprite3D.new()
	var texture = get_parent().fetchTexture(dict["TEXTURE"],true)
	sprite.name = dict["TEXTURE"]
	#var textureInfo = get_parent().textureInfo
	#get_parent().imageBuilder.createImage(textureInfo[dict["TEXTURE"]])
	#var shape = CollisionShape2D.new()
	#var shapeRes = BoxShape.new()
	#shapeRes.extents *= scaleFactor
	get_parent().imageBuilder.createImageFromName(dict["TEXTURE"])
	#shape.shape = shapeRes
	#area.add_child(shape)
#	var space = World.direct_space_state
	sprite.texture = texture
	sprite.translation = textToVector3(dict["ORIGIN"])
	
	get_parent().get_node("decals").add_child(sprite)
	#breakpoint

func parseTriggerOnce(dict):
	var modelInfo = getModelInfoFromDict(dict)
	

	
	var dimAbs = modelInfo["BBMax"] - modelInfo["BBMin"]
	dimAbs = Vector3(abs(dimAbs.x),abs(dimAbs.y),abs(dimAbs.z))
	var interactionBox = createInteractionAreaNode(modelInfo)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5


	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/trigger.gd")
	
	if dict.has("TARGET"):
		interactionBox.set_meta("target",dict["TARGET"])
	
	interactionBox.set_meta("trigger_once",true)
	interactionBox.set_script(scriptRes)
	
	get_parent().get_node("triggers").add_child(interactionBox)
	deleteModelNode(modelInfo)

func parseTriggerMultiple(dict):
	
	var modelInfo = getModelInfoFromDict(dict)
	

	
	var dimAbs = modelInfo["BBMax"] - modelInfo["BBMin"]
	dimAbs = Vector3(abs(dimAbs.x),abs(dimAbs.y),abs(dimAbs.z))
	var interactionBox = createInteractionAreaNode(modelInfo)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5


	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/trigger.gd")
	
	if dict.has("TARGET"):
		interactionBox.set_meta("target",dict["TARGET"])
	
	interactionBox.set_meta("trigger_once",false)
	interactionBox.set_script(scriptRes)
	
	get_parent().get_node("triggers").add_child(interactionBox)
	deleteModelNode(modelInfo)


func parseTriggerTransition(dict):
	
	var modelInfo = getModelInfoFromDict(dict)
	var interactionBox = createInteractionAreaNode(modelInfo)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5
	
	
	get_parent().get_node("triggers").add_child(interactionBox)
	deleteModelNode(modelInfo)


func parseTriggerChangeLevel(dict):
	
	var modelInfo = getModelInfoFromDict(dict)
	var interactionBox = createInteractionAreaNode(modelInfo)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5
	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/trigger_changelevel.gd")
	interactionBox.set_meta("mapName",dict["MAP"])
	interactionBox.set_script(scriptRes)
	get_parent().get_node("triggers").add_child(interactionBox)
	
	deleteModelNode(modelInfo)

func parseTriggerAuto(dict):
	

	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/trigger_auto.gd")

	
	
	var node = Node.new()
	
	if dict.has("TARGET"):
		node.set_meta("target",dict["TARGET"])
	
	node.name = "trigger_auto"
	node.set_meta("delay",dict["DELAY"])
	node.set_script(scriptRes)
	get_parent().get_node("triggers").add_child(node)

func parseTriggerAutoSave(dict):
	
	var modelInfo = getModelInfoFromDict(dict)
	var interactionBox = createInteractionAreaNode(modelInfo)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5
	
	
	get_parent().get_node("triggers").add_child(interactionBox)
	deleteModelNode(modelInfo)


	
func getUniqeParents(targetNodes):
	var uniqueParents = []
	for i in targetNodes:
		var parent = get_parent().get_path()
		if !uniqueParents.has(parent):
			uniqueParents.append(parent)
			
	return uniqueParents


func createInteractionAreaNode(model,growMargin = 0,nameStr ="interactionBox"):
	var areaNode = Area.new()
	var collisionNode = CollisionShape.new()
	var shapeNode = BoxShape.new()
	
	var BBMin = model["BBMin"]
	var BBMax = model["BBMax"]
	
	var dim = BBMax - BBMin
	dim/=2
	dim = Vector3(abs(dim.x),abs(dim.y),abs(dim.z))
	dim += Vector3(1,1,1)*scaleFactor*growMargin#box will be x units larger than object in all dimensions

	shapeNode.extents = dim
	collisionNode.shape = shapeNode
	areaNode.add_child(collisionNode)
	areaNode.name = nameStr

	return areaNode

		

func doRenderModes():
	if get_parent().disableTextures:
		return
		
	var renderModeFaces= get_parent().renderModeFaces
	for i in renderModeFaces:
		var faces = getModelInfoFromDict(i)["faceArr"]
		
		
		for f in faces:
			if get_parent().faceIndexToMaterialMap.has(f):
				var mat = get_parent().faceIndexToMaterialMap[f].duplicate()
				if i["RENDERAMT"] < 1:
					
					mat.flags_transparent = true
					mat.albedo_color.a = i["RENDERAMT"]
				var testM = get_parent().faceMeshNodes[f]
				testM.set_surface_material(0,mat)
			#breakpoint
			

	
func parseRenderMode(dict):
	
	if dict["CLASSNAME"] == "LIGHT":
		print("unimplimented light render mode")
		return
	
	var mode = int(dict["RENDERMODE"])
	
	if dict["CLASSNAME"] == "ENV_RENDER":
		return
	
	if mode == 0:
		return
	if mode != RENDERMODE.solid:
		if !dict.has("MODEL"):
			return
		
		
		var model = dict["MODEL"]
		model = model.trim_prefix("*")
		
		
		if !model.is_valid_integer():
			return
		
		var amount = 255
		var color = 0
		if dict.has("RENDERAMT"):
			amount = int(dict["RENDERAMT"])/255.0

		
		if dict.has("RENDERCOLOR"):
			if dict["RENDERCOLOR"] != "0":
				color = textToVector3i(dict["RENDERCOLOR"])/255
		
		get_parent().renderModeFaces.append({"MODEL":model,"RENDERAMT":amount})
		get_parent().modelRenderModes[model] = {"renderMode":mode,"amount":amount}

func parseMultiManager(dict):
	var targetGroups = []
	for i in dict.keys():
		if i != "TARGETNAME" and i != "CLASSNAME" and i!= "ORIGIN":
			targetGroups.append(i)
	

	var node = Node.new()
	
	
	if dict.has("TARGETNAME"):
		node.add_to_group(dict["TARGETNAME"])
	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/multi_manager.gd")
	node.name = dict["TARGETNAME"]
	node.set_meta("targetGroups",targetGroups)
	node.set_script(scriptRes)
	get_parent().get_node("triggers").add_child(node)
	

func parsePathCorner(dict):
	var node = Position3D.new()
	node.translation = textToVector3(dict["ORIGIN"])
	node.name = dict["TARGETNAME"]
	if dict.has("TARGET"):
		node.set_meta("target",dict["TARGET"])
		cornerPaths[node.name] = dict["TARGET"]
	else:
		cornerPaths[node.name] = null
	
	get_parent().add_child(node)

func parsePathTrack(dict):
	var node = Position3D.new()
	node.translation = textToVector3(dict["ORIGIN"])
	node.name = dict["TARGETNAME"]
	if dict.has("TARGET"):
		node.set_meta("target",dict["TARGET"])
		trackPaths[node.name] = dict["TARGET"]
	else:
		trackPaths[node.name] = null
	
	get_parent().add_child(node)


func parseTrain(dict):
	var faceMeshNodes = get_parent().faceMeshNodes
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"]
	var targetNodeArr = []
	var pathArr = []
	if !dict.has("TARGET"):#if train dosen't have a traget corner it won't move so nothing needs to happen
		return
	
	var a = dict["TARGET"]
	while(a != null):
		
		if !cornerPaths.has(a):
			return
		
		var b = cornerPaths[a]
		pathArr.append(a)
		a = b
		
		if cornerPaths.size()>1:
			if b == pathArr[0]:#the loop has been closed
				break
	


	for i in targetFaces:
		if faceMeshNodes.has(i):
			targetNodeArr.append(faceMeshNodes[i].get_parent().name)
	
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_train.gd")
	var trainNode= Spatial.new()

	trainNode.set_meta("targetNodePaths",targetNodeArr)
	trainNode.set_meta("path",pathArr)
	trainNode.set_script(scriptRes)

	get_parent().add_child(trainNode)
	
	
	
func parseTrackTrain(dict):
	var pathArr = []
	var faceMeshNodes = get_parent().faceMeshNodes
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"]
	var targetNodeArr = []
	var origin = Vector3.ZERO
	
	origin = textToVector3(dict["ORIGIN"])
	

	for i in targetFaces:
		if faceMeshNodes.has(i):
			setOrigin(faceMeshNodes[i].get_parent(),origin)

			targetNodeArr.append(faceMeshNodes[i].get_parent().name)
			
	if !dict.has("TARGET"):#if train dosen't have a traget corner it won't move so nothing needs to happen
		return
	
	var a = dict["TARGET"]
	
	if !trackPaths.has(a):
		print("track not found for train:",a)
		return
	
	while(a != null):
		var b = trackPaths[a]
		pathArr.append(a)
		a = b
		
		if !trackPaths.has(a):
			print("couldn't find:", a)
			break
		
		if trackPaths.size()>1:
			if b == pathArr[0]:#the loop has been closed
			
				break
				
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_track_train.gd")
	var trainNode= Spatial.new()

	trainNode.set_meta("targetNodePaths",targetNodeArr)
	trainNode.set_meta("path",pathArr)
	trainNode.set_script(scriptRes)

	get_parent().add_child(trainNode)

func parseAmbientGeneric(dict):
	var par = get_parent().get_node_or_null("Ambient Sounds")
	if par == null:
		par = Node.new()
		par.name = "Ambient Sounds"
		get_parent().add_child(par)
	

		
	

	var pos = textToVector3(dict["ORIGIN"])
	var audioNode = get_parent().createAudioPlayer3DfromName(dict["MESSAGE"].to_lower())
	var volume = int(dict["HEALTH"])
	#audioNode.unit_db = 0.5 * (volume/10.0)
	audioNode.max_db = 1
	if dict.has("TARGETNAME"):
		audioNode.add_to_group(dict["TARGETNAME"])
	
	audioNode.translation = pos
	audioNode.unit_size = 7 * (volume/10.0)

		
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/ambient_generic.gd")
	audioNode.set_script(scriptRes)
	audioNode.autoplay = true
	
	if dict.has("SPAWNFLAGS"):
		var flags = int(dict["SPAWNFLAGS"])
		
		if flags & (1 << 0) > 0:
			pass
			#print("play everywhere")
		if flags & (1 << 1) > 0:
			pass
			#print("small radius")
		
		if(flags & (1 << 2 )) > 0:
			pass
			#print("medium radius")
		
		if(flags & (1 << 3)) > 0:
			pass
			#print("large radius")
		
		if(flags & (1 << 4)) > 0:
			audioNode.autoplay = false
			
		if(flags & (1 << 5)) > 0:
			pass
			#print("not toggled")
	
	if dict.has("TARGETNAME"):
		audioNode.add_to_group(dict["TARGETNAME"])

	par.add_child(audioNode)

	#audioNode.stream.save_to_wav("test.wav")
	

func parseIllusionary():
	breakpoint

func deleteModelNode(modelInfo):
	var modelFaceIdxs = modelInfo["faceArr"]
	var deleted = false
	for faceIdx in modelFaceIdxs:
		if get_parent().faceMeshNodes.has(faceIdx):
			if get_parent().faceMeshNodes[faceIdx] != null:#whis is this nulled?
				get_parent().faceMeshNodes[faceIdx].get_parent().queue_free()
				deleted = true
			
			#if get_parent().faceMeshNodes[faceIdx] == null:
			#	breakpoint
				

