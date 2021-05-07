tool
extends Spatial
class_name GLDSRC_Map
signal mapLoaded
signal playerSpawnSignal(dict)
var file
var directory = {}
var spawns = []

onready var imageBuilder = get_node("ImageBuilder")
onready var levelBuilder = get_node("levelBuilder")
onready var entityDataParser = get_node("entityDataParser")
onready var bmlLoader = get_node("bmpLoader")
onready var lightmapAtlas = get_node("lightmapAtlas")
var wadDict = {}
#export(Array,String,FILE) var additionalWadDirs = [""]
var vertices = []
var planes = []
var edges = []
var surfaces = []
var renderables = []
var renderableEdges = []
var textureInfo = []
var textureCache = {}
var textures = []
var entities = []
var brushModels = []
var postFuncBrushes = []
var postPostFuncBrushes = []
var edgeToFaceIndexMap = {}
var faceMeshNodes = {}
var lightNodes = null
var brushNodes =  null
var firstTick = true
var loaded = false
var playerSpawnSet = false
var hotFaces = []
var renderModeFaces = []
var renderFaces = []
var ligthMapOffset = null
var lightMap = []
var rawLightmap = []
var entityDataArr = []
export var importLightmaps = true
export var optimize = true
export var textureFilterSkyBox = true
export var enableEntities = true
export var disableSound = false
export var textureLights = true

var simpleCombine =  true
var physicsPropsDontRotate = true
var playerSpawn = {"position":Vector3.ZERO,"rotation":Vector3.ZERO}
var faceIndexToMaterialMap = {}
var nameToPathMap = {}
var materialCache = {}
var textureToFacesDict = {}
var modelRenderModes = {}
var textureToMaterialDict = {}
var skyTexture = "desert"
var hlPath = null
export var texturesPerMesh = 3

var LUMP_NANES = [
			"LUMP_ENTITES","LUMP_PLANES","LUMP_TEXTURES","LUMP_VERTICES","LUMP_VISIBILITY",
			"LUMP_NODES","LUMP_TEXINFO","LUMP_FACES","LUMP_LIGHTING","LLUMP_CLIPNODES","LUMP_LEAVES",
			"LUMP_MARKSURFACES","LUMP_EDGES", "LUMP_SURFEDGES","LUMP_MODELS","HEADER_LUMPS",
			]


export(String,FILE) var path =  "Enter path to BSP here"
export var scaleFactor = 0.05
export var disableTextures = false
export var textureFiltering = false
#export var lightRangeMultiplier = 400.0
#export var lightEnergyMultiplier = 75.0
export var cacheMaterials = true
export var collisions = true
export var lights = false
func _ready():
	
	if !Engine.is_editor_hint():
		if !find_node("Geometry"):
			createMap()

	if get_node_or_null("spawns"):
		var s = get_node("spawns").get_children()
		if s.size() > 0:
			emit_signal("playerSpawnSignal",{"pos":s[0].global_transform.origin,"rot":s[0].rotation_degrees.y})
		else:
			emit_signal("playerSpawnSignal",{"pos":Vector3.ZERO,"rot":0})



	


func createMap():
	#print("---creating map---")
	levelBuilder = get_node("levelBuilder")
	entityDataParser = get_node("entityDataParser")	
	imageBuilder = get_node("ImageBuilder")
	lightmapAtlas = get_node("lightmapAtlas")
	clearAllData()
	createSubNodes(["Lights","BrushEntities","triggers","decals","spawns"])
	lightNodes = get_node("Lights")
	brushNodes = get_node("BrushEntities")
	
	if loadBSP() == false:
		print("failed to load BSP file")
		deleteSubNodes(["Lights","BrushEntities","triggers","decals"])
		return
	
	
	levelBuilder.createLevel(directory,wadDict)
	

	
	if enableEntities == false:
		set_meta("done",true)
		return 
	
	for i in entityDataArr:
		entityDataParser.parseEntityData2(i)
	
	
	entityDataParser.doRenderModes2()
	set_meta("done",true)
	loaded = true

func _physics_process(delta):
	if loaded and !playerSpawnSet:
		emit_signal("playerSpawnSignal",getSpawn())
		playerSpawnSet = true
	

