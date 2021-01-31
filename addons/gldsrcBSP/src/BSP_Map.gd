tool
extends Spatial
class_name GLDSRC_Map
signal mapLoaded
signal playerSpawnSignal(pos,rot)
var file
var directory = {}


onready var imageBuilder = get_node("ImageBuilder")
onready var levelBuilder = get_node("levelBuilder")
onready var entityDataParser = get_node("entityDataParser")
var wadDict = {}
export(Array,String,FILE) var additionalWadDirs = [""]
var vertices
var planes
var edges 
var surfaces
var faces
var textureInfo
var textureCache = {}
var textures = []
var entities
var brushModels = []
var postFuncBrushes = []
var postPostFuncBrushes = []
var edgeToFaceIndexMap = {}
var faceMeshNodes = {}
var lightNodes = null
var brushNodes = null
var firstTick = true
var playerSpawnSet = false
var hotFaces = []
var renderModeFaces = []
export var optimize = true

export var enableEntities = true
var simpleCombine = false
export var disableSound = false
var physicsPropsDontRotate = true
var playerSpawn = {"position":Vector3.ZERO,"rotation":Vector3.ZERO}
var faceIndexToMaterialMap = {}
var nameToPathMap = {}
var materialCache = {}
var textureToFacesDict = {}
var modelRenderModes = {}

var LUMP_NANES = [
			"LUMP_ENTITES","LUMP_PLANES","LUMP_TEXTURES","LUMP_VERTICES","LUMP_VISIBILITY",
			"LUMP_NODES","LUMP_TEXINFO","LUMP_FACES","LIGHTING","LLUMP_CLIPNODES","LUMP_LEAVES",
			"LUMP_MARKSURFACES","LUMP_EDGES", "LUMP_SURFEDGES","LUMP_MODELS","HEADER_LUMPS",
			]


export(String,FILE) var path = "Enter path to BSP here"
export var scaleFactor = 0.05
export var disableTextures = false
export var textureFiltering = false
export var lightRangeMultiplier = 400.0
export var lightEnergyMultiplier = 75.0
export var cacheMaterials = true
export var collisions = true
export var lights = true
func _ready():
	
	if !Engine.is_editor_hint():
		if !find_node("Geometry"):
			createMap()
	pass
	


func createMap():
	levelBuilder = get_node("levelBuilder")
	entityDataParser = get_node("entityDataParser")
	imageBuilder = get_node("ImageBuilder")
	postFuncBrushes = []
	
	add_child(imageBuilder)
	lightNodes = Spatial.new()
	lightNodes.name = "Lights"
	add_child(lightNodes)
	
	
	brushNodes = Spatial.new()
	brushNodes.name = "BrushEntities"
	add_child(brushNodes)
	
	var triggers = Spatial.new()
	triggers.name = "triggers"
	add_child(triggers)
	
	var mergedFaces = Spatial.new()
	mergedFaces.name = "mergedFaces"
	add_child(mergedFaces)
	
	var decals = Spatial.new()
	decals.name = "decals"
	add_child(decals)
	
	if loadBSP() == false:
		print("failed to load BSP file")
		return

	levelBuilder.createLevel(directory,wadDict)
	#entityDataParser.sortEntityBrushesIntoNodes(brushModels)
	if enableEntities == false:
		set_meta("done",true)
		return 
	
	for i in postFuncBrushes:#the func brushes reference faces nodes so the map must be made first
		if i["CLASSNAME"] == "FUNC_DOOR":
			entityDataParser.parseDoor(i)
		elif i["CLASSNAME"] == "FUNC_BUTTON":
			entityDataParser.parseButton(i)
		elif i["CLASSNAME"] == "FUNC_WALL":
			entityDataParser.parseWall(i)
		elif i["CLASSNAME"] == "FUNC_DOOR_ROTATING":
			entityDataParser.parseDoorRotating(i)
		elif i["CLASSNAME"] == "TRIGGER_ONCE":
			entityDataParser.parseTriggerOnce(i)
		elif i["CLASSNAME"] == "TRIGGER_MULTIPLE":
			entityDataParser.parseTriggerMultiple(i)
		elif  i["CLASSNAME"] == "FUNC_PUSHABLE":
			entityDataParser.parsePushable(i)
		elif i["CLASSNAME"] == "FUNC_ROTATING":
			entityDataParser.parseRotating(i)
		elif i["CLASSNAME"] == "FUNC_BREAKABLE":
			entityDataParser.parseBreakable(i)
		elif i["CLASSNAME"] == "TRIGGER_AUTO":
			entityDataParser.parseTriggerAuto(i)
		elif i["CLASSNAME"] == "FUNC_TRAIN":
			entityDataParser.parseTrain(i)
		elif i["CLASSNAME"] == "FUNC_TRACKTRAIN":
			entityDataParser.parseTrackTrain(i)
		elif i["CLASSNAME"] == "TRIGGER_TRANSITION":
			entityDataParser.parseTriggerTransition(i)
		elif i["CLASSNAME"] == "TRIGGER_AUTOSAVE":
			entityDataParser.parseTriggerAutoSave(i)
		elif i["CLASSNAME"] == "TRIGGER_TELEPORT":
			entityDataParser.parseTriggerAutoSave(i)
		elif i["CLASSNAME"] == "TRIGGER_HURT":
			entityDataParser.parseTriggerAutoSave(i)
		elif i["CLASSNAME"] == "TRIGGER_CHANGELEVEL":
			entityDataParser.parseTriggerChangeLevel(i)
	
	for i in postPostFuncBrushes:#parsing multimanger last just in case
		if i["CLASSNAME"] == "MULTI_MANAGER":
			entityDataParser.parseMultiManager(i)
	entityDataParser.doRenderModes()
	set_meta("done",true)

