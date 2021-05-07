tool
extends Node
var file
var textures = []
var fileDict = {}
var bones = []
var boneIndex = 0
var boneMap = {}
var ittCount = -1
var killSwitch = false
#onready var ig = get_node("../ImmediateGeometry")


func mdlParse(path): 
	file = load("res://addons/gldsrcBSP/DFile.gd").new()
	
	if !file.loadFile(path):
		print("file not found")
		return false
		
	fileDict["magic"] = file.get_String(4)
	fileDict["version"] = file.get_32()
	fileDict["name"] = file.get_String(64)
	fileDict["size"] = file.get_32()
	fileDict["eyePosition"] = getVectorXZY(file)
	fileDict["min"] = getVectorXZY(file)
	fileDict["max"] = getVectorXZY(file)
	fileDict["bbmin"] = getVectorXZY(file)
	fileDict["bbmax"] = getVectorXZY(file)
	fileDict["flags"] = file.get_32()
	fileDict["numBones"] = file.get_32()
	fileDict["boneIndex"] = file.get_32()
	fileDict["numbonecontrollers"] = file.get_32()
	fileDict["bonecontrollerindex"] = file.get_32()
	fileDict["numhitboxes"] = file.get_32()
	fileDict["hitboxindex"] = file.get_32()
	fileDict["numseq"] = file.get_32()
	fileDict["seqindex"] = file.get_32()
	fileDict["numseqgroups"] = file.get_32()
	fileDict["seqgroupindex"] = file.get_32()
	fileDict["numTextures"] = file.get_32()
	fileDict["textureindex"] = file.get_32()
	fileDict["texturedataindex"] = file.get_32()
	fileDict["numskinref"] = file.get_32()
	fileDict["numskinfamilies"] = file.get_32()
	fileDict["skinindex"] = file.get_32()
	fileDict["numbodyparts"] = file.get_32()
	fileDict["bodypartindex"] = file.get_32()
	fileDict["numattachments"] = file.get_32()
	fileDict["attachmentindex"] = file.get_32()
	fileDict["soundtable"] = file.get_32()
	fileDict["soundindex"] = file.get_32()
	fileDict["soundgroups"] = file.get_32()
	fileDict["soundgroupindex"] = file.get_32()
	fileDict["numtransitions"] = file.get_32()
	fileDict["transitionindex"] = file.get_32()
	
	#print("numTextures:",fileDict["numTextures"])
	file.seek(fileDict["textureindex"])
	for i in fileDict["numTextures"]:
		textures.append(parseTexture())
	
	if fileDict["numTextures"] == 0:
		var searchPath = path.split(".")[0]
		searchPath = searchPath + "t.mdl"
		var fExist= File.new()
		var doesExist = fExist.file_exists(searchPath)
		fExist.close()
			
		if doesExist:
			var textureParse = Node.new()
			var script = load("res://addons/gldsrcBSP/src/mdlLoad.gd")
			textureParse.set_script(script)
			add_child(textureParse)
			textures = textureParse.mdlParseTextures(searchPath)
	
	
	parseBones()
	boneHier2()
	var seq = parseSequence()
	return parseBodyPart()
	
	
	
func mdlParseTextures(path): 
	file = load("res://addons/gldsrcBSP/DFile.gd").new()
	
	if !file.loadFile(path):
		print("file not found")
		return false
		
	fileDict["magic"] = file.get_String(4)
	fileDict["version"] = file.get_32()
	fileDict["name"] = file.get_String(64)
	fileDict["size"] = file.get_32()
	fileDict["eyePosition"] = getVectorXZY(file)
	fileDict["min"] = getVectorXZY(file)
	fileDict["max"] = getVectorXZY(file)
	fileDict["bbmin"] = getVectorXZY(file)
	fileDict["bbmax"] = getVectorXZY(file)
	fileDict["flags"] = file.get_32()
	fileDict["numBones"] = file.get_32()
	fileDict["boneIndex"] = file.get_32()
	fileDict["numbonecontrollers"] = file.get_32()
	fileDict["bonecontrollerindex"] = file.get_32()
	fileDict["numhitboxes"] = file.get_32()
	fileDict["hitboxindex"] = file.get_32()
	fileDict["numseq"] = file.get_32()
	fileDict["seqindex"] = file.get_32()
	fileDict["numseqgroups"] = file.get_32()
	fileDict["seqgroupindex"] = file.get_32()
	fileDict["numTextures"] = file.get_32()
	fileDict["textureindex"] = file.get_32()
	fileDict["texturedataindex"] = file.get_32()
	
	file.seek(fileDict["textureindex"])
	for i in fileDict["numTextures"]:
		textures.append(parseTexture())
	
	return textures