func loadBSP():
	var a = OS.get_system_time_msecs()
	file = load("res://addons/gldsrcBSP/DFile.gd").new()
	path = path.replace("\\","/")
	
	if !file.loadFile(path):
		print("file not found:", path)
		return false
	
	var filePath = path.replace("\\","/")

	filePath = filePath.substr(0,filePath.find_last("/") )
	filePath =  filePath.substr(0,filePath.find_last("/") )
	filePath = filePath + '/'
	
	
	directory["version"] = file.get_32u()
	
	if path.find("cstrike"):
		hlPath = filePath.replace("cstrike","valve")
	
	wadDict["baseDirectory"] = filePath
	#filePath =  path.substr(0,path.find_last("/") )
	for i in range(0,15):
		var lumpName = LUMP_NANES[i]
		directory[lumpName] = {}
		directory[lumpName]["offset"] = file.get_32u()
		directory[lumpName]["length"] = file.get_32u()
		pass
	
	#a = OS.get_system_time_msecs()
	parse_texinfo(directory["LUMP_TEXINFO"])
	#print("texinf:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parse_texture(directory["LUMP_TEXTURES"])
	#print("texture:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parse_vertices(directory["LUMP_VERTICES"])
	#print("vertices:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parse_planes(directory["LUMP_PLANES"])
	#print("planes:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parse_edges(directory[ "LUMP_EDGES"])
	#print("edges:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parse_surfedges(directory["LUMP_SURFEDGES"])
	#print("surfedges:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parseLightmap(directory["LUMP_LIGHTING"])
	#print("lightmap:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parse_faces(directory["LUMP_FACES"])
	#print("faces:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parse_models(directory["LUMP_MODELS"])
	#print("models:",OS.get_system_time_msecs()-a)
	#a = OS.get_system_time_msecs()
	parse_entites(directory["LUMP_ENTITES"])
	#print("entities:",OS.get_system_time_msecs()-a)
	
	#lightMapToImage()
	readMaterialSounds()
	#print("parse time:",OS.get_system_time_msecs()-a)
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
			#var temp = line
			var temp2 = line.split("\"",false)
			#var firstQoutePos = temp.find("\"")
			#var secondQoutePos = temp.find("\"",firstQoutePos+1)
			#var thirdQoutePos = temp.find("\"",secondQoutePos+1)
			#var fourthQoutePos = temp.find("\"",thirdQoutePos+1)
		
			#var identifier = temp.substr(firstQoutePos+1,secondQoutePos-1)
			#var value = temp.substr(thirdQoutePos+1)
			var identifier = temp2[0]
			var value = temp2[2]
			curEntDict[identifier] = value.trim_suffix("\"")
		entDictData.append(curEntDict)
	

	for i in entDictData:
		if i.has("WAD"):
			entityDataParser.allWADparse(i,wadDict)
		else:
			entityDataArr.append(i)
	
	entities = entDictData
	
	

func parse_vertices(lumpDict):
	file.seek(lumpDict["offset"])
	var size = lumpDict["length"]
	
	for i in size/(4*3):
		var vec = file.get_Vector32()
		vertices.append(Vector3(-vec.x,vec.z,vec.y)*scaleFactor)
	


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
	
	edges = edgeArray
		
func parse_surfedges(surfedgeDict):
	file.seek(surfedgeDict["offset"])
	var size = surfedgeDict["length"]
	var surfedgeArray = []
	
	for i in (size/4):
		surfedgeArray.append(file.get_32())
		
	surfaces =  surfedgeArray
	