func _process(delta):
	if firstTick and playerSpawnSet:# and get_meta("done"):
		
		get_tree().call_group("player","setSpawn",playerSpawn["position"],playerSpawn["rotation"])
		firstTick = false
	

func loadBSP():
	file = load("res://addons/gldsrcBSP/DFile.gd").new()
	if !file.loadFile(path):
		print("file not found:", path)
		return false
	
	var filePath = path.replace("\\","/")

	filePath = filePath.substr(0,filePath.find_last("/") )
	filePath =  filePath.substr(0,filePath.find_last("/") )
	filePath = filePath + '/'
	
	
	directory["version"] = file.get_32u()

	wadDict["baseDirectory"] = filePath
	#filePath =  path.substr(0,path.find_last("/") )
	for i in range(0,15):
		var lumpName = LUMP_NANES[i]
		directory[lumpName] = {}
		directory[lumpName]["offset"] = file.get_32u()
		directory[lumpName]["length"] = file.get_32u()
		pass
	
	parse_texinfo(directory["LUMP_TEXINFO"])
	parse_texture(directory["LUMP_TEXTURES"])
	parse_vertices(directory["LUMP_VERTICES"])
	parse_planes(directory["LUMP_PLANES"])
	parse_edges(directory[ "LUMP_EDGES"])
	parse_surfedges(directory["LUMP_SURFEDGES"])
	parse_faces(directory["LUMP_FACES"])
	parse_models(directory["LUMP_MODELS"])
	parse_entites(directory["LUMP_ENTITES"])
	
	
	return true

	
func parse_entites(lumpDict):
	file.seek(lumpDict["offset"])
	var allText = file.get_String(lumpDict["length"])
	allText = allText.replace("}","")
	var entArrayTxt  = allText.split("{\n",false)
	var entArrayToken
	
	var entDictData = []
	
	for t in entArrayTxt:
		var curEntDict = {}
		var allLines = t.split("\n",false)
		for line in allLines:
			#var temp = line.substr(1,-1)
			var temp = line
			var firstQoutePos = temp.find("\"")
			var secondQoutePos = temp.find("\"",firstQoutePos+1)
			var thirdQoutePos = temp.find("\"",secondQoutePos+1)
			var fourthQoutePos = temp.find("\"",thirdQoutePos+1)
		
			var identifier = temp.substr(firstQoutePos+1,secondQoutePos-1)
			var value = temp.substr(thirdQoutePos+1)
			curEntDict[identifier] = value.trim_suffix("\"")
		entDictData.append(curEntDict)
	

	
	for i in entDictData:
		entityDataParser.parseEntityData(i,wadDict)
	
	entities = entDictData
	
	

func parse_vertices(lumpDict):
	file.seek(lumpDict["offset"])
	var size = lumpDict["length"]
	var verticeArray = []
	for i in size/(4*3):
		var vec = file.get_Vector32()
		verticeArray.append(Vector3(-vec.x,vec.z,vec.y)*scaleFactor)
	
	#lumpDict["verticeArray"] = verticeArray
	vertices = verticeArray


