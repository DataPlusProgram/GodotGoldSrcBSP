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

func _ready():
	set_meta("hidden",true)
	
func mdlParse(path): 
	file = load("res://addons/gldsrcBSP/DFile.gd").new()
	
	if !file.loadFile(path):
		print("file not found")
		return false
		
	fileDict["magic"] = file.get_String(4)
	fileDict["version"] = file.get_32()
	fileDict["name"] = file.get_String(64)
	fileDict["size"] = file.get_32()
	fileDict["eyePosition"] = file.get_Vector32()
	fileDict["min"] = file.get_Vector32()
	fileDict["max"] = file.get_Vector32()
	fileDict["bbmin"] = file.get_Vector32()
	fileDict["bbmax"] = file.get_Vector32()
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
	
	parseBones()
	boneHier2()
	var seq = parseSequence()
	return parseBodyPart()
	
	
	

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
		sequenceDict["linearMovement"] = file.get_Vector32()
		sequenceDict["autoMovePosIndex"] = file.get_32()
		sequenceDict["autoMovoeAngleIndex"] = file.get_32()
		sequenceDict["bbMin"] = file.get_Vector32()
		sequenceDict["bbMax"] = file.get_Vector32()
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
	return sequences

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
	boneDict["pos"] = file.get_Vector32()
	boneDict["rot"] = file.get_Vector32()
	boneDict["scaleP"] = file.get_Vector32()
	boneDict["scaleR"] = file.get_Vector32()
	boneDict["index"] = String(boneIndex)
	var sphere = CSGSphere.new()
	sphere.radius = 0.5
	#print(boneDict["name"],":",boneDict["pos"])
	sphere.translation = boneDict["pos"]
	sphere.rotation = boneDict["rot"]
	#add_child(sphere)
	#boneDict["node"] = sphere
	var boneTransform  = Transform.IDENTITY
	print(boneTransform)
	boneTransform.translated(boneDict["pos"])

	print(boneTransform)
	var rotVect = boneDict["rot"]
	boneDict["transform"] = boneTransform
	
	boneDict["thePos"] = boneDict["pos"]
	#bone["pos"] = boneDict["thePos"].rotated(Vector3(1,0,0),rotVect.x)
	#bone["pos"] = boneDict["thePos"].rotated(Vector3(0,1,0),rotVect.y)
	#bone["pos"] = boneDict["thePos"].rotated(Vector3(0,0,1),rotVect.z)
	
	
	
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
		var v = file.get_Vector32()
		
		verts.append(Vector3(v.x,v.y,v.z))
	
	file.seek(modelDict["normIndex"])
	for i in range(0,modelDict["numNorms"]):
		norms.append(file.get_Vector32())
	
	
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
		
		print(boneIndices[v])
		var vert = vertices[v]
		
		vert = vert.rotated(Vector3(1,0,0),boneRot.x)
		vert = vert.rotated(Vector3(0,1,0),boneRot.y)
		vert = vert.rotated(Vector3(0,0,1),boneRot.z)
		vert += bonePos

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
	boneItt2(0)
	



func boneItt2(index):
	if index == 0:
		var boneRot = bones[index]["rot"]
		var bonePos = bones[index]["pos"]
		var scaleR = bones[index]["scaleR"]
		bones[index]["sumPos"] = bonePos
	
	for cIndex in bones[index]["children"]:
		print(bones[cIndex]["name"])
		var pBoneRot = bones[index]["rot"]
		var bonePos = bones[cIndex]["pos"]
		
		bonePos = bonePos.rotated(Vector3(1,0,0),pBoneRot.x)
		bonePos = bonePos.rotated(Vector3(0,1,0),pBoneRot.y)
		bonePos = bonePos.rotated(Vector3(0,0,1),pBoneRot.z)
		
		
		bones[cIndex]["sumPos"] = bones[index]["sumPos"] + bonePos#bones[cIndex]["pos"]
		#drawLine(bones[index]["sumPos"],bones[cIndex]["sumPos"])
		boneItt2(cIndex)

func drawSphere(pos,nameStr = ""):
	var meshNode = MeshInstance.new()
	var mesh = SphereMesh.new()
	
	mesh.radius = 0.25
	mesh.height = 0.5
	meshNode.mesh = mesh
	meshNode.name = nameStr
	meshNode.translation = pos
	add_child(meshNode)
	return meshNode
	
	

func drawLine(start,end):
	if killSwitch == true:
		return
	var ig = ImmediateGeometry.new()
	ig.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	ig.add_vertex(start)
	ig.add_vertex(end)
	var random_color = Color(randf(), randf(), randf())
	var mat = SpatialMaterial.new()
	mat.albedo_color = random_color
	ig.material_override = mat
	ig.end()
	add_child(ig)
	
	var sphereNode : MeshInstance = drawSphere(end)
	sphereNode.material_override = mat
	