func saveScene():
	var i = 0
	for c in get_children():
		c.set_owner(self)
	#	var packed_scene = PackedScene.new()
	#	packed_scene.pack(c)
	#	ResourceSaver.save(String(i) + ".tscn", packed_scene)
	#	i+= 1
	
	
	var packed_scene = PackedScene.new()
	packed_scene.pack(self)
	ResourceSaver.save(String(i) + ".tscn", packed_scene)
	#	i+= 1
	print("saved")


func parseTexture():
	var textureDict = {}
	#if fileDict["textureindex"] == 0 :return
	#file.seek(fileDict["textureindex"])
	
	textureDict["name"] = file.get_String(64)
	textureDict["flags"] = file.get_32()
	textureDict["width"] = file.get_32()
	textureDict["height"] = file.get_32()
	textureDict["index"] = file.get_32()

	var w = textureDict["width"]
	var h =  textureDict["height"]
	var image = Image.new()
	image.create(w,h,false,Image.FORMAT_RGBA8)
	
	var pPos = file.get_position()
	
	file.seek(textureDict["index"])
	
	var pallete = []
	var colorArr = []
	
	for y in h:
		for x in w:
			var colorIndex = file.get_8()
			colorArr.append(colorIndex)
	
	# file.get_8()
	
	for c in 256:
		var r = file.get_8() / 255.0
		var g = file.get_8() / 255.0
		var b = file.get_8() / 255.0

		pallete.append(Color(r,g,b))
		
	image.lock()
	
	
	for y in h:
		for x in w:
			var colorIndex = colorArr[x+(y*w)]
			var color = pallete[colorIndex]
			image.set_pixel(x,y,color)

	
	image.unlock()
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	if true:
		texture.flags -= texture.FLAG_FILTER
		
	file.seek(pPos)
	return texture
	

func parseSequence():
	var sequences = []
	file.seek(fileDict["seqindex"])
	for i in fileDict["numseq"]:
		var sequenceDict = {}
		sequenceDict["name"] = file.get_String(32)
		sequenceDict["fps"] = file.get_float32()
		sequenceDict["flags"] = file.get_32()
		sequenceDict["activity"] = file.get_32()
		sequenceDict["actweight"] = file.get_32()
		sequenceDict["numevents"] = file.get_32()
		sequenceDict["eventindex"] = file.get_32()
		sequenceDict["numframes"] = file.get_32()
		sequenceDict["numpivots"] = file.get_32()
		sequenceDict["pivotIndex"] = file.get_32()
		sequenceDict["motionType"] = file.get_32()
		sequenceDict["motionBone"] = file.get_32()
		sequenceDict["linearMovement"] = getVectorXZY(file)
		sequenceDict["autoMovePosIndex"] = file.get_32()
		sequenceDict["autoMovoeAngleIndex"] = file.get_32()
		sequenceDict["bbMin"] = getVectorXZY(file)
		sequenceDict["bbMax"] = getVectorXZY(file)
		sequenceDict["numBlends"] = file.get_32()
		sequenceDict["animIndex"] = file.get_32()
		sequenceDict["blendType0"] = file.get_32()
		sequenceDict["blendType1"] = file.get_32()
		sequenceDict["blendStart0"] = file.get_float32()
		sequenceDict["blendStart1"] = file.get_float32()
		sequenceDict["blendEnd0"] = file.get_float32()
		sequenceDict["blendEnd1"] = file.get_float32()
		sequenceDict["blendParent"] = file.get_float32()
		sequenceDict["seqGroup"] = file.get_32()
		sequenceDict["entryMode"] = file.get_32()
		sequenceDict["exitNode"] = file.get_32()
		sequenceDict["nodeFlags"] = file.get_32()
		sequenceDict["nextFlags"] = file.get_32()
		
		sequences.append(sequenceDict)
		parseAnims(sequenceDict["animIndex"],sequenceDict["numBlends"],sequenceDict["numframes"])
		
	return sequences