func parse_planes(planeDict):
	file.seek(planeDict["offset"])
	var size = planeDict["length"]
	var planeArray = []
	for i in size/(5*4):
		var vect = file.get_Vector32()
		var dist = file.get_float32()
		var type = file.get_32u()
		planeArray.append({"normal":Vector3(-vect.x,vect.z,vect.y),"distance":dist,"type":type})
		
		
	planes = planeArray

func parse_edges(edgeDict):
	file.seek(edgeDict["offset"])
	var size = edgeDict["length"]
	var edgeArray = []
	
	for i in size/2:
		var a = file.get_16()
		var b = file.get_16()
		edgeArray.append([a,b])
	
	#edgeDict["array"] = edgeArray
	edges = edgeArray
		
func parse_surfedges(surfedgeDict):
	file.seek(surfedgeDict["offset"])
	var size = surfedgeDict["length"]
	var surfedgeArray = []
	
	for i in (size/4):
		surfedgeArray.append(file.get_32())
		
	#surfedgeDict["array"] = surfedgeArray
	surfaces =  surfedgeArray
	

func parse_faces(facesDict):
	file.seek(facesDict["offset"])
	var size = facesDict["length"]
	var facesArray = []
	var index = 0
	for i in size/(12+4+4):
		var dict = {}
		dict["planeIndex"] = file.get_16()
		dict["planeSide"] = file.get_16()
		dict["firstEdgeIndex"] = file.get_32()
		dict["nEdges"] = file.get_16()

		dict["textureInfo"] = file.get_16()
		var nStyles1 = file.get_8()
		var nStyles2 = file.get_8()
		var nStyles3 = file.get_8()
		var nStyles4 = file.get_8()
		dict["nStyles"] = [nStyles1,nStyles2,nStyles3,nStyles4]
		dict["lightmapOffset"] = file.get_32()
		dict["edges"] = []
		for j in range(dict["firstEdgeIndex"],dict["firstEdgeIndex"]+dict["nEdges"]):
			dict["edges"].append(j)
		
		var edge
		dict["actualEdges"] = []
		dict["verts"] = []
		dict["origFaces"] = [index]

		for e in dict["edges"]:
			if surfaces[e] >= 0:
				edge = edges[surfaces[e]]
				dict["verts"].append(vertices[edge[0]])
				#faceVerts.append(vertices[edge[0]])
				
				if !edgeToFaceIndexMap.has(edge):
					edgeToFaceIndexMap[edge] = []
				edgeToFaceIndexMap[edge].append(index)
				dict["actualEdges"].append(edge)
			else:
				edge = edges[-surfaces[e]]
				dict["verts"].append(vertices[edge[1]])
				#faceVerts.append(vertices[edge[1]])
				
				if !edgeToFaceIndexMap.has(edge):
					edgeToFaceIndexMap[edge] = []
				edgeToFaceIndexMap[edge].append(index)
				dict["actualEdges"].append(edge)
		index += 1
		
		var texInfo = textureInfo[dict["textureInfo"]]
		var textureI = textures[texInfo["textureIndex"]]
		var textureName = textureI["name"]
		dict["textureName"] = textureName
		if !textureToFacesDict.has(textureName):
			textureToFacesDict[textureName] = [index]
		else:
			textureToFacesDict[textureName].append(index)
		facesArray.append(dict)
		
		
		
		
	
	faces = facesArray
	

func parse_texinfo(texinfoDict):
	file.seek(texinfoDict["offset"])
	var size = texinfoDict["length"]
	var texInfoArr = []
	
	for i in size/(4*4 + 12*2):
		var infoDict = {}
		infoDict["vS"] = file.get_Vector32()#12
		infoDict["fSShift"] = file.get_float32()#4
		infoDict["vT"]= file.get_Vector32()#12
		infoDict["fTShift"] = file.get_float32()#4
		infoDict["textureIndex"] = file.get_32()#4
		infoDict["flags"] = file.get_32()#4
		
		infoDict["vS"] = Vector3(-infoDict["vS"].x,infoDict["vS"].z,infoDict["vS"].y)
		infoDict["vT"] = Vector3(-infoDict["vT"].x,infoDict["vT"].z,infoDict["vT"].y)
		
		
		texInfoArr.append(infoDict)
		
	textureInfo = texInfoArr