func parse_faces(facesDict):
	file.seek(facesDict["offset"])
	var size = facesDict["length"]
	var index = 0
	for i in size/(12+4+4):
		var dict = {}
		var planeIndex  = file.get_16()
		var planeSide = file.get_16()
		var fistEdgeIndex = file.get_32()
		var numFaceEdges  = file.get_16()
		var faceTetxureInfoIdx = file.get_16()
		var faceEdges = []
		
		var nStyles1 = file.get_8()
		var nStyles2 = file.get_8()
		var nStyles3 = file.get_8()
		var nStyles4 = file.get_8()
		var faceverts = []
		#dict["nStyles"] = [nStyles1,nStyles2,nStyles3,nStyles4]
		
		var lightmapOffset = file.get_32()
		var surfEdges = []
		for j in range(fistEdgeIndex,fistEdgeIndex+numFaceEdges):
			surfEdges.append(j)
		
		var edge
		
		#dict["origFaces"] = [index]
		
		for e in surfEdges:
			if surfaces[e] >= 0:
				edge = edges[surfaces[e]]
				faceverts.append(vertices[edge[0]])
				
				
				if !edgeToFaceIndexMap.has(edge):
					edgeToFaceIndexMap[edge] = []
				edgeToFaceIndexMap[edge].append(index)
				faceEdges.append(edge)
			else:
				edge = edges[-surfaces[e]]
				faceverts.append(vertices[edge[1]])
				
				
				if !edgeToFaceIndexMap.has(edge):
					edgeToFaceIndexMap[edge] = []
				edgeToFaceIndexMap[edge].append(index)
				faceEdges.append(edge)

		var texInfo = textureInfo[faceTetxureInfoIdx]
		var textureI = textures[texInfo["textureIndex"]]
		var textureName = textureI["name"]
		
		if !textureToFacesDict.has(textureName):
			textureToFacesDict[textureName] = [index]
		else:
			textureToFacesDict[textureName].append(index)
		
		var norm = planes[planeIndex]["normal"]
		if planeSide == 1: norm = -norm
		norm = norm.snapped(Vector3(0.0001,0.0001,0.0001))
		var lightmapUV = []
		var uvs = []
		for v in faceverts:
			uvs.append(texProject(v,texInfo))
			lightmapUV.append(texProject(v,texInfo))
			
			
		
		var lImage = lightmapFunc(uvs,lightmapOffset,lightmapUV)
		var lightmapPos = get_node("lightmapAtlas").addToAtlas2(lImage,index)
		var uvOffset = Vector2(texInfo["fSShift"],texInfo["fTShift"])
		var f = {}
		f[textureName] = {}
		f[textureName] = [{"verts":faceverts,"normal":norm,"texInfo":texInfo,"uv":uvs,"uvOffset":uvOffset,"lightmapUV":lightmapUV,"localLightmap":lImage,"faceIndex":index}]
		
		renderables.append(f)
		renderableEdges.append(faceEdges)
		index += 1
		

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

	
	var numberOfTextures = file.get_32()
	for i in numberOfTextures:
		textureOffsets.append(file.get_32u()+textureDict["offset"])
		
	for i in textureOffsets:
		if i > file.get_len():#simple error check to prevent crash
			textures.append({})
			continue
			
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
			textures.append({"dim":[w,h],"name":fName,"external":true})
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

		BBmin = Vector3(-BBmin.x,BBmin.z,BBmin.y)*scaleFactor
		BBmax = Vector3(-BBmax.x,BBmax.z,BBmax.y)*scaleFactor
		origin = Vector3(-origin.x,origin.z,origin.y)*scaleFactor
		var BBabs = BBmax - BBmin
		BBabs = Vector3(abs(BBabs.x),abs(BBabs.y),abs(BBabs.z))
		for f in numFaces:
			faceArr.append(f+firstFaceIndex)
			if !hotFaces.has(f+firstFaceIndex) and i!=0:
				hotFaces.append(f+firstFaceIndex)
		
		
		
		brushModels.append({"faceArr":faceArr,"BBMin":BBmin,"BBMax":BBmax,"origin": origin,"BBabs":BBabs})
		
func parseLightmap(lightMapDict):
	
	ligthMapOffset = lightMapDict["offset"]
	file.seek(lightMapDict["offset"])
	var size = lightMapDict["length"]
	
	#for i in (size/3):
	#	var r = file.get_8()/255.0
	#	var g = file.get_8()/255.0
	#	var b = file.get_8()/255.0
	#	lightMap.append(Color(r,g,b))
	
	#file.seek(lightMapDict["offset"])
	rawLightmap = file.get_buffer(size)

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
	
	
	for i in textures:
		if i.name == textureName:
			if i.has("data"):
				var texture = imageBuilder.createImage(null,isDecal,i)
				textureCache[textureName] = texture
				return texture
				
	
	print("texture not found:",textureName)
#	breakpoint
 
func loadSound(fileName):
	var dir = path
	dir  = dir.substr(0,dir.find_last('/'))
	dir  = dir.substr(0,dir.find_last('/'))
	dir = dir + "/sound/" + fileName
		
	var stream = get_node("waveLoader").getStreamFromWAV(dir)
	if stream.data.size() == 0:
		if hlPath != null:
			stream =  get_node("waveLoader").getStreamFromWAV(dir.replace("cstrike","valve"))
			if stream.data.size() == 0:
				print("couldn't find sound file:",fileName)
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

func readMaterialSounds():
	var dir = path
	dir  = dir.substr(0,dir.find_last('/'))
	dir  = dir.substr(0,dir.find_last('/'))
	var matPath = dir + "/sound/materials.txt"
	var materialFile = File.new()
	var result = materialFile.open(matPath,materialFile.READ)
	if result != 0:
		return
	
	var content = materialFile.get_as_text()
	content = content.split("\n")
	
		
	for line in content:
		if line.length() == 0:
			continue
		if line[0] == "/":
			continue
		line = line.split(" ")
		var matType = line[0]
		var textureName = line[1]
		textureToMaterialDict[textureName] = matType
	#	if textures.has(textureName):
		#	breakpoint