func parseAnims(offset,numBlends,numFrames):
	file.seek(offset)
	
	var boneToOffset = []
	var blendOffsets = []
	
	
	var blendLength = 6 * bones.size()#a pos and rot for each bone
	for o in numBlends*blendLength:
		blendOffsets.append(file.get_16())#an offset for each value xyz rxryryx
	
	var boneAnimData = []
	
	for boneIdx in bones.size():
		for f in numFrames:
			var animData = []
			animData.resize(numFrames)
			
			for i in numFrames:
				animData[i] = 0
			
			var compressedSize = file.get_8()
			var uncompressedSize = file.get_8()
			var compressedData = []
			
			for i in compressedSize:
				compressedData.append(file.get_16u())
			
			var i = 0
			var j = 0
			
			while(j < uncompressedSize and i < numFrames):
				var index = min(compressedSize-1,j)
				animData[i] = compressedData[index]
				j+=1
				i+=1
			boneAnimData.append(animData)
			

	#breakpoint

	#for bone in bones.size():
		
	#	var xOffset = file.get_16()
	#	var yOffset = file.get_16()
	#	var zOffset = file.get_16()
	#	var xrOffset = file.get_16()
	#	var yrOffset = file.get_16()
	#	var zrOffset = file.get_16()
	#	boneToOffset.append({"xOffset":xOffset,"yOffset":yOffset,"zOffset":zOffset,"xrOffset":xrOffset,"yrOffset":yrOffset,"zrOfsset":zrOffset})
		
#	breakpoint

func parseBones():
	file.seek(fileDict["boneIndex"])
	for b in fileDict["numBones"]:
		bones.append(parseBone())

func parseBone():
	var boneDict = {}
	

	boneDict["name"] = file.get_String(32)
	boneDict["parentIndex"] = file.get_32()
	boneDict["unused"] = file.get_32()
	boneDict["x"] = file.get_32()
	boneDict["y"] = file.get_32()
	boneDict["z"] = file.get_32()
	boneDict["rotX"] = file.get_32()
	boneDict["rotY"] = file.get_32()
	boneDict["rotZ"] = file.get_32()
	boneDict["pos"] = getVectorXZY(file)
	boneDict["rot"] = getVectorXZY(file)
	boneDict["scaleP"] = getVectorXZY(file)
	boneDict["scaleR"] = getVectorXZY(file)
	boneDict["index"] = String(boneIndex)
	boneDict["transform"] = Transform.IDENTITY
	var sphere = CSGSphere.new()
	
	#boneDict["rot"] = Vector3(-boneDict["rot"].x,boneDict["rot"].z,boneDict["rot"].y)

		#breakpoint
	boneIndex += 1
	return boneDict



func parseBodyPart():
	file.seek(fileDict["bodypartindex"])
	var bodyPart = {}
	bodyPart["name"] = file.get_String(64)
	bodyPart["numModels"] = file.get_32()
	bodyPart["base"] = file.get_32()
	bodyPart["modelIndex"] = file.get_32()
	return parseModel(bodyPart["modelIndex"])
	