func parse_texture(textureDict):
	var tOffset = textureDict["offset"]
	file.seek(tOffset)
	
	var size = textureDict["length"]
	#textureDict["images"] = []
	var textureImagesArr = []
	var textureOffsets = []
	var textureArr = []
	
	var numberOfTextures = file.get_32()
	for i in numberOfTextures:
		textureOffsets.append(file.get_32u()+textureDict["offset"])
		
	for i in textureOffsets:
		file.seek(i)
		var cur = {}
		var fName  = file.get_String(16)
		var w = file.get_32u()
		var h = file.get_32u()
		
		var mip1 = file.get_32u()
		var mip2 =  file.get_32u()
		var mip3 = file.get_32u()
		var mip4 =  file.get_32u()
		
		if mip1 == 0:
			#textureDict["images"].append({"dim":[w,h],"name":fName})
			textures.append({"dim":[w,h],"name":fName})
			continue
		
		var mip1sz = mip2 - mip1
		var mip4sz = mip1sz / 64
		
		file.seek(mip1+i)
		
		var data = []
		var pallete = []
		var pixSize = w*h
		
		
		data = file.bulkByteArr(pixSize)
		
		file.seek(mip4+i+mip4sz+2)
		
		for c in 256:
			var r = file.get_8() / 255.0
			var g = file.get_8() / 255.0
			var b = file.get_8() / 255.0
			pallete.append(Color(r,g,b,1))

		textures.append({"dim":[w,h],"data":data,"palette":pallete,"name":fName})
	
	return textures

func parse_models(modelDict):
	var tOffset = modelDict["offset"]
	file.seek(tOffset)
	var length = modelDict["length"]
	for i in length/(12*3 + 4*7):
		
		var faceArr = []
		var BBmin = file.get_Vector32()#12
		var BBmax = file.get_Vector32()
		var origin = file.get_Vector32()
		var node1 = file.get_32()
		var node2 = file.get_32()
		var node3 = file.get_32()
		var node4 = file.get_32()
		var numVisLeafs = file.get_32()
		var firstFaceIndex = file.get_32()
		var numFaces = file.get_32()
		#if(i == 0):
		#	continue
		BBmin = Vector3(-BBmin.x,BBmin.z,BBmin.y)*scaleFactor
		BBmax = Vector3(-BBmax.x,BBmax.z,BBmax.y)*scaleFactor
		origin = Vector3(-origin.x,origin.z,origin.y)*scaleFactor
		var BBabs = BBmax - BBmin
		BBabs = Vector3(abs(BBabs.x),abs(BBabs.y),abs(BBabs.z))
		for f in numFaces:
			faceArr.append(f+firstFaceIndex)
			if !hotFaces.has(f+firstFaceIndex) and i!=0:
				#hotFaces[f+firstFaceIndex] = 1
				hotFaces.append(f+firstFaceIndex)
		
		
		
		brushModels.append({"faceArr":faceArr,"BBMin":BBmin,"BBMax":BBmax,"origin": origin,"BBabs":BBabs})
		


func fetchTexture(textureName,isDecal = false):
	
	if textureCache.has(textureName):
		return textureCache[textureName]
	
	for i in wadDict:
		if typeof(wadDict[i]) != TYPE_DICTIONARY:
			continue
			
		if wadDict[i].has(textureName):
			var textureFile = wadDict[i][textureName]
			
			var texture = imageBuilder.createImage(textureFile,isDecal)
			textureCache[textureName] = texture
			return texture
#	breakpoint
 
func loadSound(fileName):
		var dir = path
		dir  = dir.substr(0,dir.find_last('/'))
		dir  = dir.substr(0,dir.find_last('/'))
		dir = dir + "/sound/" + fileName
		
		var stream = get_node("waveLoader").getStreamFromWAV(dir)
		return stream
		
func createAudioPlayer3DfromName(fileName):
	fileName = fileName.replace("*","")
	if fileName.find(".wav") == -1 or disableSound:
		return AudioStreamPlayer3D.new()
		
	var stream : AudioStreamSample = loadSound(fileName) 
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	return player
	
func fetchMaterial(nameStr):
	var isFirstINstance = false
	if !materialCache.has(nameStr) or !cacheMaterials:
		materialCache[nameStr] = []
		isFirstINstance = true
		var mat = SpatialMaterial.new()
		
		return {"material":mat,"isFirstInstance":isFirstINstance}
	
	return {"material":materialCache[nameStr],"isFirstInstance":isFirstINstance}
	
func saveToMaterialCache(nameStr,mat):
	materialCache[nameStr] = mat