func lightMapToImage():
	return
	var img : Image = Image.new()
	
	var size = (directory["LUMP_LIGHTING"]["length"]/4)
	print(size)
	var w = sqrt(size)
	var h = w
	
	img.create(w,h,false,Image.FORMAT_RGBF)
	img.lock()
	
	var count = 0
	for y in h:
		for x in w:
			img.set_pixel(x,y,lightMap[count])
			count+=1
	img.create_from_data(w,h,false,Image.FORMAT_RGBF,lightMap)
	#img.save_png("lightmatTest.png")

func createSubNodes(arr):
	for i in arr:
		var node = Spatial.new()
		node.name = i
		add_child(node)

func deleteSubNodes(arr):
	for i in arr:
		if get_node(i)!= null:
			remove_child(get_node(i))

func clearAllData():
	vertices.clear()
	planes.clear()
	edges.clear()
	surfaces.clear()
	textureInfo.clear()
	textureCache = {}
	textures.clear()
	entities.clear()
	brushModels.clear()
	postFuncBrushes.clear()
	postPostFuncBrushes.clear()
	edgeToFaceIndexMap = {}
	faceMeshNodes = {}
	firstTick = true
	playerSpawnSet = false
	hotFaces.clear()
	renderModeFaces.clear()
	renderFaces.clear()
	lightMap.clear()
	renderables.clear()
	renderableEdges.clear()


func texProject(vert,texInfo):

	var vs = texInfo["vS"]
	var fShift = texInfo["fSShift"]
	var vt = texInfo["vT"]
	var tShift = texInfo["fTShift"]

	#var u = vert.dot(vs)#*scaleFactor
	#var v = vert.dot(vt)#*scaleFactor
	
#	u += fShift
#	v += tShift
	
	var u= vert.dot(vs)/scaleFactor
	var v= vert.dot(vt)/scaleFactor
	u += fShift
	v += tShift
	
	
	return Vector2(u,v)


func texProject2(vert,texInfo):

	var vs = texInfo["vS"]
	var fShift = texInfo["fSShift"]
	var vt = texInfo["vT"]
	var tShift = texInfo["fTShift"]

	var u = vert.dot(vs)#*scaleFactor
	var v = vert.dot(vt)#*scaleFactor
	
	u += fShift
	v += tShift
	
	#var u= vert.dot(vs)/scaleFactor
	#var v= vert.dot(vt)/scaleFactor
	#u += fShift
	#v += tShift
	
	
	return Vector2(u,v)

func lightmapFunc(vertsUV,ligthmapDataOffset,lightmapuv):
	
	var mins = Vector2(INF,INF)
	var maxs = Vector2(-INF,-INF)
	
	
	for i in vertsUV:
		if i.x < mins.x : mins.x = i.x
		if i.y < mins.y : mins.y = i.y
		
		if i.x > maxs.x : maxs.x = i.x
		if i.y > maxs.y : maxs.y = i.y
	
	var uvDim = maxs - mins
	
	var maxs16 = (maxs/16).ceil()
	var mins16 = (mins/16).floor()
	

	
	
	
	var lightMapDim = (maxs16 - mins16)+Vector2(1,1)

	var texturel = createLightMapTexture(lightMapDim,ligthmapDataOffset)
	
	
	
	#lightmapuv.resize(vertsUV.size())
	for i in vertsUV.size():
		lightmapuv[i] = (vertsUV[i] - mins)/ uvDim
		#lightmapuv[i] -= lightmapuv[i]*0.001
	
	
	return texturel


func createLightMapTexture(dim,offset):

	var w = dim.x 
	var h = dim.y
	#var rawLightmap = rawLightmap
	
	var image : Image = Image.new()
	image.create(dim.x,dim.y,false,Image.FORMAT_RGB8)
	var fmt = image.get_format()
	image.lock()
	var i = 0
	
	for y in h:
		for x in w:
			var index = (x+(y*w))*3
			var r = rawLightmap[offset + index]
			var g = rawLightmap[offset + index + 1]
			var b = rawLightmap[offset + index + 2]
			var color = Color8(r,g,b)
			
			image.set_pixel(x,y,color)

	image.unlock()
	#var rect = Rect2(Vector2(0.5,0.5),image.get_size()-Vector2(0.5,0.5))
	#image = image.get_rect(rect)
	
	#var texture = ImageTexture.new()
	#texture.create_from_image(image)
	#texture.flags -= texture.FLAG_FILTER
	
	return image


func changeLevel(mapname):
	clearAllData()
	breakpoint

func getSpawn():
	if get_node_or_null("spawns"):
		var s = get_node("spawns").get_children()
		if s.size() > 0:
			return {"pos":s[0].global_transform.origin,"rot":s[0].rotation_degrees.y}
		else:
			return {"pos":s[0].global_transform.origin,"rot":s[0].rotation_degrees.y}
	else:
		return null