func parseModel(offset):
	file.seek(offset)
	var modelDict = {}
	modelDict["name"] = file.get_String(64)
	modelDict["type"] = file.get_32()
	modelDict["boundingRadius"] = file.get_32()
	modelDict["numMesh"] = file.get_32()
	modelDict["meshindex"] = file.get_32()
	modelDict["numverts"] = file.get_32()
	modelDict["vertinfoindex"] = file.get_32()
	modelDict["vertIndex"] = file.get_32()
	modelDict["numNorms"] = file.get_32()
	modelDict["normInfoIndex"] = file.get_32()
	modelDict["normIndex"] = file.get_32()
	modelDict["numGroups"] = file.get_32()
	modelDict["groupsIndex"] = file.get_32()
	
	var verts = []
	var norms = []
	var boneMap = []
	file.seek(modelDict["vertIndex"])
	for i in range(0,modelDict["numverts"]):
		verts.append(getVectorXZY(file))
	
	file.seek(modelDict["normIndex"])
	for i in range(0,modelDict["numNorms"]):
		norms.append(getVectorXZY(file))
	
	
	file.seek(modelDict["vertinfoindex"])
	for i in range(0,modelDict["numverts"]):
		boneMap.append(file.get_8())
	#print(boneMap)
	
	var meshs = []
	file.seek(modelDict["meshindex"])
	var runningMesh = ArrayMesh.new()
	
	for i in range(0,modelDict["numMesh"]):
		var meshDict = parseMesh()
		
		for poly in meshDict["triVerts"]:
			var v = []
			var n = []
			var uv = []
			var tex = []
			var bones = []
			
			for vertDict in poly:
				v.append(verts[vertDict["vertIndex"]])
				n.append(norms[vertDict["normIndex"]])
				uv.append(Vector2(vertDict["s"],vertDict["t"]))
				bones.append(boneMap[vertDict["vertIndex"]])
			var type = poly[0]["type"]
		#	print(meshDict["skinref"])
			runningMesh = createMesh(v,n,type,uv,bones,meshDict["skinref"],runningMesh)
			#add_child(runningMesh)
		#for j in v.size()/3:
		#	print(j)
		#	var cur = [v[j*3],v[j*3+1],v[j*3+2]]
		#	add_child(createMesh(cur))
	
	var meshNode = MeshInstance.new()
	meshNode.mesh = runningMesh
	meshNode.name = "hello"
	return meshNode
func parseMesh():
	var meshDict = {}
	
	meshDict["numTris"]  = file.get_32()
	meshDict["triIndex"]  = file.get_32()
	meshDict["skinref"]  = file.get_32()
	meshDict["numNorms"]  = file.get_32()
	meshDict["normIndex"] = file.get_32()
	meshDict["triVerts"] = []
	
	var pPos = file.get_position()
	file.seek(meshDict["triIndex"])
	
	
	var count = 0
	
	for i in range(0,meshDict["numTris"]):#we have 60 tringles
		var t = parseTrivert()
		if t == null:
			break
		meshDict["triVerts"].append(t)

	
	file.seek(pPos)
	return meshDict


	
func parseTrivert():
	
	var count = file.get_16u()
	
	if count == 0:
		return null
	var tris = []
	for i in abs(count):
		var vertDict = {}
		vertDict["vertIndex"]  = file.get_16()
		vertDict["normIndex"]  = file.get_16()
		vertDict["s"]  = file.get_16()
		vertDict["t"]  = file.get_16()
		vertDict["type"] = sign(count)
		tris.append(vertDict)

	return tris

func createMeshFromFan(vertices):

	var texture
	var surf = SurfaceTool.new()
	var mesh = Mesh.new()

	
	surf.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)


	var TL = Vector2(INF,INF)
	var triVerts = []
	for v in vertices.size():
		triVerts.append(vertices[v])

	
	surf.add_triangle_fan(triVerts,[],[],[],[])
	surf.commit(mesh)
	var meshNode = MeshInstance.new()
	meshNode.mesh = mesh

	return meshNode

