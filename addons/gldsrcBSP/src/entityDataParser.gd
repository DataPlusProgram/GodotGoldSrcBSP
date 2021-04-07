tool
extends Node

var scaleFactor = 0.05
#var renderModeFaces = []
var cornerPaths = {}
var trackPaths = {}

const MATERIAL = {
	0: ["glass","bustglass1"],
	1: ["wood","wood1"],
	2: "metal",
	3: "flesh",
	4: "cinder block",
	5: "ceiling tile",
	6: "computer",
	7: "unbreakable glass",
	8: "rock"
}

const CDAUDIO = {
	2: "Half-Life01.mp3",
	3: "Prospero01.mp3",
	4: "Half-Life12.mp3",
	5: "Half-Life07.mp3",
	6: "Half-Life10.mp3",
	7: "Suspense01.mp3",
	8: "Suspense03.mp3",
	9: "Half-Life09.mp3",
	10:"Half-Life02.mp3",
	11:"Half-Life13.mp3",
	12:"Half-Life04.mp3",
}

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

const TRAINSOUNDS = {
	1 : "plats/ttrain1.wav",
	2 : "plats/ttrain2.wav",
	3 : "plats/ttrain3.wav",
	4 : "plats/ttrain4.wav",
	5 : "plats/ttrain5.wav",
	6 : "plats/ttrain6.wav",
	7 : "plats/ttrain7.wav"
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
		allWADparse(entityDict,wadDict)
		
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
		
		
		if get_parent().lights:
			if className == "LIGHT":
				parseLight(entityDict)
			elif className == "LIGHT_SPOT":
				parseLightSpot(entityDict)
		
		
		
		if className == "FUNC_DOOR":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "FUNC_BUTTON":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "FUNC_ROT_BUTTON":
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
		elif className == "TRIGGER_PUSH":
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
			parseLadder(entityDict)
		elif className == "TRIGGER_CDAUDIO":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "FUNC_PENDULUM":
			get_parent().postFuncBrushes.append(entityDict)
		elif className == "ITEM_SUIT":
			parseModel(entityDict,"w_suit.mdl")
		elif className == "AMMO_357":
			parseModel(entityDict,"w_357ammobox.mdl")
		
			
		

		
		
		


func allWADparse(entityDict,wadDict):
	var data = entityDict["WAD"]
	#data+=("DECALS.WAD")
	data = data.replace("\\QUIVER\\VALVE\\","")
	var baseDir = wadDict["baseDirectory"]
	var wadList = data.split(";",false)
	for i in wadList:
		i = i.replace("\\","/")
		i = i.substr(i.find_last("/")+1)
		var parsedWad = WADparse(baseDir + i.to_lower())
		if parsedWad != null:
			wadDict[i] = parsedWad
			
	if entityDict.has("SKYNAME"):
		get_parent().skyTexture = wadDict["baseDirectory"]+ "gfx/env/" +entityDict["SKYNAME"].to_lower()


func WADparse(path):
	var file = load("res://addons/gldsrcBSP/DFile.gd").new()
	
	
	if file.loadFile(path) == false:
		var split = path.split("/")
		if split[split.size()-1] == "halflife.wad":#we are looking for halflife.wad
			var guessPath = guessWadPath(path)
			if file.loadFile(guessPath) == false:
				print("halflife.wad not found")
				return null
		else:
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
#	light.light_energy = 5
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/light.gd")
	light.set_script(scriptRes)
	get_parent().lightNodes.add_child(light)
	
	
func parseLightSpot(dict):
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
	var light = SpotLight.new()
	
	if dict.has("SPAWNFLAGS"):
		light.visible = false
	
	if dict.has("TARGETNAME"):
		light.add_to_group(dict["TARGETNAME"])
	var pitch = 0 
	if dict.has("PITCH"):
		int(dict["PITCH"])
		pitch = (pitch + 90)
	
	light.light_color = Color(r,g,b)
	light.translation = pos
	light.rotation_degrees.y = pitch
	light.spot_range = 20.0
	#light.omni_range = scaleFactor * get_parent().lightRangeMultiplier
	#light.light_indirect_energy = 100*scaleFactor * get_parent().lightEnergyMultiplier
	
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
	doorComponent.name = "func_door"
	
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
		
	if dict.has("TARGETNAME"):
		doorComponent.name = dict["TARGETNAME"]
	
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
	var brushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = brushModelInfo["faceArr"]
	var targetNodeArr = []
	var materialType = 0
	if dict.has("MATERIAL"):
		materialType = int(dict["MATERIAL"])
	#var material = MATERIAL[int(dict["MATERIAL"])]
	
	for i in targetFaces:
		#if i > faceMeshNodes.size():
		#	continue
		if !faceMeshNodes.has(i):
			return
		if faceMeshNodes[i] == null:
			continue
		targetNodeArr.append(faceMeshNodes[i].get_parent().name)
		
		var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_breakable.gd")
		var breakableNode = Node.new()
		breakableNode.name = "func_breakable"
		
		if dict.has("TARGETNAME"):
			breakableNode.add_to_group(dict["TARGETNAME"])
			
		if dict.has("TARGET"):
			breakableNode.set_meta("targetName",dict["TARGET"])
		breakableNode.set_meta("targetNodes",targetNodeArr[0])
		breakableNode.set_meta("materialType",materialType)
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

func parseRotButton(dict):
	
	var target = null
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"]
	var faceMeshNodes = get_parent().faceMeshNodes
	var targetNodeArr = []
	var axis = Vector3(0,1,0)
	if dict.has("TARGET"):
		target = dict["TARGET"]
	
	var origin = Vector2.ZERO
	var sound = 0
	
	if dict.has("ORIGIN"):
		origin = textToVector3(dict["ORIGIN"])

	var flags = int(dict["SPAWNFLAGS"])
	if(flags & 64) >0:#x axis
		axis = Vector3(-1,0,0)
	
	if(flags & 128) >0:#y axis
		axis = Vector3(0,0,1)
		
		
	
	
	for i in targetFaces:
		if faceMeshNodes.has(i):
			setOrigin(faceMeshNodes[i].get_parent(),origin)
			targetNodeArr.append(faceMeshNodes[i].get_parent().name)
			
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_rot_button.gd")
	
	
	var interactionAreaNode = createInteractionAreaNode(bushModelInfo,3)
	
	if dict.has("SOUNDS"):
		if dict["SOUNDS"] != "0":
			sound = int(dict["SOUNDS"])
			if BUTTONSOUNDS.has(sound):
				var audioPlayer = get_parent().createAudioPlayer3DfromName("buttons/"+ BUTTONSOUNDS[sound])
				audioPlayer.name = "sound"
				interactionAreaNode.add_child(audioPlayer)
	
	interactionAreaNode.set_meta("targetNodePaths",targetNodeArr)
	interactionAreaNode.translation =(bushModelInfo["BBMin"] + 0.5*(bushModelInfo["BBMax"]-bushModelInfo["BBMin"]))+origin
	interactionAreaNode.name = "func_rot_button"
	interactionAreaNode.set_meta("target",target)
	interactionAreaNode.set_meta("axis",axis)
	interactionAreaNode.set_script(scriptRes)
	get_parent().get_node("BrushEntities").add_child(interactionAreaNode)


func parsePushable(dict):
	return
	var faceMeshNodes = get_parent().faceMeshNodes
	var bushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = bushModelInfo["faceArr"] 
	var rigidBody = RigidBody.new()
	var originPos = faceMeshNodes[targetFaces[0]].get_parent().translation

	rigidBody.translation = originPos
	rigidBody.can_sleep = false
	#rigid body (center translation)
	#
	for i in targetFaces: #for every static body of model
		if faceMeshNodes.has(i):
			
			var meshNode : MeshInstance = faceMeshNodes[i]
			var bodyNode = meshNode.get_parent()
			var parPos = meshNode.get_parent().translation
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
			
			meshNode.translation = parPos - originPos
			collisionShape.translation = parPos - originPos
			
			collisionShape.get_parent().remove_child(collisionShape)
			rigidBody.add_child(collisionShape)
			
			if get_parent().physicsPropsDontRotate:
				rigidBody.axis_lock_angular_x = true
				rigidBody.axis_lock_angular_y = true
				rigidBody.axis_lock_angular_z = true
			
			#rigidBody.translation = pos
	rigidBody.gravity_scale = 10
	get_parent().add_child(rigidBody)


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
		var audioPlayer : AudioStreamPlayer3D = get_parent().createAudioPlayer3DfromName("doors/" + DOORSOUNDS[moveSound])
		audioPlayer.name = "moveSound"
		audioPlayer.unit_db = 10
		doorComponent.add_child(audioPlayer)
	
	doorComponent.set_meta("targetNodePaths",targetNodeArr)
	doorComponent.set_meta("scaleFactor",scaleFactor)
	doorComponent.set_meta("origin",origin)
	doorComponent.set_meta("rotAmount",rotAmount)
	doorComponent.set_meta("initialRot",initialRot)
	
	doorComponent.set_meta("rotDir",1)
	doorComponent.name = "func_door_rotating"
	if dict.has("SPAWNFLAGS"):
		var flags = int(dict["SPAWNFLAGS"])
		
		if (flags & (1 << 0)) > 0: 
			print("startsOpen")
			
		if (flags & (1 << 1)) > 0:
			doorComponent.set_meta("rotDir",-1) 
			#print("reverseDir")
		
		if (flags & (1 << 2)) > 0:
			pass
			#print("dont link")
		
		if (flags & (1 << 3)) > 0:
			pass
			#print("passable")
		
		if (flags & (1 << 4)) > 0:
			pass
			#print("one way")
		
		if (flags & (1 << 5)) > 0:
			pass
			#print("toggle")
		
		
		if(flags & (1 << 7 )) > 0:
			#print("y axis")
			#initialRot = Vector3(90,0,0)
			axis = Vector3(0,0,1)
			
		if (flags & (1 << 6)) > 0:
			#print("x axis")
			axis = Vector3(-1,0,0)
		
		if(flags & (1 << 8)) > 0:
			#print("use oonly")
			pass
			
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
	var flags = 0
	var axis = Vector3(0,1,0)
	
	if dict.has("SPAWNFLAGS"):
		flags = int(dict["SPAWNFLAGS"])
	
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


func parseLadder(dict):
	var modelInfo = getModelInfoFromDict(dict)
	var interactionBox = createInteractionAreaNode(modelInfo,3)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5
	interactionBox.name = "ladder"
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_ladder.gd")
	interactionBox.set_script(scriptRes)
	
	get_parent().get_node("triggers").add_child(interactionBox)

	
	deleteModelNode(modelInfo)

func parseTriggerPush(dict):
	var modelInfo = getModelInfoFromDict(dict)
	var interactionBox = createInteractionAreaNode(modelInfo,3)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5
	interactionBox.name = "ladder"
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/trigger_push.gd")
	interactionBox.set_script(scriptRes)
	
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
	var delay = 0
	
	if dict.has("DELAY"):
		delay = dict["DELAY"]
	
	node.set_meta("delay",delay)
	node.set_script(scriptRes)
	get_parent().get_node("triggers").add_child(node)

func parseTriggerAutoSave(dict):
	
	var modelInfo = getModelInfoFromDict(dict)
	var interactionBox = createInteractionAreaNode(modelInfo)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5
	
	
	get_parent().get_node("triggers").add_child(interactionBox)
	deleteModelNode(modelInfo)


func parseTriggerCDAudio(dict):
	var modelInfo = getModelInfoFromDict(dict)
	var interactionBox = createInteractionAreaNode(modelInfo)
	interactionBox.translation = modelInfo["BBMin"]+ (modelInfo["BBMax"] - modelInfo["BBMin"])*0.5
	var audioId = int(dict["HEALTH"])
	if audioId <= 1:
		return
	
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
				
				if i["renderMode"] == RENDERMODE.color:
					mat.albedo_texture = null
					mat.albedo_color = i["RENDERCOLOR"]
					mat.albedo_color.a = i["RENDERAMT"]
				
				if i["renderMode"] == RENDERMODE.texture:
					mat.flags_transparent = true
					mat.albedo_color.a = i["RENDERAMT"]
				
				if i["renderMode"] == RENDERMODE.solid:
					mat.flags_transparent = true
					
				
				if i["renderMode"] == RENDERMODE.additive:
					mat.albedo_color.a = i["RENDERAMT"]
					mat.params_blend_mode = mat.BLEND_MODE_ADD
				
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
	if mode != 111111:
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
				color = dict["RENDERCOLOR"]#/255
				color  = color.split(" ")
				var cx = int(color[0])
				var cy = int(color[1])
				var cz = int(color[2])
				color = Color8(int(cx),int(cy),int(cz))
		
		get_parent().renderModeFaces.append({"MODEL":model,"renderMode":mode,"RENDERAMT":amount,"RENDERCOLOR":color})
		get_parent().modelRenderModes[model] = {"renderMode":mode,"amount":amount}

func parseMultiManager(dict):
	var targetGroups = []
	for i in dict.keys():
		if i != "TARGETNAME" and i != "CLASSNAME" and i!= "ORIGIN":
			targetGroups.append({"name":i,"delay":dict[i]})
	

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
	
	if dict.has("MESSAGE"):
		node.set_meta("trigger",dict["MESSAGE"])
	
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
		
	if dict.has("MESSAGE"):
		node.set_meta("trigger",dict["MESSAGE"])
	get_parent().add_child(node)


func parseTrain(dict):
	
	var faceMeshNodes = get_parent().faceMeshNodes
	var brushModelInfo = getModelInfoFromDict(dict)
	var targetFaces = brushModelInfo["faceArr"]
	var targetNodeArr = []
	var pathArr = []
	
	
	#if dict.has("SPAWNFLAGS"):
	#	if int(dict["SPAWNFLAGS"]) == 8:
	#		deleteModelNode(brushModelInfo)
	
	if !dict.has("TARGET"):#if train dosen't have a traget corner it won't move so nothing needs to happen
		return
	
	var a = dict["TARGET"]
	print("Start loop")
	while(a != null):
		
		if !cornerPaths.has(a):
			return
		
		var b = cornerPaths[a]
		
		
		pathArr.append(a)
		a = b
		print(pathArr.size())
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
	var sound = -1
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
				pathArr.append(b)
				break
	
	var path = Path.new()
	var tarr = []
	for i in pathArr:
		var node : Position3D = (get_parent().find_node(i,true,false))
		if node.has_meta("trigger"):
			var triggerName = node.get_meta("trigger")
			
			path.set_meta(triggerName,node.translation)
			#var areaNode = Area.new()
			#var collisionNode = CollisionShape.new()
			#var shapeNode = BoxShape.new()
			
			#shapeNode.extents = Vector3(scaleFactor*5,scaleFactor*5,scaleFactor*5)
			#collisionNode.shape = shapeNode
			#areaNode.add_child(collisionNode)
			#node.add_child(areaNode)
			#areaNode.name = nameStr
		
		
		path.curve.add_point(node.translation)
		

		
		
		
	path.set_meta("scaleFactor",scaleFactor)
	path.add_child(PathFollow.new())
	get_parent().add_child(path)
	var scriptRes = load("res://addons/gldsrcBSP/funcScripts/func_track_train.gd")
	var trainNode= Spatial.new()

	if dict.has("SOUNDS"):
		sound = int(dict["SOUNDS"])
		var audioNode = get_parent().createAudioPlayer3DfromName(TRAINSOUNDS[sound])
		audioNode.name = "moveSound"
		trainNode.add_child(audioNode)

	trainNode.translation = origin
	trainNode.name ="func_tracktrain"
	trainNode.set_meta("targetNodePaths",targetNodeArr)
	trainNode.set_meta("path",pathArr)
	trainNode.set_meta("pathName",path.name)
	trainNode.set_script(scriptRes)

	get_parent().add_child(trainNode)

func parseAmbientGeneric(dict):
	if !dict.has("MESSAGE"):
		return
	var par = get_parent().get_node_or_null("Ambient Sounds")
	if par == null:
		par = Node.new()
		par.name = "Ambient Sounds"
		get_parent().add_child(par)
	

		
	

	var pos = textToVector3(dict["ORIGIN"])
	var audioNode = get_parent().createAudioPlayer3DfromName(dict["MESSAGE"].to_lower())
	if dict.has("MESSAGE"):
		audioNode.name= dict["MESSAGE"]
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
	var playEverywhere = false
	if dict.has("SPAWNFLAGS"):
		var flags = int(dict["SPAWNFLAGS"])
		
		if flags & (1 << 0) > 0:
			audioNode.unit_size = 100000000
			playEverywhere = true
			
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
	
func parseModel(dict,modelName):
	var pos = textToVector3(dict["ORIGIN"])
	var baseDir = get_parent().wadDict["baseDirectory"]
	
	
	var mesh = $"../mdlLoader".mdlParse(baseDir + "models/" + modelName)
	mesh.scale *= scaleFactor
	#mesh.rotation_degrees.x -= 90
	mesh.translation = pos
	
	
	get_parent().add_child(mesh)
	#breakpoint

func parseIllusionary(dict):
	var modelInfo = getModelInfoFromDict(dict)
	deleteModelCollision(modelInfo)

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
				

func deleteModelCollision(modelInfo):
	var modelFaceIdxs = modelInfo["faceArr"]
	var deleted = false
	for faceIdx in modelFaceIdxs:
		if get_parent().faceMeshNodes.has(faceIdx):
			if get_parent().faceMeshNodes[faceIdx] != null:#whis is this nulled?
				
				var par = get_parent().faceMeshNodes[faceIdx].get_parent()
				#print(par.get_type())
				for i in par.get_children():
					if i.get_class() == "MeshInstance":
						i.get_parent().remove_child(i) 
						par.remove_child(i)
						i.translation += par.translation
						var parp = i.get_parent()
						par.get_parent().add_child(i)
					else:
						i.queue_free()
				par.queue_free()
				deleted = true

func guessWadPath(path):
	if path.find_last("Half-Life") != -1:
		var pathPre = path.substr(0, path.find_last("Half-Life"))
		return pathPre + "Half-Life/valve/halflife.wad" 
	else:
		return null