func createMesh(vertices,normals,type,uv,boneIndices,textureIndex,runningMesh=null):
	var test = boneMap
	var center = Vector3.ZERO
	
	var surf = SurfaceTool.new()
	#var mesh = ArrayMesh.new()
	#mesh = surf.commit()
	var mat = createMat(textureIndex)

	
	
	if type == 1: surf.begin((Mesh.PRIMITIVE_TRIANGLE_STRIP))
	if type == -1: surf.begin((Mesh.PRIMITIVE_TRIANGLE_FAN))
	
	surf.set_material(mat)
	
	for v in vertices.size():
		#print(v)
		surf.add_normal(normals[v])
		surf.add_uv(uv[v])
		#var bonePos = boneMap[boneIndices[v]].global_transform.origin
		#var bonePos = boneMap[boneIndices[v]]["transform"]
		#var bonePos = Vector3.ZERO#bones[boneIndices[v]]["thePos"]
		
		var bonePos = bones[boneIndices[v]]["sumPos"]
		var boneRot = bones[boneIndices[v]]["rot"]
		
		#bonePos = bonePos.rotated(Vector3(1,0,0),boneRot.x)
		#bonePos = bonePos.rotated(Vector3(0,1,0),boneRot.y)
		#bonePos = bonePos.rotated(Vector3(0,0,1),boneRot.z)
		
		
		var vert = vertices[v]
		
		#vert = vert.rotated(Vector3(1,0,0),boneRot.x)
		#vert = vert.rotated(Vector3(0,1,0),boneRot.y)
		#vert = vert.rotated(Vector3(0,0,1),boneRot.z)
		vert = bones[boneIndices[v]]["runningTransform"].xform(vert)
	#	var vT = [vert.x,vert.y,vert.z,1]
		#vT =  bones[boneIndices[v]]["runningTransform"]*vT
		
		#vert += bonePos

		surf.add_vertex(vert)
		
	
	surf.commit(runningMesh)
	
	
	return runningMesh

func createMat(textureIndex):
	#print(textureIndex)
	var mat = SpatialMaterial.new()
	if textures == null:
		return mat
	
	if textures.size() == 0:
		return mat
	
	var text =  textures[textureIndex]
	mat.albedo_texture = text
	mat.uv1_scale.x /= text.get_width()
	mat.uv1_scale.y /= text.get_height()
	
	return(mat)



func boneHier2():
	for bone in bones:#bones arranged by index. Setting up children data
		var b1Index = bones.find(bone)
		bone["children"] = []
		for b2 in bones:
			var b2Index = bones.find(b2)
			if b2["parentIndex"] == b1Index:
			#	bone["children"].append(b2)
				bone["children"].append(b2Index)
	
	#var rootBone = bones[1]
	boneItt2(0,Transform.IDENTITY)

func boneItt2(index,runningTransform):
	if index == 0:
		var boneRot = bones[index]["rot"]
		var bonePos = bones[index]["pos"]
		var scaleR = bones[index]["scaleR"]
		bones[index]["sumPos"] = bonePos
		
		var localTransform = Transform.IDENTITY
		localTransform = localTransform.translated(bonePos)
		localTransform.basis = localTransform.basis.rotated(Vector3(1,0,0),boneRot.x)
		localTransform.basis = localTransform.basis.rotated(Vector3(0,1,0),boneRot.y)
		localTransform.basis = localTransform.basis.rotated(Vector3(0,0,1),boneRot.z)
		runningTransform *= localTransform
		
		bones[index]["runningTransform"] = runningTransform
		
	for cIndex in bones[index]["children"]:
		var cTransform = runningTransform
		
		var pBoneRot = bones[index]["rot"]
		var boneRot = bones[cIndex]["rot"]
		var bonePos = bones[cIndex]["pos"]
		
		
		var localTransform = Transform.IDENTITY
		localTransform = localTransform.translated(bonePos)
		localTransform.basis = localTransform.basis.rotated(Vector3(1,0,0),boneRot.x)
		localTransform.basis = localTransform.basis.rotated(Vector3(0,1,0),boneRot.y)
		localTransform.basis = localTransform.basis.rotated(Vector3(0,0,1),boneRot.z)
		cTransform *= localTransform
		
		bones[cIndex]["runningTransform"] = cTransform
		bones[cIndex]["sumPos"] = bones[index]["sumPos"] + bonePos#bones[cIndex]["pos"]
		#drawLine(bones[index]["sumPos"],bones[cIndex]["sumPos"])
		boneItt2(cIndex,cTransform)

	
	
	
func getVectorXZY(file):
	var vec = file.get_Vector32()
	#return Vector3(-vec.x,vec.z,vec.y)
	return Vector3(vec.x,vec.y,vec.z)
